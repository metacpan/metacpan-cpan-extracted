#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

require_ok('Term::DataMatrix');
use Term::ANSIColor qw/ color /;

my $dmcode = Term::DataMatrix->new;

my $barcode = $dmcode->plot('hello world');
my $expected_black_pixels = 141;
my %cc = _count_pixels($barcode);

# Smoke tests
cmp_ok($cc{on_black}, '>', 0,
    'barcode should contain more than 0 black pixels'
);
cmp_ok($cc{on_white}, '>', 0,
    'barcode should contain more than 0 white pixels'
);

# Note: The generated barcode might be stretched width- or height-wise.
is(0, $cc{on_black} % $expected_black_pixels,
    "barcode should contain a multiple of $expected_black_pixels black pixels"
);
# The background (white) pixels are less important. There may be padding added.
# But what we *do* know about the 'hello world' barcode is that there are more
# than 100 blanks in the barcode data.
cmp_ok($cc{on_white}, '>', 100,
    'barcode should contain more than 100 white pixels'
);

sub _count_pixels {
    my $barcode_text = shift;
    my $color_start = qr/\e\[[0-9;]+m/;
    # Lookahead match; each element of the list returned will start with the
    # pattern.
    my @parts = split /(?=$color_start)/, $barcode_text;

    my %color_counts;
    foreach my $part (@parts) {
        if ($part =~ /^($color_start)/p) {
            my $color = $1;
            my $text = ${^POSTMATCH};
            if (length $text) {
                $color_counts{$color} += length $text;
            }
        }
    }
    # Add in some aliases
    foreach my $color_name (qw/ on_black on_white /) {
        my $escape = color($color_name);
        if (exists $color_counts{$escape}) {
            $color_counts{$color_name} = $color_counts{$escape};
        }
    }
    return %color_counts;
}
