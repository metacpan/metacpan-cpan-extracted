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

our $VERSION = '0.01';

use constant DEFAULTS => {
  background => 'white',
  foreground => 'black',
  lineheight => 30,
  linewidth  => 1,
  margin     => 10,
  textsize   => 10,
};

# functions

sub plot_code128 ($text, $params = {}) {
  return __PACKAGE__->new($params)->plot($text);
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

    my %params = (
      background => 'white',
      foreground => 'black',
      lineheight => 30,
      linewidth  => 2,
      margin     => 10,
      textsize   => 10,
    );
    my $code128 = SVG::Barcode::Code128->new(\%params);
    my $svg     = $code128->plot('https://perldoc.pl');
    my $svg2    = $code128->param(foreground => 'red')->plot('https://perldoc.pl');

    # use as function
    use SVG::Barcode::Code128 'plot_code128';

    my $svg = plot_code128('https://perldoc.pl', \%params);

=head1 DESCRIPTION

L<SVG::Barcode::Code128> is a generator for SVG based Code 128 barcodes.

=head1 FUNCTIONS

=head2 plot_code128

    use SVG::Barcode::Code128 'plot_code128';

    my $svg = plot_code128($text, \%params);

Returns a Code 128 barcode using the provided text and parameters.

=head1 CONSTRUCTOR

=head2 new

    $code128 = SVG::Barcode::Code128->new(\%params);
    $code128 = SVG::Barcode::Code128->new;             # create with defaults

Creates a new Code 128 plotter. Inherited from L<SVG::Barcode/new>.

Accepted parameters are:

=over 4

=item background

Color of the background. Default C<'white'>.

=item foreground

Color of the dots. Default C<'black'>.

=item lineheight

Height of the lines. Default C<30>.

=item linewidth

Width of a single line. Default C<2>.

=item margin

Margin around the code. Default C<10>.

=item textsize

Size of the text at the bottom of the code. C<0> means no text. Default C<10>.

=back

=head1 METHODS

=head2 param

Getter and setter for the parameters. Inherited from L<SVG::Barcode/param>.

=head2 plot

Creates a SVG code. Inherited from L<SVG::Barcode/plot>.

=head1 SEE ALSO

L<SVG::Barcode>, L<Barcode::Code128>.

=head1 AUTHOR & COPYRIGHT

© 2019 by Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
