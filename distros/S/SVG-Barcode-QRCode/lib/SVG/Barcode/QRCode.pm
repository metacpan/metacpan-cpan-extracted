package SVG::Barcode::QRCode;
use parent 'SVG::Barcode';
use strict;
use warnings;
use utf8;
use v5.24;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
our @EXPORT_OK = qw|plot_qrcode|;

use Text::QRCode;

our $VERSION = '0.01';

use constant DEFAULTS => {
  background => 'white',
  foreground => 'black',
  level      => 'M',
  margin     => 10,
  size       => 5,
  version    => 0,
};

# functions

sub plot_qrcode ($text, $params = {}) {
  return __PACKAGE__->new($params)->plot($text);
}

# internal methods

sub _plot ($self, $text) {
  $self->{plotter} ||= Text::QRCode->new($self->%{qw|level version|});

  my @qrcode    = $self->{plotter}->plot($text)->@*;
  my $dimension = @qrcode;

  my @dot;
  my $size    = $self->{size};
  my $add_dot = sub {
    if (@dot) {
      $self->_rect(@dot);
      @dot = ();
    }
  };

  for my $y (0 .. $dimension - 1) {
    for my $x (0 .. $dimension - 1) {
      if ($qrcode[$y][$x] eq '*') {
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

1;

=encoding utf8

=head1 NAME

SVG::Barcode::QRCode - Generator for SVG based QR Codes

=head1 SYNOPSIS

    use SVG::Barcode::QRCode;

    my %params = (
      background => 'white',
      foreground => 'black',
      level      => 'M',
      margin     => 10,
      size       => 5,
      version    => 0,
    );
    my $qrcode = SVG::Barcode::QRCode->new(\%params);
    my $svg    = $qrcode->plot('https://perldoc.pl');
    my $svg2   = $qrcode->param(foreground => 'red')->plot('https://perldoc.pl');

    # use as function
    use SVG::Barcode::QRCode 'plot_qrcode';

    my $svg = plot_qrcode('https://perldoc.pl', \%params);

=head1 DESCRIPTION

L<SVG::Barcode::QRCode> is a Generator for SVG based QR Codes.

=head1 FUNCTIONS

=head2 plot_qrcode

    use SVG::Barcode::QRCode 'plot_qrcode';

    my $svg = plot_qrcode($text, \%params);

Returns a QR Code using the provided text and parameters.

=head1 CONSTRUCTOR

=head2 new

    $qrcode = SVG::Barcode::QRCode->new(\%params);
    $qrcode = SVG::Barcode::QRCode->new;             # create with defaults

Creates a new QR Code plotter. Inherited from L<SVG::Barcode/new>.

Accepted parameters are:

=over 4

=item background

Color of the background. Default C<'white'>.

=item foreground

Color of the dots. Default C<'black'>.

=item level

Error correction level, one of C<'L'> (low), C<'M'> (medium), C<'Q'> (quartile), C<'H'> (high). Default C<'M'>.

=item margin

Margin around the code. Default C<10>.

=item size

Size of the dots. Default C<5>.

=item version

Symbol version from C<1> to C<40>. C<0> will adapt the version to the required capacity. Default C<0>.

=back

=head1 METHODS

=head2 param

Getter and setter for the parameters. Inherited from L<SVG::Barcode/param>.

=head2 plot

Creates a SVG code. Inherited from L<SVG::Barcode/plot>.

=head1 SEE ALSO

L<SVG::Barcode>, L<Text::QRCode>.

=head1 AUTHOR & COPYRIGHT

© 2019 by Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
