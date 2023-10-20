#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

require_ok('Term::DataMatrix');

my $barcode = Term::DataMatrix->new->plot('hello world');
my $barcode_again = Term::DataMatrix->new->plot('hello world');

is($barcode, $barcode_again,
    'barcodes of the same text should be the same'
);

my $dmcode = Term::DataMatrix->new;
isnt($dmcode->plot('foo bar'), $dmcode->plot('baz qux'),
    'barcodes of different text should not be the same'
);
