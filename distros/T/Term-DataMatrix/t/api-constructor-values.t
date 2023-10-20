#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

require_ok('Term::DataMatrix');

my $dmcode;

# Ensure custom values for *_text show up when specified via constructor.
$dmcode = Term::DataMatrix->new(
    white_text => 'W' x 7,
    black_text => 'B' x 5,
);
# Ensure values we specify in each show up.
like(scalar $dmcode->plot('hello'),
    qr/W{7}/,
    'value of white_text should show up in output of ->plot()'
);
like(scalar $dmcode->plot('hello'),
    qr/B{5}/,
    'value of black_text should show up in output of ->plot()'
);

# Ensure ONLY values we specified show up.
# Note: We really shouldn't care in this test if the string from ->plot() ends
# in a newline.
like(scalar $dmcode->plot('hello') . "\n",
    qr/^([WB]+\n)+\n*$/m,
    'only values for white_text and black_text should show up in output of ->plot()'
);
