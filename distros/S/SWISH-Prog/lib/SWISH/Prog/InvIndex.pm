package SWISH::Prog::InvIndex;

use strict;
use warnings;
use base qw( SWISH::Prog::Class );
use Carp;
use Path::Class ();    # do not import file() and dir()
use Scalar::Util qw( blessed );
use SWISH::Prog::InvIndex::Meta;
use overload(
    '""'     => sub { shift->path },
    'bool'   => sub {1},
    fallback => 1,
);

our $VERSION = '0.75';

__PACKAGE__->mk_accessors(qw( path clobber ));

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    my $path = $self->{path} || $self->{invindex} || 'index.swish';

    unless ( blessed($path) && $path->isa('Path::Class::Dir') ) {
        $self->path( Path::Class::dir($path) );
    }

    $self->{clobber} = 0 unless exists $self->{clobber};
}

sub new_from_meta {
    my $self = shift;

    # open swish.xml meta file
    my $meta = $self->meta;

    # parse for index format
    my $format = $meta->Index->{Format};

    # create new object and re-set $self
    my $newclass = "SWISH::Prog::${format}::InvIndex";

    warn "reblessing $self into $newclass";

    eval "require $newclass";
    croak $@ if $@;

    return $newclass->new(
        path    => $self->{path},
        clobber => $self->{clobber},
    );
}

sub open {
    my $self = shift;

    if ( -d $self->path && $self->clobber ) {
        $self->path->rmtree( $self->verbose, 1 );
    }
    elsif ( -f $self->path ) {
        croak $self->path
            . " is not a directory -- won't even attempt to clobber";
    }

    if ( !-d $self->path ) {
        carp "no path $self->{path} -- mkpath";
        $self->path->mkpath( $self->verbose );
    }

    1;
}

sub open_ro {
    shift->open(@_);
}

sub close { 1; }

sub meta {
    my $self = shift;
    return SWISH::Prog::InvIndex::Meta->new( invindex => $self );
}

sub meta_file {
    my $self = shift;
    return $self->path->file(
        SWISH::Prog::InvIndex::Meta->swish_header_file );
}

1;

__END__

=head1 NAME

SWISH::Prog::InvIndex - base class for Swish-e inverted indexes

=head1 SYNOPSIS

 use SWISH::Prog::InvIndex;
 my $index = SWISH::Prog::InvIndex->new(path => 'path/to/index');
 print $index;  # prints $index->path
 my $meta = $index->meta;  # $meta isa SWISH::Prog::InvIndex::Meta object
 
=head1 DESCRIPTION

A SWISH::Prog::InvIndex is a base class for defining different Swish-e
inverted index formats.

=head1 METHODS

=head2 init

Implements the base SWISH::Prog::Class method.

=head2 path

Returns a Path::Class::Dir object representing the directory path to the index. 
The path is a directory which contains the various files that comprise the 
index.

=head2 meta

Returns a SWISH::Prog::InvIndex::Meta object with which you can query 
information about the index.

=head2 meta_file

Returns Path::Class::File object pointing at the swish_header_file.

=head2 open

Open the invindex for reading/writing. Subclasses should implement this per
their IR library specifics.

This base open() method will rmtree( path() ) if clobber() is true,
and will mkpath() if path() does not exist. So SUPER::open() should
do something sane at minimum.

=head2 open_ro

Open the invindex in read-only mode. This is typical when searching
the invindex.

The default open_ro() method will simply call through to open().

=head2 close

Close the index. Subclasses should implement this per
their IR library specifics.

=head2 clobber

Get/set the boolean indicating whether the index should overwrite
any existing index with the same name. The default is true.

=head2 new_from_meta

Returns a new instance like new() does, blessed into the appropriate
class indicated by the C<swish.xml> meta header file.

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
