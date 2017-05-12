package SWISH::Prog::Native::Indexer;
use strict;
use warnings;
use base qw( SWISH::Prog::Indexer );
use Carp;
use File::Temp ();
use SWISH::Prog::Native::InvIndex;
use SWISH::Prog::Config;
use Scalar::Util qw( blessed );
use File::Copy ();

our $VERSION = '0.75';

my $invindex_class = 'SWISH::Prog::Native::InvIndex';

__PACKAGE__->mk_accessors(qw( fh exe opts ));

=head1 NAME

SWISH::Prog::Native::Indexer - wrapper around Swish-e binary

=head1 SYNOPSIS

 use SWISH::Prog::Native::Indexer;
 my $indexer = SWISH::Prog::Native::Indexer->new(
        invindex    => SWISH::Prog::Native::InvIndex->new,
        config      => SWISH::Prog::Config->new,
        count       => 0,
        clobber     => 1,
        flush       => 10000,
        started     => time(),
 );
 $indexer->start;
 for my $doc (@list_of_docs) {
    $indexer->process($doc);
 }
 $indexer->finish;


=head1 DESCRIPTION

The Native Indexer is a wrapper around the swish-e version 2.x binary tool.

=head1 METHODS

=head2 new

Create indexer object. All the following parameters are also accessor methods.

=over

=item index

A SWISH::Prog::InvIndex::Native object.

=item config

A SWISH::Prog::Config object.

=item exe

The path to the C<swish-e> executable. If empty, will just look in $ENV{PATH}.

=item verbose

Takes same args as C<swish-e -v> option.

=item warnings

Takes same args as C<swish-e -W> option.

=item opts

String of options passed directly to the swish-e program.

=back

=cut

=head2 init

Initialize object. Called by new().

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    # default config
    $self->{config} ||= SWISH::Prog::Config->new;

    # default index
    $self->{invindex} ||= $self->{config}->IndexFile || $invindex_class->new;

    if ( $self->{invindex} && !blessed( $self->{invindex} ) ) {
        $self->{invindex} = $invindex_class->new( path => $self->{invindex} );
    }

    unless ( $self->invindex->isa($invindex_class) ) {
        croak ref($self) . " requires $invindex_class-derived object";
    }

    $self->{exe} ||= 'swish-e';    # let PATH find it

}

=head2 swish_check

Returns true if the exe() executable works, false otherwise.

=cut

sub swish_check {
    my $self = shift;
    if ( exists $self->{_exe_version} ) {
        return $self->{_exe_version};
    }
    my $cmd = $self->exe . " -V";
    chomp( my @vers = `$cmd` );
    if ( !@vers ) {
        return 0;
    }
    $self->{_exe_version} = $vers[0];
    $self->{_exe_version} =~ s/SWISH-E //;
    return $self->{_exe_version};
}

=head2 start( [cmd] )

Start the indexer on its merry way. Stores the filehandle
in fh().

Returns the $indexer object.

You likely don't want to pass I<cmd> in but let start() construct
it for you.

=cut

sub start {
    my $self = shift;
    $self->SUPER::start(@_);

    my $index = $self->invindex->file;
    my $v     = $self->verbose || 0;
    my $w     = $self->warnings || 0;    # suffer the peril!
    my $opts  = $self->opts || '';
    my $exe   = $self->exe;

    my $swish_version = $self->swish_check;
    my $cmd           = shift
        || "$exe $opts -f $index -v$v -W$w -S prog -i stdin";

    # swish3 compat only in 2.4.8 or higher
    if ( $swish_version ge '2.4.8' || $swish_version ge '2.5.8' ) {
        $cmd .= " -D '\\x03' ";
    }

    if ( !$self->config->file ) {
        $self->config->write2( 0, 1 );    # write in prog mode
    }
    my $config_file = $self->config->file;
    $cmd .= ' -c ' . $config_file;

    $self->debug and carp "opening: $cmd";

    local $| = 1;

    open( SWISH, "| $cmd" ) or croak "can't exec $cmd: $!\n";

    # must print bytes as is even if swish-e won't index them as UTF-8
    binmode( SWISH, ':raw' );

    $self->fh( *SWISH{IO} );

    return $self;
}

=head2 fh

Get or set the open() filehandle for the swish-e process. B<CAUTION:>
don't set unless you know what you're doing.

You can print() to the filehandle using the SWISH::Prog index() method.
Or do it directly like:

 print { $indexer->fh } "your headers and body here";
 
The filehandle is close()'d by the finish() method.

=cut

=head2 finish

Close the open fh() filehandle and check for any errors.

Called by the magic DESTROY method so $indexer will finish()
whenever it goes out of scope.

=cut

sub DESTROY {
    shift->finish();
}

sub finish {
    my $self = shift;
    return 1 unless $self->fh;

    # close indexer filehandle
    my $e = close( $self->fh );
    unless ($e) {
        if ( $? == 0 ) {

            # false positive ??
            return;
        }

        carp "error $e: can't close indexer (\$?: $?): $!\n";

        if ( $? == 256 ) {

            # no docs indexed
            # TODO remove temp indexes

        }

    }

    # destroy fh, in case close() didn't do it.
    $self->fh(undef);

    # write header
    $self->config->write3( $self->invindex->meta_file->stringify );

}

=head2 merge( @I<InvIndex objects> )

merge() will merge @I<SWISH::Prog::Native::InvIndex objects>
together with the index named in the calling Indexer object.

Returns the $indexer object on success, croaks on failure.
 
=cut

sub merge {
    my $self = shift;
    if ( !@_ ) {
        croak "merge() requires some InvIndex objects to work with";
    }

    my $invindex_class = blessed( $self->invindex );

    # we want a collection of path names to work with
    my @names;
    for (@_) {
        if ( blessed($_) and $_->isa($invindex_class) ) {
            push( @names, $_->file->stringify );
        }
        elsif ( -s $_ ) {
            push( @names, "$_" );    # force whatever it is to stringify
        }
        else {
            croak "$_ is not a InvIndex object or a file path";
        }
    }

    for (@names) {
        if ( !-s "$_.prop" )
        {    # test .prop file since that is both 2.4 and 2.6
            croak "$_ appears to be empty: $!";
        }
    }

    if ( scalar(@names) > 60 ) {
        carp "Likely too many indexes to merge at one time!"
            . "Your OS may have an open file limit.";
    }
    my $to_merge     = join( ' ', @names, $self->invindex->file );
    my $current_path = $self->invindex->path;
    my $verbose      = $self->verbose || 0;
    my $opts         = $self->opts || '';
    my $exe          = $self->exe || 'swish-e';

    # we can't replace the index in-place
    # so we create a new temp index, then mv() back
    my $tmpindex = $invindex_class->new(
        path => $current_path->parent->subdir('tmpmerge.index') );
    $tmpindex->path->mkpath( $self->debug );
    my $cmd = "$exe $opts -v$verbose -M $to_merge $tmpindex/index.swish-e";

    $self->debug and carp "opening: $cmd";

    local $| = 1;

    open( SWISH, "$cmd  |" )
        or croak "can't start merge: $!\n";

    while (<SWISH>) {
        if ( $verbose or $self->debug ) {
            print STDERR $_;
        }
    }

    close(SWISH) or croak "can't close merge(): $cmd: $! ($?)\n";

    # assume that the header file is the same for
    # all the merged files, and preserve this one.
    my $header = $self->invindex->meta_file->stringify;
    File::Copy::copy( $header, $tmpindex->meta_file->stringify )
        or croak "copy $header -> $tmpindex failed: $!";

    # archive the existing just in case
    my $archive = "$current_path.$$";
    File::Copy::move( $current_path, $archive )
        or croak "move $current_path -> $archive failed: $!";

    if ( !File::Copy::move( $tmpindex, $current_path ) ) {
        carp "move $tmpindex -> $current_path failed: $!";
        carp "restoring original index $current_path";
        File::Copy::move( $archive, $current_path )
            or croak "move $archive -> $current_path failed: $!";
    }
    Path::Class::dir($archive)->rmtree
        or croak "failed to rmtree $archive: $!";

    return $self;
}

=head2 process( I<doc> )

process() will parse and index I<doc>. I<doc> should be a 
SWISH::Prog::Doc instance.

Will croak() on failure.

=cut

sub process {
    my $self = shift;
    my $doc  = $self->SUPER::process(@_);
    $doc->version(2);

    if ( $self->debug ) {
        warn $doc;
    }

    print { $self->fh } $doc
        or croak "failed to print to filehandle " . $self->fh . ": $!\n";

    return $doc;
}

=head2 add( I<doc> )

Add I<doc> to the index.

Note this is slower than merge(). If you have multiple I<doc> objects,
create a new Indexer object and process() them all, then merge() the two
InvIndex objects.

 my $indexer = SWISH::Prog::Native::Indexer->new(invindex => 'tmpmerge');
 $indexer->start;
 for my $doc (@list_of_docs) {
     $indexer->process($doc);
 }
 $indexer->finish;
 $indexer->merge( 'path/to/other/index' );
 
=cut

sub add {
    my $self = shift;
    my $doc = shift or croak "need SWISH::Prog::Doc object to add()";
    unless ( $doc->isa('SWISH::Prog::Doc') ) {
        croak "$doc is not a SWISH::Prog::Doc object";
    }

    # create a temporary invindex of $doc
    my $invindex_class = blessed( $self->invindex );
    my $tmpdir = Path::Class::dir( File::Temp::tempdir( CLEANUP => 1 ) );
    my $tmpinvindex = $invindex_class->new( path => $tmpdir );

    # spawn a new indexer with similar attributes
    my $indexer = blessed($self)->new(
        verbose  => $self->verbose,
        debug    => $self->debug,
        invindex => $tmpinvindex,
        config   => $self->config,
    );
    $indexer->start;
    $indexer->process($doc);
    $indexer->finish;

    # merge it
    $self->merge($tmpinvindex);

    # remove temp invindex
    $tmpdir->rmtree or croak "failed to clean up temp invindex $tmpdir: $!";

    return $self;
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
