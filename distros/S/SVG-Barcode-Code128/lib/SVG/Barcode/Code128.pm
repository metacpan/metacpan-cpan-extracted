package SVG::Barcode::Code128;
use parent 'SVG::Barcode';
use strict;
use warnings;
use utf8;
use v5.24;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
our @EXPORT_OK = qw|plot_code128|;

use Barcode::Code128;

our $VERSION = '0.10';

use constant DEFAULTS => {
  lineheight => 30,
  linewidth  => 1,
  textsize   => 10,
};

SVG::Barcode::_param(__PACKAGE__, $_, DEFAULTS->{$_}) for keys DEFAULTS->%*;

# functions

sub plot_code128 ($text, %params) {
  return __PACKAGE__->new(%params)->plot($text);
}

# internal methods

sub _plot ($self, $text) {
  $self->{plotter} ||= Barcode::Code128->new;

  my @code = split //, $self->{plotter}->barcode($text);
  $self->_plot_1d(\@code, '#');
  $self->_plot_text($text);
}

1;

=encoding utf8

=head1 NAME

SVG::Barcode::Code128 - Generator for SVG based Code 128 barcodes

=head1 SYNOPSIS

    use SVG::Barcode::Code128;

    my $code128 = SVG::Barcode::Code128->new;
    my $svg     = $code128->plot('https://perldoc.pl');

    $code118->linewidth;     # 1
    $code118->lineheight;    # 30
    $code118->textsize;      # 10
                             # from SVG::Barcode:
    $code118->foreground;    # black
    $code118->background;    # white
    $code118->margin;        # 2
    $code118->id;
    $code118->class;
    $code118->width;
    $code118->height;

    my %params = (
      lineheight => 40,
      textsize   => 0,
    );
    $code128 = SVG::Barcode::Code128->new(%params);

    # use as function
    use SVG::Barcode::Code128 'plot_code128';

    my $svg = plot_code128('https://perldoc.pl', %params);

=head1 DESCRIPTION

L<SVG::Barcode::Code128> is a generator for SVG based Code 128 barcodes.

=head1 FUNCTIONS

=head2 plot_code128

    use SVG::Barcode::Code128 'plot_code128';

    $svg = plot_code128($text, %params);

Returns a Code 128 barcode using the provided text and parameters.

=head1 CONSTRUCTOR

=head2 new

    $code128 = SVG::Barcode::Code128->new;             # create with defaults
    $code128 = SVG::Barcode::Code128->new(\%params);

Creates a new Code 128 plotter. Inherited from L<SVG::Barcode|SVG::Barcode/new>.

=head1 METHODS

=head2 plot

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

=head2 lineheight

    $value  = $qrcode->lineheight;
    $qrcode = $qrcode->lineheight($newvalue);
    $qrcode = $qrcode->lineheight('');          # 30

Getter and setter for the height of a line. Default C<30>.

=head2 linewidth

    $value  = $qrcode->linewidth;
    $qrcode = $qrcode->linewidth($newvalue);
    $qrcode = $qrcode->linewidth('');          # 1

Getter and setter for the width of a single line. Default C<1>.

=head2 textsize

    $value  = $qrcode->textsize;
    $qrcode = $qrcode->textsize($newvalue);
    $qrcode = $qrcode->textsize('');          # 10

Getter and setter for the size of the text a the bottom. C<0> hides the text. Default C<10>.

=head1 SEE ALSO

L<SVG::Barcode>, L<Barcode::Code128>.

=head1 AUTHOR & COPYRIGHT

© 2019 by Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
