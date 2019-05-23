package SVG::Barcode;
use strict;
use warnings;
use utf8;
use v5.24;
use feature 'signatures';
no warnings 'experimental::signatures';

use Carp 'croak';
use POSIX 'fmax';

our $VERSION = '0.02';

use constant DEFAULTS =>
  {background => 'white', foreground => 'black', margin => 10,};

# constructor

sub new ($class, $params = {}) {
  my $self = bless {}, $class;

  for (keys $class->DEFAULTS->%*) {
    $self->{$_} = $class->DEFAULTS->{$_};
  }
  for (keys $params->%*) {
    $self->param($_, $params->{$_});
  }

  return $self;
}

# methods

sub param ($self, $name, $newvalue = undef) {
  if (defined $newvalue) {
    croak "Unknown parameter $name!" unless $self->DEFAULTS->{$name};
    $self->{$name} = $newvalue eq '' ? $self->DEFAULTS->{$name} : $newvalue;
    delete $self->{plotter};
    return $self;
  } else {
    return $self->{$name};
  }
}

sub plot ($self, $text) {
  $self->{elements}
    = [qq|  <rect width="100%" height="100%" fill="$self->{background}"/>|];
  $self->{width} = $self->{height} = 0;

  $self->_plot($text);

  $self->{height} += $self->{margin};
  $self->{width}  += $self->{margin};
  my $svg
    = qq|<svg width="$self->{width}" height="$self->{height}" xmlns="http://www.w3.org/2000/svg">\n|
    . join("\n", $self->{elements}->@*)
    . qq|\n</svg>|;

  return $svg;
}

# internal methods

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
  my $size    = $self->{size};
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
          $dot[2] += $size;
        } else {
          @dot = ($x * $size, $y * $size, $size, $size);
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
  $self->{width}  = fmax $self->{width},  $x1 + $width;
  $self->{height} = fmax $self->{height}, $y1 + $height;

  push $self->{elements}->@*,
    qq|  <rect x="$x1" y="$y1" width="$width" height="$height" fill="$color"/>|;

  return $self;
}

sub _text ($self, $text, $x, $y, $size, $color = $self->{foreground}) {
  my $escaped = $self->_xml_escape($text);
  my $x1      = $x + $self->{margin};
  my $y1      = $y + $self->{margin};
  $self->{height} = fmax $self->{height}, $y1;

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

    my $plotter = SVG::Barcode::Subclass->new(\%params)
    $plotter->param(param_name => 'newvalue');
    my $svg = $plotter->plot($text);

=head1 DESCRIPTION

L<SVG::Barcode> is a base class for SVG 1D and 2D codes.

You will not use it directly, it will be loaded by its subclasses:

=over

=item * L<SVG::Barcode::Code128>

=item * L<SVG::Barcode::QRCode>

=back

=head1 CONSTRUCTOR

=head2 new

    $plotter = SVG::Barcode::Subclass->new(\%params);
    $plotter = SVG::Barcode::Subclass->new;             # create with defaults

=head1 METHODS

=head2 param

    $value = $plotter->param($name);
    $svg   = $plotter->param($name, $newvalue);
    $svg   = $plotter->param($name, '');          # set to default

Getter and setter for the parameters.

=head2 plot

    $svg = $plotter->plot($text);

Creates a QR Code.

=head1 SEE ALSO

L<SVG::Barcode::QRCode>.

=head1 AUTHOR & COPYRIGHT

© 2019 by Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
