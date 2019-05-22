package SVG::Barcode;
use strict;
use warnings;
use utf8;
use v5.24;
use feature 'signatures';
no warnings 'experimental::signatures';

use Carp 'croak';
use POSIX 'fmax';

our $VERSION = '0.01';

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
    $self->{$name} = $newvalue || $self->DEFAULTS->{$name};
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

sub _rect ($self, $x, $y, $width, $height, $color = $self->{foreground}) {
  my $x1 = $x + $self->{margin};
  my $y1 = $y + $self->{margin};
  $self->{width}  = fmax $self->{width},  $x1 + $width;
  $self->{height} = fmax $self->{height}, $y1 + $height;

  push $self->{elements}->@*,
    qq|  <rect x="$x1" y="$y1" width="$width" height="$height" fill="$color"/>|;

  return $self;
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
