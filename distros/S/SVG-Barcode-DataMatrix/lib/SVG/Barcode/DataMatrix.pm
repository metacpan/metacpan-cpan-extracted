package SVG::Barcode::DataMatrix;
use parent 'SVG::Barcode';
use strict;
use warnings;
use utf8;
use v5.24;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
our @EXPORT_OK = qw|plot_datamatrix|;

use Barcode::DataMatrix;

our $VERSION = '0.13';

use constant DEFAULTS => {
  dotsize       => 1,
  encoding_mode => 'AUTO',
  process_tilde => 0,
  size          => 'AUTO',
};

SVG::Barcode::_param(__PACKAGE__, $_, DEFAULTS->{$_}) for keys DEFAULTS->%*;

# functions

sub plot_datamatrix ($text, %params) {
  return __PACKAGE__->new(%params)->plot($text);
}

# internal methods

sub _plot ($self, $text) {
  $self->{plotter}
    ||= Barcode::DataMatrix->new($self->%{qw|encoding_mode process_tilde size|});
  $self->_plot_2d($self->{plotter}->barcode($text), 1);
}

1;

=encoding utf8

=head1 NAME

SVG::Barcode::DataMatrix - Generator for SVG based Data Matrix barcodes

=head1 SYNOPSIS

    use SVG::Barcode::DataMatrix;

    my $datamatrix = SVG::Barcode::DataMatrix->new;
    my $svg        = $datamatrix->plot('https://perldoc.pl');

    $datamatrix->dotsize;          # 1
    $datamatrix->encoding_mode;    # AUTO
    $datamatrix->process_tilde;    # 0
    $datamatrix->size;             # AUTO
                                   # from SVG::Barcode:
    $datamatrix->foreground;       # black
    $datamatrix->background;       # white
    $datamatrix->margin;           # 2
    $datamatrix->id;
    $datamatrix->class;
    $datamatrix->width;
    $datamatrix->height;
    $datamatrix->scale;

    my %params = (
      level  => 'H',
      margin => 4,
    );
    $datamatrix = SVG::Barcode::DataMatrix->new(%params);

    # use as function
    use SVG::Barcode::DataMatrix 'plot_datamatrix';

    $svg = plot_datamatrix('https://perldoc.pl', %params);

=head1 DESCRIPTION

L<SVG::Barcode::DataMatrix> is a generator for SVG based Data Matrix barcodes.

=head1 FUNCTIONS

=head2 plot_datamatrix

    use SVG::Barcode::DataMatrix 'plot_datamatrix';

    $svg = plot_datamatrix($text, %params);

Returns a Data Matrix using the provided text and parameters.

=head1 CONSTRUCTOR

=head2 new

    $datamatrix = SVG::Barcode::DataMatrix->new;            # create with defaults
    $datamatrix = SVG::Barcode::DataMatrix->new(%params);

Creates a new Data Matrix plotter. Inherited from L<SVG::Barcode|SVG::Barcode/new>.

=head1 METHODS

=head2 plot

    $svg = $datamatrix->plot($text);

Creates a SVG code. Inherited from L<SVG::Barcode|SVG::Barcode/plot>.

=head1 PARAMETERS

Inherited from L<SVG::Barcode>:
L<background|SVG::Barcode/background>,
L<class|SVG::Barcode/class>,
L<foreground|SVG::Barcode/foreground>,
L<height|SVG::Barcode/height>,
L<id|SVG::Barcode/id>,
L<margin|SVG::Barcode/margin>,
L<scale|SVG::Barcode/scale>,
L<width|SVG::Barcode/width>.

=head2 dotsize

    $value      = $datamatrix->dotsize;
    $datamatrix = $datamatrix->dotsize($newvalue);
    $datamatrix = $datamatrix->dotsize('');          # 1

Getter and setter for the size of the dots. Default C<1>.

=head2 encoding_mode

    $value      = $datamatrix->encoding_mode;
    $datamatrix = $datamatrix->encoding_mode($newvalue);
    $datamatrix = $datamatrix->encoding_mode('');          # AUTO

Getter and setter for the encoding mode.
One of C<AUTO>, C<ASCII>, C<C40>, C<TEXT>, C<BASE256>, or C<NONE>. Default C<AUTO>.

=head2 process_tilde

    $value      = $datamatrix->process_tilde;
    $datamatrix = $datamatrix->process_tilde($newvalue);
    $datamatrix = $datamatrix->process_tilde('');          # 0

Getter and setter for the tilde flag.
If set to C<1> the tilde character C<~> is being used to recognize special characters.
Default C<0>.

=head2 size

    $value      = $datamatrix->size;
    $datamatrix = $datamatrix->size($newvalue);
    $datamatrix = $datamatrix->size('');          # AUTO

Getter and setter for the module size of the matrix.
C<height x width>, one of C<AUTO>, C<10x10>, C<12x12>, C<14x14>, C<16x16>, C<18x18>, C<20x20>, C<22x22>, C<24x24>, C<26x26>, C<32x32>, C<36x36>, C<40x40>, C<44x44>, C<48x48>, C<52x52>, C<64x64>, C<72x72>, C<80x80>, C<88x88>, C<96x96>, C<104x104>, C<120x120>, C<132x132>, C<144x144>, C<8x18>, C<8x32>, C<12x26>, C<12x36>, C<16x36>, C<16x48>.
Default C<AUTO>.

=head1 SEE ALSO

L<SVG::Barcode>, L<Barcode::DataMatrix>.

=head1 AUTHOR & COPYRIGHT

© 2019 by Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
