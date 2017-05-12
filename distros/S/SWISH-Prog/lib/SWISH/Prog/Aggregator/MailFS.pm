package SWISH::Prog::Aggregator::MailFS;
use strict;
use warnings;
use base qw( SWISH::Prog::Aggregator::FS );
use Path::Class ();
use SWISH::Prog::Aggregator::Mail;    # delegate doc creation
use Carp;
use Data::Dump qw( dump );

our $VERSION = '0.75';

=pod

=head1 NAME

SWISH::Prog::Aggregator::MailFS - crawl a filesystem of email messages

=head1 SYNOPSIS

 use SWISH::Prog::Aggregator::MailFS;
 my $fs = SWISH::Prog::Aggregator::MailFS->new(
        indexer => SWISH::Prog::Indexer->new
    );
    
 $fs->indexer->start;
 $fs->crawl( $path_to_mail );
 $fs->indexer->finish;
 
=head1 DESCRIPTION

SWISH::Prog::Aggregator::MailFS is a subclass of SWISH::Prog::Aggregator::FS
that expects every file in a filesystem to be an email message.
This class is useful for crawling a file tree like those managed by ezmlm.

B<NOTE:> This class will B<not> work with personal email boxes
in the Mbox format. It might work with maildir format, but that is
coincidental. Use SWISH::Prog::Aggregator::Mail to handle your personal
email box. Use this class to handle mail archives as with a mailing list.

=cut

=head1 METHODS

See SWISH::Prog::Aggregator::FS. Only new or overridden methods are documented
here.

=cut

=head2 init

Constructor.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    # cache a Mail aggregator to use its get_doc method
    $self->{_mailer} = SWISH::Prog::Aggregator::Mail->new(
        indexer => $self->indexer,
        verbose => $self->verbose,
        debug   => $self->debug,
    );

    return $self;
}

=head2 file_ok( I<full_path> )

Like the parent class method, but ignores file extension, assuming
that all files are email messages.

Returns the I<full_path> value if the file is ok for indexing;
returns 0 if not ok.

=cut

sub file_ok {
    my $self      = shift;
    my $full_path = shift;
    my $stat      = shift;

    $self->debug and warn "checking file $full_path\n";

    return 0 if $full_path =~ m![\\/](\.svn|RCS)[\\/]!; # TODO configure this.

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
        print "crawling $full_path\n";
    }

    return $full_path;
}

=head2 get_doc( I<url> )

Overrides parent class to delegate the creation of the 
SWISH::Prog::Doc object to SWISH::Prog::Aggregator::Mail->get_doc().

Returns a SWISH::Prog::Doc object.

=cut

sub get_doc {
    my $self = shift;

    # there's some wasted overhead here in creating a
    # SWISH::Prog::Doc 2x. But we're optimizing here for
    # developer time...

    # mostly a slurp convenience
    my $doc = $self->SUPER::get_doc(@_);

    #carp "first pass for raw doc: " . dump($doc);

    # get the "folder"
    my $folder = Path::Class::file( $doc->url )->dir;

    # now convert the buffer to an email message
    my $msg = Mail::Message->read( \$doc->content );

    # and finally convert to the SWISH::Prog::Doc we intend to return
    my $mail = $self->{_mailer}->get_doc( $folder, $msg );
    
    # reinstate original url from filesystem
    $mail->url($doc->url);

    #carp "second pass for mail doc: " . dump($mail);

    return $mail;
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
