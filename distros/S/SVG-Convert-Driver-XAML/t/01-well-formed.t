BEGIN {
    our @svg = glob("./examples/*.svg");
    our $tests = scalar @svg;
};

use Test::More tests => $tests;
use SVG::Convert;

my $convert = SVG::Convert->new;

for $src (@svg) {
    my $doc = $convert->convert(format => "xaml", src_file => $src, output => "doc");
    ok($doc);
}
