package SWISH::Prog::Aggregator::FS;
use strict;
use warnings;
use base qw( SWISH::Prog::Aggregator );

use Carp;
use File::Find;
use File::Rules;
use Data::Dump qw( dump );
use SWISH::3;

our $VERSION = '0.75';

# we rely on file extensions to determine content type
# and thus parser type. If a file has no extension,
# assume this one.
our $DEFAULT_EXTENSION = 'txt';

=pod

=head1 NAME

SWISH::Prog::Aggregator::FS - crawl a filesystem

=head1 SYNOPSIS

 use SWISH::Prog::Aggregator::FS;
 my $fs = SWISH::Prog::Aggregator::FS->new(
        indexer => SWISH::Prog::Indexer->new
    );
    
 $fs->indexer->start;
 $fs->crawl( $path );
 $fs->indexer->finish;
 
=head1 DESCRIPTION

SWISH::Prog::Aggregator::FS is a filesystem aggregator implementation
of the SWISH::Prog::Aggregator API. It is similar to the DirTree.pl
script in the Swish-e 2.4 distribution.

=cut

=head1 METHODS

See SWISH::Prog::Aggregator.

=head2 init

Implements the base init() method called by new().

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    # create .ext regex to match in file_ok()
    if ( $self->config->IndexOnly ) {
        my $re = join( '|',
            grep {s/^\.//} split( m/\s+/, $self->config->IndexOnly ) );
        $self->{_ext_re} = qr{\.($re)}io;
    }
    else {
        $self->{_ext_re} = $SWISH::Prog::Utils::ExtRE;
    }

}

=head2 file_ok( I<full_path> )

Check I<full_path> before fetch()ing it.

Returns 0 if I<full_path> should be skipped.

Returns file extension of I<full_path> if I<full_path> should be processed.

=cut

sub file_ok {
    my $self      = shift;
    my $full_path = shift;
    my $stat      = shift;

    $self->debug and warn "checking file $full_path\n";

    my ( $path, $file, $ext )
        = SWISH::Prog::Utils->path_parts( $full_path, $self->{_ext_re} );

    $self->debug and warn "path=$path file=$file ext=$ext\n";

    # treat no extension like plain text
    $ext = $DEFAULT_EXTENSION unless length $ext;

    return 0 if $file =~ m/^\./;

    #carp "parsed file: $file\npath: $path\next: $ext";

    $stat ||= [ stat($full_path) ];
    return 0 unless -r _;
    return 0 if -d _;
    if (    $self->ok_if_newer_than
        and $self->ok_if_newer_than >= $stat->[9] )
    {
        return 0;
    }
    return 0
        if ( $self->_apply_file_rules($full_path)
        && !$self->_apply_file_match($full_path) );

    $self->debug and warn "  $full_path -> ok\n";
    if ( $self->verbose & 4 ) {
        local $| = 1;    # don't buffer
        print "crawling file $full_path\n";
    }

    return $ext;
}

=head2 dir_ok( I<directory> )

Called by find() for all directories. You can control
the recursion into I<directory> via the config() params
 
=cut

sub dir_ok {
    my $self = shift;
    my $dir  = shift;
    my $stat = shift || [ stat($dir) ];

    $self->debug and warn "checking dir $dir\n";

    return 0 unless -d _;
    return 0 if $dir =~ m!/\.!;
    return 0 if $dir =~ m/^\.[^\.]/;        # could be ../foo
    return 0 if $dir =~ m!/(\.svn|RCS)/!;
    return 0
        if ( $self->_apply_file_rules($dir)
        && !$self->_apply_file_match($dir) );

    $self->debug and warn "  $dir -> ok\n";
    if ( $self->verbose & 2 ) {
        local $| = 1;                       # don't buffer
        print "crawling dir $dir\n";
    }

    1;
}

=head2 get_doc( I<file_path> [, I<stat>, I<ext> ] )

Returns a doc_class() instance representing I<file_path>.

=cut

sub get_doc {
    my $self = shift;
    my $url = shift or croak "file path required";
    my ( $stat, $ext ) = @_;
    my $buf;

    # NOTE we always read in binary (raw) mode in case
    # the file is compressed, binary, etc.
    eval {

        # the 2nd param runs in raw mode (no NULL substitution)
        $buf = SWISH::3->slurp( $url, 1 );
        $url =~ s/\.gz$//;    # post-slurp, in case it failed.
    };

    if ($@) {
        carp "unable to read $url - skipping";
        return;
    }

    $stat ||= [ stat($url) ];

    # TODO SWISH::3 has this function too.
    # might be faster since no OO overhead.
    my $type = SWISH::Prog::Utils->mime_type( $url, $ext );

    if (    $self->ok_if_newer_than
        and $self->ok_if_newer_than >= $stat->[9] )
    {
        warn "skipping $url ... too old\n";
        return;
    }

    return $self->doc_class->new(
        url     => $url,
        modtime => $stat->[9],
        content => $buf,
        type    => $type,
        size    => $stat->[7],
        debug   => $self->debug
    );

}

sub _do_file {
    my $self = shift;
    my $file = shift;
    if ( my $ext = $self->file_ok($file) ) {
        my $doc = $self->get_doc( $file, [ stat(_) ], $ext );
        $self->swish_filter($doc);
        if ( $self->test_mode ) {
            warn join( ' ', $doc->url, $doc->type ) . "\n";
        }
        else {
            $self->{indexer}->process($doc);
        }
        $self->_increment_count;
    }
    else {
        $self->debug and warn "skipping file $file\n";
        if ( $self->verbose & 4 ) {
            local $| = 1;
            print "skipping $file\n";
        }
    }
}

#
# the basic wanted() code here based on Bill Moseley's DirTree.pl,
# part of the Swish-e 2.4 distrib.

=head2 crawl( I<paths_or_files> )

Crawl the filesystem recursively within I<paths_or_files>, processing
each document specified by the config().

=cut

sub crawl {
    my $self = shift;

    my @paths = @_;

    my @files = grep { !-d } @paths;
    my @dirs  = grep {-d} @paths;

    for my $f (@files) {
        $self->_do_file($f);
    }

    # TODO set some flags here for filtering out files/dirs
    # based on $self->indexer->config.

    if (@dirs) {

        find(
            {   wanted => sub {

                    # canonpath cleans up any leading .
                    my $path = File::Spec->canonpath($File::Find::name);

                    if (-d) {
                        unless ( $self->dir_ok( $path, [ stat(_) ] ) ) {
                            if ( $self->verbose & 2 ) {
                                local $| = 1;
                                print "skipping $path\n";
                            }
                            $File::Find::prune = 1;
                            return;
                        }

                        #warn "-d $path\n";
                        return;
                    }
                    else {

                        #warn "!-d $path\n";
                    }

                    $self->_do_file($path);

                },
                no_chdir => 1,
                follow   => $self->config->FollowSymLinks,

            },
            @dirs
        );
    }

    return $self->{count};
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
