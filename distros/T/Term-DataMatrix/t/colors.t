#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

use Term::ANSIColor qw/ color /;
use List::Util qw/ max min /;
require_ok('Term::DataMatrix');

my $dmcode = Term::DataMatrix->new;

my $barcode = $dmcode->plot('hello world');
my $black = quotemeta color('on_black');
my $white = quotemeta color('on_white');
my $reset = quotemeta color('reset');

like($barcode, qr/$black/,
    'barcode should contain black color escapes'
);
like($barcode, qr/$white/,
    'barcode should contain white color escapes'
);
like($barcode, qr/$reset/,
    'barcode should contain color reset escapes'
);
