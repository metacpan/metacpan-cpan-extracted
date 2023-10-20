#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More 'no_plan';

require_ok('Term::DataMatrix');

if (eval {
    Term::DataMatrix->new(
        black => 'on_green',
        unknown_parameter => 1,
    );
}) {
    fail('->new() should abort if given an unknown parameter');
}

# Error message should mention it too.
like($@, qr/unknown_parameter/,
    '->new() should mention what went wrong'
);
unlike($@, qr/black/,
    '->new() should not mention what went right'
);
