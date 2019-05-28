package SVG::Barcode;
use strict;
use warnings;
use utf8;
use v5.24;
use feature 'signatures';
no warnings 'experimental::signatures';

use Carp 'croak';
use POSIX 'fmax';
use Sub::Util 'set_subname';

our $VERSION = '0.10';

use constant DEFAULTS => {
  background => 'white',
  class      => '',
  foreground => 'black',
  height     => '',
  id         => '',
  margin     => 2,
  width      => '',
};

_param(__PACKAGE__, $_, DEFAULTS->{$_}) for keys DEFAULTS->%*;

# constructor

sub new ($class, %params) {
  my $self = bless {DEFAULTS->%*, $class->DEFAULTS->%*}, $class;

  $self->$_($params{$_}) for keys %params;

  return $self;
}

# methods

sub plot ($self, $text) {
  $self->{elements}
    = [qq|  <rect width="100%" height="100%" fill="$self->{background}"/>|];
  $self->{vbwidth} = $self->{vbheight} = 0;

  $self->_plot($text);

  $self->{vbheight} += $self->{margin};
  $self->{vbwidth}  += $self->{margin};
  my @attr = (qq|viewBox="0 0 $self->{vbwidth} $self->{vbheight}"|);
  for my $name (qw|id class width height|) {
    my $value = $self->$name or next;
    push @attr, qq|$name="$value"|;
  }
  my $attributes = join ' ', sort @attr;

  my $svg
    = qq|<svg $attributes xmlns="http://www.w3.org/2000/svg">\n|
    . join("\n", $self->{elements}->@*)
    . qq|\n</svg>|;

  return $svg;
}

# internal methods

sub _param ($class, $name, $default) {
  no strict 'refs';    ## no critic 'ProhibitNoStrict'
  no warnings 'redefine';
  *{"${class}::$name"} = set_subname $name, sub ($self, $newvalue = undef) {
    if (defined $newvalue) {
      $self->{$name} = $newvalue eq '' ? $default : $newvalue;
      delete $self->{plotter};
      return $self;
    } else {
      return $self->{$name};
    }
  };
}

sub _plot (@) {
  croak 'Method _plot not implemented by subclass!';
}

sub _plot_1d ($self, $code, $sign) {
  my @line;
  my $width    = $self->{linewidth};
  my $height   = $self->{lineheight};
  my $add_line = sub {
    if (@line) {
      $self->_rect(@line);
      @line = ();
    }
  };

  for my $x (0 .. $#$code) {
    if ($code->[$x] eq $sign) {
      if (@line) {
        $line[2] += $width;
      } else {
        @line = ($x * $width, 0, $width, $height);
      }
    } else {
      $add_line->();
    }
  }
  $add_line->();
}

sub _plot_2d ($self, $code, $sign) {
  my $x_max = $code->[0]->@* - 1;
  my $y_max = $code->@* - 1;

  my @dot;
  my $dotsize = $self->{dotsize};
  my $add_dot = sub {
    if (@dot) {
      $self->_rect(@dot);
      @dot = ();
    }
  };

  for my $y (0 .. $y_max) {
    for my $x (0 .. $x_max) {
      if ($code->[$y][$x] eq $sign) {
        if (@dot) {
          $dot[2] += $dotsize;
        } else {
          @dot = ($x * $dotsize, $y * $dotsize, $dotsize, $dotsize);
        }
      } else {
        $add_dot->();
      }
    }
    $add_dot->();
  }
}

sub _plot_text ($self, $text) {
  if (my $size = $self->{textsize}) {
    $self->_text($text, 0, $self->{lineheight} + $size, $size);
  }
}

sub _rect ($self, $x, $y, $width, $height, $color = $self->{foreground}) {
  my $x1 = $x + $self->{margin};
  my $y1 = $y + $self->{margin};
  $self->{vbwidth}  = fmax $self->{vbwidth},  $x1 + $width;
  $self->{vbheight} = fmax $self->{vbheight}, $y1 + $height;

  push $self->{elements}->@*,
    qq|  <rect x="$x1" y="$y1" width="$width" height="$height" fill="$color"/>|;

  return $self;
}

sub _text ($self, $text, $x, $y, $size, $color = $self->{foreground}) {
  my $escaped = $self->_xml_escape($text);
  my $x1      = $x + $self->{margin};
  my $y1      = $y + $self->{margin};
  $self->{vbheight} = fmax $self->{vbheight}, $y1;

  push $self->{elements}->@*,
    qq|  <text x="$x1" y="$y1" font-size="$size" fill="$color">$escaped</text>|;

  return $self;
}

# from Mojo::Util
my %XML = (
  '&'  => '&amp;',
  '<'  => '&lt;',
  '>'  => '&gt;',
  '"'  => '&quot;',
  '\'' => '&#39;'
);

sub _xml_escape ($self, $str) {
  $str =~ s/([&<>"'])/$XML{$1}/ge;
  return $str;
}

1;

=encoding utf8

=head1 NAME

SVG::Barcode - Base class for SVG 1D and 2D codes

=head1 SYNOPSIS

    use SVG::Barcode::Subclass;

    my $plotter = SVG::Barcode::Subclass->new;

    $plotter->foreground;    # black
    $plotter->background;    # white
    $plotter->margin;        # 2
    $plotter->id;
    $plotter->class;
    $plotter->width;
    $plotter->height;

    %params = (
      foreground => 'red',
      id         => 'barcode',
    );
    $plotter = SVG::Barcode::Subclass->new(%params);

    my $svg = $plotter->plot($text);

=head1 DESCRIPTION

L<SVG::Barcode> is a base class for SVG 1D and 2D codes.

You will not use it directly, it will be loaded by its subclasses:

=over

=item * L<SVG::Barcode::Code128>

=item * L<SVG::Barcode::DataMatrix>

=item * L<SVG::Barcode::QRCode>

=back

=head1 CONSTRUCTOR

=head2 new

    $plotter = SVG::Barcode::Subclass->new;             # create with defaults
    $plotter = SVG::Barcode::Subclass->new(%params);

=head1 METHODS

=head2 plot

    $svg = $plotter->plot($text);

Creates a barcode.

=head1 PARAMETERS

=head2 background

    $value   = $plotter->background;
    $plotter = $plotter->background($newvalue);
    $plotter = $plotter->background('');          # white

Getter and setter for the background color. Default C<white>.

=head2 class

    $value   = $plotter->class;
    $plotter = $plotter->class($newvalue);
    $plotter = $plotter->class('');          # ''

Getter and setter for the class of the svg element. Default C<''>.

=head2 foreground

    $value   = $plotter->foreground;
    $plotter = $plotter->foreground($newvalue);
    $plotter = $plotter->foreground('');          # black

Getter and setter for the foreground color. Default C<black>.

=head2 height

    $value   = $plotter->height;
    $plotter = $plotter->height($newvalue);
    $plotter = $plotter->height('');          # ''

Getter and setter for the height of the svg element. Default C<''>.

=head2 id

    $value   = $plotter->id;
    $plotter = $plotter->id($newvalue);
    $plotter = $plotter->id('');          # ''

Getter and setter for the id of the svg element. Default C<''>.

=head2 margin

    $value   = $plotter->margin;
    $plotter = $plotter->margin($newvalue);
    $plotter = $plotter->margin('');          # 2

Getter and setter for the margin around the barcode. Default C<2>.

=head2 width

    $value   = $plotter->width;
    $plotter = $plotter->width($newvalue);
    $plotter = $plotter->width('');          # ''

Getter and setter for the width of the svg element. Default C<''>.

=head1 SEE ALSO

L<SVG::Barcode::Code128>, L<SVG::Barcode::DataMatrix>, L<SVG::Barcode::QRCode>.

=head1 AUTHOR & COPYRIGHT

© 2019 by Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
