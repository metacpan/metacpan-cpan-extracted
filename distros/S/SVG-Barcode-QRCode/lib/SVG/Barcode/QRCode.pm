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

our $VERSION = '0.10';

use constant DEFAULTS => {
  dotsize => 1,
  level   => 'M',
  version => 0,
};

SVG::Barcode::_param(__PACKAGE__, $_, DEFAULTS->{$_}) for keys DEFAULTS->%*;

# functions

sub plot_qrcode ($text, %params) {
  return __PACKAGE__->new(%params)->plot($text);
}

# internal methods

sub _plot ($self, $text) {
  $self->{plotter} ||= Text::QRCode->new($self->%{qw|level version|});
  $self->_plot_2d($self->{plotter}->plot($text), '*');
}

1;

=encoding utf8

=head1 NAME

SVG::Barcode::QRCode - Generator for SVG based QR Codes

=head1 SYNOPSIS

    use SVG::Barcode::QRCode;

    my $qrcode = SVG::Barcode::QRCode->new;
    my $svg    = $qrcode->plot('https://perldoc.pl');

    $qrcode->level;         # M
    $qrcode->dotsize;       # 1
    $qrcode->version;       # 0
                            # from SVG::Barcode:
    $qrcode->foreground;    # black
    $qrcode->background;    # white
    $qrcode->margin;        # 2
    $qrcode->id;
    $qrcode->class;
    $qrcode->width;
    $qrcode->height;

    my %params = (
      level  => 'H',
      margin => 4,
    );
    $qrcode = SVG::Barcode::QRCode->new(%params);

    # use as function
    use SVG::Barcode::QRCode 'plot_qrcode';

    $svg = plot_qrcode('https://perldoc.pl', %params);

=head1 DESCRIPTION

L<SVG::Barcode::QRCode> is a generator for SVG based QR Codes.

=head1 FUNCTIONS

=head2 plot_qrcode

    use SVG::Barcode::QRCode 'plot_qrcode';

    $svg = plot_qrcode($text, %params);

Returns a QR Code using the provided text and parameters.

=head1 CONSTRUCTOR

=head2 new

    $qrcode = SVG::Barcode::QRCode->new;            # create with defaults
    $qrcode = SVG::Barcode::QRCode->new(%params);

Creates a new QR Code plotter. Inherited from L<SVG::Barcode|SVG::Barcode/new>.

=head1 METHODS

=head2 plot

    $svg = $qrcode->plot($text);

Creates a SVG code. Inherited from L<SVG::Barcode|SVG::Barcode/plot>.

=head1 PARAMETERS

Inherited from L<SVG::Barcode>:
L<background|SVG::Barcode/background>,
L<class|SVG::Barcode/class>,
L<foreground|SVG::Barcode/foreground>,
L<height|SVG::Barcode/height>,
L<id|SVG::Barcode/id>,
L<margin|SVG::Barcode/margin>,
L<width|SVG::Barcode/width>.

=head2 dotsize

    $value  = $qrcode->dotsize;
    $qrcode = $qrcode->dotsize($newvalue);
    $qrcode = $qrcode->dotsize('');          # 1

Getter and setter for the size of the dots. Default C<1>.

=head2 level

    $value  = $qrcode->level;
    $qrcode = $qrcode->level($newvalue);
    $qrcode = $qrcode->level('');          # M

Getter and setter for the error correction level.
One of one of C<L> (low), C<M> (medium), C<Q> (quartile), C<H> (high). Default C<M>.

=head2 version

    $value  = $qrcode->version;
    $qrcode = $qrcode->version($newvalue);
    $qrcode = $qrcode->version('');          # 0

Getter and setter for the symbol version.
From C<1> to C<40>. C<0> will adapt the version to the required capacity. Default C<0>.

=head1 SEE ALSO

L<SVG::Barcode>, L<Text::QRCode>.

=head1 AUTHOR & COPYRIGHT

© 2019 by Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
