
# Color - provides color names => SDL::Color mapping

package SDL::App::FPS::Color;

# (C) by Tels <http://bloodgate.com/>

use strict;

use Exporter;
use vars qw/@ISA $VERSION @EXPORT_OK $AUTOLOAD/;
@ISA = qw/Exporter/;

$VERSION = '0.02';

@EXPORT_OK = qw/
  RED GREEN BLUE
  ORANGE YELLOW PURPLE MAGENTA CYAN BROWN
  WHITE BLACK
  GRAY LIGHTGRAY DARKGRAY
  GREY LIGHTGREY DARKGREY
  LIGHTRED DARKRED LIGHTBLUE DARKBLUE LIGHTGREE DARKGREEN
  darken lighten blend desaturate invert
  /;

use SDL::Color;

my $color = 
  {
  BLACK		=> [0x00,0x00,0x00],
  WHITE		=> [0xff,0xff,0xff],
  LIGHTGRAY	=> [0xa0,0xa0,0xa0],
  DARKGRAY	=> [0x40,0x40,0x40],
  GRAY		=> [0x80,0x80,0x80],
  LIGHTGREY	=> [0xa0,0xa0,0xa0],
  DARKGREY	=> [0x40,0x40,0x40],
  GREY		=> [0x80,0x80,0x80],
  RED		=> [0xff,0x00,0x00],
  GREEN		=> [0x00,0xff,0x00],
  BLUE 		=> [0x00,0x00,0xff],
  LIGHTRED	=> [0xff,0x80,0x80],
  LIGHTGREEN	=> [0x80,0xff,0x80],
  LIGHTBLUE 	=> [0x80,0x80,0xff],
  DARKRED	=> [0x80,0x00,0x00],
  DARKGREEN	=> [0x00,0x80,0x00],
  DARKBLUE	=> [0x00,0x00,0x80],
  YELLOW	=> [0xff,0xff,0x00],
  PURPLE	=> [0x80,0x00,0x80],
  MAGENTA	=> [0xff,0x80,0xff],
  CYAN		=> [0x80,0xff,0xff],
  ORANGE	=> [0xff,0x80,0x00],
  TURQUISE	=> [0xff,0xff,0x80],
  BROWN		=> [0x80,0x40,0x40],
  SALMON	=> [0xff,0x80,0x80],
  };

sub AUTOLOAD
  {
  # create at runtime the different color routines (and the SDL::Color
  # objects) Only the first call has an overhead, and this avoids to
  # create dozend objects at load time, that probably are never used.
  my $name = $AUTOLOAD;

  $name =~ s/.*:://;    # split package

  if (exists $color->{$name})
    {
    if (ref($color->{$name}) ne 'SDL::Color')		# will always be true?
      {
      # create object on the fly
      my ($r,$g,$b) = @{ $color->{$name} };
      $color->{$name} = SDL::Color->new( -r => $r, -g => $g, -b => $b);
      }
    no strict 'refs';
    *{"SDL::App::FPS::Color"."::$name"} = sub { $color->{$name}; };
    &$name;      # uses @_
    }
  else
    {
    # delayed load of Carp and avoid recursion
    require Carp;
    Carp::croak ("SDL::App::FPS::Color $name is unknown");
    }
  }

sub darken
  {
  shift unless ref($_[0]);		# allow SDL::App::FPS::Color->darken()
  my ($color,$factor) = @_;

  if ($factor < 0 || $factor > 1)
    {
    require Carp; Carp::croak ("Darkening factor must be between 0..1");
    }
  $factor = 1-$factor;
  SDL::Color->new ( 
    -r => $color->r() * $factor, 
    -g => $color->g() * $factor, -b => $color->b() * $factor);
  }

sub lighten
  {
  shift unless ref($_[0]);		# allow SDL::App::FPS::Color->lighten()
  my ($color,$factor) = @_;

  if ($factor < 0 || $factor > 1)
    {
    require Carp; Carp::croak ("Darkening factor must be between 0..1");
    }
  my $r = $color->r();
  my $g = $color->g();
  my $b = $color->b();
  SDL::Color->new ( 
    -r => $r + (0xff - $r) * $factor, 
    -g => $g + (0xff - $g) * $factor, 
    -b => $b + (0xff - $b) * $factor ); 
  }

sub invert
  {
  shift unless ref($_[0]);	# allow SDL::App::FPS::Color->desaturate()
  my ($color) = @_;

  SDL::Color->new ( 
    -r => 255 - $color->r(),
    -g => 255 - $color->g(),
    -b => 255 - $color->b());
  }

sub desaturate
  {
  shift unless ref($_[0]);	# allow SDL::App::FPS::Color->desaturate()
  my ($color,$r,$g,$b) = @_;

  $r = 1 if !defined $r;
  $g = 1 if !defined $g;
  $b = 1 if !defined $b;

  if ($r < 0 || $r > 1)
    {
    require Carp; Carp::croak ("Desaturate red factor must be between 0..1");
    }
  if ($g < 0 || $g > 1)
    {
    require Carp; Carp::croak ("Desaturate green factor must be between 0..1");
    }
  if ($b < 0 || $b > 1)
    {
    require Carp; Carp::croak ("Desaturate blue factor must be between 0..1");
    }
  my $rgb = ($color->r() * $r + $color->g() * $g + $color->b() * $b)/ 3;
  SDL::Color->new ( -r => $rgb, -g => $rgb, -b => $rgb );
  }

sub blend
  {
  shift unless ref($_[0]);		# allow SDL::App::FPS::Color->blend()
  my ($color_a,$color_b,$factor) = @_;

  if ($factor < 0 || $factor > 1)
    {
    require Carp; Carp::croak ("Darkening factor must be between 0..1");
    }
  my $r = $color_a->r();
  my $g = $color_a->g();
  my $b = $color_a->b();
  SDL::Color->new ( 
    -r => $r + ($color_b->r() - $r) * $factor, 
    -g => $g + ($color_b->g() - $g) * $factor, 
    -b => $b + ($color_b->b() - $b) * $factor ); 
  }

1;

__END__

=pod

=head1 NAME

SDL::App::FPS::Color - provides color names => SDL::Color mapping

=head1 SYNOPSIS

	package SDL::App::FPS::Color qw/RED BLUE GREEN/;

	my $yellow = SDL::App::FPS::Color::YELLOW();
	my $red = RED();
	my $blue = BLUE;
	
=head1 EXPORTS

Can export the color names on request.

=head1 DESCRIPTION

This package provides SDL::Color objects that corrospond to the basic
color names.

=head1 METHODS

The following color names exist:

  	RED		GREEN		BLUE
	ORANGE		YELLOW		PURPLE
	MAGENTA 	CYAN 		BROWN
	WHITE		BLACK
	GRAY		LIGHTGRAY	DARKGRAY
	GREY		LIGHTGREY	DARKGREY
	LIGHTRED 	DARKRED
	LIGHTBLUE	DARKBLUE
	LIGHTGREE	DARKGREEN

=head2 darken

	$new_color = SDL::App::FPS::Color::darken($color,$factor);

C<$factor> must be between 1 (result is black) and 0 (result is original
color). C<darken()> darkens the color by this factor, for instance 0.5 makes
a color of 50% color values from the original color.

=head2 lighten

	$new_color = SDL::App::FPS::Color::lighten($color,$factor);

C<$factor> must be between 0 (result is original color) and 1 (result is
white). C<lighten()> darkens the color by this factor, for instance 0.5 makes
a color of 50% higher color values from the original color.

=head2 blend

	$new_color = SDL::App::FPS::Color::blend($color_a,$color_b,$factor);

C<$factor> must be between 0 (result is C<$color_a>) and 1 (result is
C<$color_b>). C<blend()> creates a blended color from the two colors. A
factor of 0.5 means it will result in exact the middle of color A and color B.

=head2 invert

	$new_color = SDL::App::FPS::Color::invert($color);

Inverts a color - black will be white, white will be black, and blue will be
yellow, etc.

=head2 desaturate

	$new_color = SDL::App::FPS::Color::desaturate($color,$rb,$gf,$bf);

Converts a color to grayscale. The default is just averaging the three
components red, green and blue (meaning C<$rf>, C<$gf> and C>$bf> are 1.0).

You can pass values between 0..1 for C<$rf>, C<$gf> and C<$bf>, for instance:

	$gray = SDL::App::FPS::Color::desaturate($color, 0, 1, 1);

This would ignore the red component completely, making the grayscale based only
on the green and blue parts. Or maybe you want to simulate that the human eye
is more sensitive to green:

	$gray = SDL::App::FPS::Color::desaturate($color, 0.6, 1, 0.6);

=head1 AUTHORS

(c) 2003 Tels L<http://bloodgate.com/perl/sdl/|http://bloodgate.com/perl/sdl/>

=head1 SEE ALSO

L<SDL:App::FPS>, L<SDL::App> and L<SDL>.

=cut

