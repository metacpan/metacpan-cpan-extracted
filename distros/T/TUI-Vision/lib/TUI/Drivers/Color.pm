package TUI::Drivers::Color;
# ABSTRACT: Represents a color in any of the supported color types

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TColor
);

use PerlX::Assert::PP;
use Scalar::Util qw(
  blessed
  looks_like_number
);

use TUI::Drivers::Const qw( :ctXXXX );
use TUI::Drivers::Colors qw(
  RGBtoBIOS
  XTerm256toXTerm16
  XTerm16toBIOS
);

sub TColor() { __PACKAGE__ }

# predeclare private methods
my (
  $type,
);

# Default color constructor an constructor for specific color types.
#   Bit  0..23: Color (24 bits)
#   Bit 24..31: Type (8 bits, of which only 2 are actually used)

sub new {    # $cell (|%args)
  my ( $class, @args ) = @_;
  assert ( $class and !ref $class );

  # TColor->new()
  my $bits;
  if (!@args) {
    $bits = 0;
  }

  # TColor->new( bios => Int )
  elsif ( @args == 2 && $args[0] eq 'bios' ) {
    my $bios = $args[1];
    assert ( looks_like_number $bios );
    $bits = ( $bios & 0xf ) 
          | ( ctBIOS << 24 );
  }

  # TColor->new( rgb => Int | ArrayRef )
  elsif ( @args == 2 && $args[0] eq 'rgb' ) {
    my $rgb = $args[1];
    if ( ref $rgb eq 'ARRAY' ) {
      assert ( @$rgb == 3 );
      $rgb = ( ( ( $rgb->[0] << 8 ) | $rgb->[1] ) << 8 ) | $rgb->[2];
    }
    assert ( looks_like_number $rgb );
    $bits = ( $rgb & 0xffffff )
          | ( ctRGB << 24 );
  }

  # TColor->new( xterm => Int )
  elsif ( @args == 2 && $args[0] eq 'xterm' ) {
    my $xterm = $args[1];
    assert ( looks_like_number $xterm );
    $bits = ( $xterm & 0xff )
          | ( ctXTerm << 24 );
  }

  else {
    return;
  }

  return bless \$bits, $class;
}

# Copy and clone methods

sub assign {    # void ($other)
  my ( $self, $other ) = @_;
  assert ( blessed $self );
  assert ( blessed $other );
  $$self = $$other;
  return;
}

sub clone {    # $attr ()
  my ( $self ) = @_;
  assert ( blessed $self );
  my $v = $$self;
  return bless \$v, ref $self;
}

# Color type getters.

sub isDefault {    # $bool ()
  assert ( blessed $_[0] );
  return $_[0]->$type == ctDefault;
}

sub isBIOS {    # $bool ()
  assert ( blessed $_[0] );
  return $_[0]->$type == ctBIOS;
}

sub isRGB {    # $bool ()
  assert ( blessed $_[0] );
  return $_[0]->$type == ctRGB;
}

sub isXTerm {    # $bool ()
  assert ( blessed $_[0] );
  return $_[0]->$type == ctXTerm;
}

# Color value getters. They perform no conversion: make sure to check
# the color type first.

sub asBIOS {    # $bios ()
  assert ( blessed $_[0] );
  return ${ $_[0] } & 0x0f;
}

sub asRGB {    # $rgb ()
  assert ( blessed $_[0] );
  return ${ $_[0] } & 0x00ffffff;
}

sub asXTerm {    # $xterm ()
  assert ( blessed $_[0] );
  return ${ $_[0] } & 0xff;
}

# Quantization to TColor BIOS.

sub toBIOS {    # $bios ($isForeground)
  my ( $self, $isForeground ) = @_;
  assert ( blessed $self );

  SWITCH: for ( $self->$type ) {
    ctBIOS == $_ and 
      return $self->asBIOS();
    ctRGB == $_ and
      return RGBtoBIOS( $self->asRGB() );
    ctXTerm == $_ and do {
      my $idx = $self->asXTerm();
      $idx = XTerm256toXTerm16( $idx )
        if $idx >= 16;
      return XTerm16toBIOS( $idx );
    };
    DEFAULT: {
      return $isForeground ? 0x7 : 0x0;
    }
  }
}

sub equals {    # $bool ($other|$bios)
  my ( $self, $other ) = @_;
  assert ( blessed $self );
  assert ( blessed $other or looks_like_number $other );
  return $self->asBIOS() == $other
    unless ref $other;
  return ref $self eq ref $other
      && $$self == $$other;
}

use overload
  '0+' => \&asBIOS,
  '==' => \&equals,
  fallback => 1;

# Private methods.

$type = sub {   # $type ()
  assert ( blessed $_[0] );
  return ${ $_[0] } >> 24;
};

1;

__END__

=head1 NAME

TUI::Drivers::Color - represents a color in any of the supported color types

=head1 SYNOPSIS

  use TUI::Drivers;

  my $default = TColor->new();

  my $bios = TColor->new(
    bios => 0xF,
  );

  my $rgb = TColor->new(
    rgb => 0x7F00BB,
  );

  my $xterm = TColor->new(
    xterm => 196,
  );

  if ( $rgb->isRGB ) {
    my $value = $rgb->asRGB;
  }

  my $biosColor = $rgb->toBIOS(1);

=head1 DESCRIPTION

This module provides C<TColor>, a value type that represents one of 
several color kinds:

=over

=item *

Terminal default color

=item *

BIOS color values

=item *

XTerm color values

=item *

24-bit RGB colors

=back

The purpose of this type is to describe either the foreground or background
color of a screen cell.

In a terminal emulator, the default color represents text displayed without
any explicit color attributes.

=head1 CONSTRUCTOR

=head2 new

Creates a desired color value.

With no arguments, a default terminal color is created:

  my $color = TColor->new();

Create a BIOS color:

  my $color = TColor->new(
    bios => 0xF,
  );

Create an RGB color:

  my $color = TColor->new(
    rgb => 0x7F00BB,
  );

An RGB color may also be specified as an RGB triplet:

  my $color = TColor->new(
    rgb => [ 127, 0, 187 ],
  );

Create an XTerm color:

  my $color = TColor->new(
    xterm => 196,
  );

=head1 METHODS

=head2 asBIOS

  my $bios = $self->asBIOS();

Returns the stored value as a BIOS color.

No conversion is performed. Make sure to verify the color type first.

=head2 asRGB

  my $rgb = $self->asRGB();

Returns the stored value as an RGB color.

No conversion is performed. Make sure to verify the color type first.

=head2 assign

  $self->assign($other);

Copies the contents of another C<TColor> into the current one.

=head2 asXTerm

  my $xterm = $self->asXTerm();

Returns the stored value as an XTerm color.

No conversion is performed. Make sure to verify the color type first.

=head2 clone

  my $color = $self->clone();

Returns a new C<TColor> object that is a copy of the current one.

=head2 equals

  my $bool = $self->equals($other | $bios);

Returns true if both values represent exactly the same color value and type; 
support typecast to a BIOS value if one is a number.

=head2 isDefault

  my $bool = $self->isDefault();

Returns true if the value represents the terminal default color.

=head2 isBIOS

  my $bool = $self->isBIOS();

Returns true if the value represents a BIOS color.

=head2 isRGB

  my $bool = $self->isRGB();

Returns true if the value represents a 24-bit RGB color.

=head2 isXTerm

  my $bool = $self->isXTerm();

Returns true if the value represents an XTerm color.

=head2 toBIOS

  my $bios = $self->toBIOS(
    $isForeground,
  );

Returns a BIOS color equivalent to the current value.

RGB and XTerm colors are quantized to the nearest BIOS-compatible color.

When the value represents the terminal default color, the returned value is
the standard foreground or background BIOS color depending on the value of
C<$isForeground>.

=head1 OPERATORS

=head2 Numeric equality

  $a == $b

Returns true when C<TColor> values contain identical data; support 
typecast to a C<TColor> value if one is a number.

=head2 Numeric conversion

  my $bits = 0+ $color;

Returns the encoded color value as an integer.

The returned value contains both the color type and color data.

=head1 SEE ALSO

L<TUI::Drivers::Const>,
L<TColorAttr|TUI::Drivers::ColorAttr>,
L<TScreenCell|TUI::Drivers::ScreenCell>,
L<Convert::Color>

=head1 AUTHORS

=over

=item * magiblot <magiblot@hotmail.com> (original color attribute design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019-2026 the L</AUTHORS> listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
