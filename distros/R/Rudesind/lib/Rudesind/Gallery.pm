package Rudesind::Gallery;

use strict;

use Rudesind::Captioned;

use Class::Roles does => 'Rudesind::Captioned';

use Params::Validate qw( validate validate_pos SCALAR );
use Path::Class ();

use Rudesind::Config;


sub new
{
    my $class = shift;
    my %p = validate( @_,
                      { path   => { type => SCALAR },
                        config => { isa => 'Rudesind::Config' },
                      }
                    );

    $p{path} =~ s{/$}{};

    my @dirs = split /\//, $p{path};

    my $dir =
        Path::Class::dir( $p{config}->image_dir, @dirs )->cleanup;

    return unless -d $dir;

    my $title = @dirs ? $dirs[-1] : 'top';
    my $self =
        bless { dir    => $dir,
                path   => $p{path},
                title  => $title,
                config => $p{config},
              }, $class;

    return $self;
}

sub path   { $_[0]->{path} }
sub title  { $_[0]->{title} }
sub config { $_[0]->{config} }

sub uri    { $_[0]->path }

sub _contents
{
    my $self = shift;

    return @{ $self->{contents} } if $self->{contents};

    local *DIR;
    opendir DIR, "$self->{dir}" or die "Cannot read $self->{dir}: $!";

    $self->{contents} =
        [ map { "$self->{dir}/$_" }
          grep { ! /^\./ }
          readdir DIR
        ];

    return @{ $self->{contents} };
}

sub subgalleries
{
    my $self = shift;

    return
        map { Rudesind::Gallery->new( path   => $self->path . "/$_",
                                      config => $self->config ) }
        sort map { $self->_strip_dir($_) } grep { ! /^\./ && -d } $self->_contents;
}

sub _strip_dir { $_[1] =~ s,$_[0]->{dir}/,,; $_ }

sub _add_path { $_[0]->{path} ? join '/', $_[0]->{path}, $_[1] : $_[1] }

sub images
{
    my $self = shift;

    return @{ $self->{images} } if $self->{images};

    my $re = Rudesind::Image->image_extension_re;

    $self->{images} =
        [ map { Rudesind::Image->new( file   => "$self->{dir}/$_",
                                      path   => $self->_add_path($_),
                                      config => $self->config,
                                    ) }
          map { $self->_strip_dir($_) }
          sort
          grep { /$re/ }
          $self->_contents
        ];

    return @{ $self->{images} };
}

sub image
{
    my $self = shift;
    my ($file) = validate_pos( @_, { type => SCALAR } );

    return unless -f "$self->{dir}/$file";

    return
        Rudesind::Image->new( file => "$self->{dir}/$file",
                              path => $self->_add_path($file),
                              config => $self->config,
                            );
}

sub previous_image
{
    my $self = shift;
    my $image = shift;

    my $prev;
    foreach my $i ( $self->images )
    {
        return $prev if $i->path eq $image->path;

        $prev = $i;
    }
}

sub next_image
{
    my $self = shift;
    my $image = shift;

    my $next;
    foreach my $i ( reverse $self->images )
    {
        return $next if $i->path eq $image->path;

        $next = $i;
    }
}

sub _caption_file
{
    my $self = shift;

    return $self->{dir}->file('.caption');
}


1;

__END__

=pod

=head1 NAME

Rudesind::Gallery - A gallery which may contain both images and other galleries

=head1 SYNOPSIS

  use Rudesind::Gallery;

  my $gallery = Rudesind::Gallery->new( path => '/', config => $config );

  foreach my $img ( $gallery->images ) { ... }

=head1 DESCRIPTION

This class represents a gallery.  A gallery can contain both images as
well as other galleries.

=head1 CONSTRUCTOR

The C<new()> method requires two parameters:

=over 4

=item * path

The I<URI> path for the gallery.  The top-level gallery will always
have be F</>.

=item * config

A C<Rudesind::Config> object.

=back

If no filesystem directory matches the given path, then the
constructor returns false.

=head1 METHODS

This class provides the following methods:

=over 4

=item * path()

The C<URI> path for this gallery.

=item * uri()

The same value as C<path()>.  Provided for the use of the Mason UI.
Use C<path()> instead.

=item * title()

A title for the gallery.  Currently, this is just the last portion of
the path, or "top" if the path is F</>.

=item * config()

The C<Rudesind::Config> object given to the constructor.

=item * subgalleries()

Returns a list of C<Rudesind::Gallery> objects, each of which is a
gallery contained by the object this method is called on.

The list is sorted by title (the last portion of the gallery's path).

=item * images()

Returns a list of C<Rudesind::Image> objects, each of which is an
image contained by the object this method is called on.

The list is sorted by title (the image file's name).

=item * image($filename)

Given a filename (without a path), this method returns a new
C<Rudesind::Image> object for that image.  Tihs is the constructor for
image objects.

If no such file exists in the gallery, then this method returns a
false value.

=item * previous_image($image)

=item * next_image($image)

Given an image object, these methods return the previous or next image
object in the gallery, if one exists.

=back

=head2 Captions

This class uses the C<Rudesind::Captioned> role.

=cut
