#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

use Carp qw/ croak /;
use Term::ANSIColor 2.01 qw/ colorstrip /;
use List::Util qw/ max min /;
require_ok('Term::DataMatrix');

my $dmcode = Term::DataMatrix->new;

# Barcode: 18x18 (including padding lines)
my $expected = 18;
my $barcode = $dmcode->plot('hello world');

my ($width, $height) = _barcode_dims($barcode);
# Note: The generated barcode might be stretched width- or height-wise.
is(0, $width % $expected,
    "barcode width should be a multiple of $expected"
);
is(0, $height % $expected,
    "barcode height should be a multiple of $expected"
);

sub _barcode_dims {
    my $barcode_text = shift;
    # Strip escape codes
    my $uncolored = colorstrip($barcode_text);
    my @lines = grep { length } split /\n/, $uncolored;
    my @line_lengths = map { length } @lines;
    my $mx = max(@line_lengths);
    my $mn = min(@line_lengths);
    if ($mx != $mn) {
        croak("Irregular line lengths! min=$mn max=$mx");
    }
    return ($mn, scalar @lines);
}
