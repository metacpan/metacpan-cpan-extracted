use strict;
use warnings;

use Test::More;

use Test::Deep;
use Test::Deep::Fuzzy;
use Test::Deep::Fuzzy::Number;

is +Test::Deep::Fuzzy::Number->new(0.1, 0.1)->range, 0.1, 'range is 0.1';
is +Test::Deep::Fuzzy::Number->new(0.008)->range, 0.000001, 'default range is 0.000001';

ok +Test::Deep::Fuzzy::Number::is_number(0.1),   '0.1 is number';
ok !Test::Deep::Fuzzy::Number::is_number(1),     '1 is not number';
ok !Test::Deep::Fuzzy::Number::is_number('10'),  '10 is not number';
ok !Test::Deep::Fuzzy::Number::is_number('abc'), 'abc is not number';


is +Test::Deep::Fuzzy::Number->new(0.123, 0.1)->diag_message('$data->{"number"}'),
    'Comparing $data->{"number"} equals 0.123 (in range: 0.1)',
    'diag message is collect';

is +Test::Deep::Fuzzy::Number->new(0.123, 0.1)->renderExp, q{0.1 ('0.123')}, 'rendered value is collect';

cmp_deeply {
    number => 0.0078125,
}, {
    number => is_fuzzy_num(0.008, 0.001),
}, 'is_fuzzy_num+cmp_deeply in range 0.001';

cmp_deeply {
    number => 0.0078125,
}, {
    number => is_fuzzy_num(0.007813),
}, 'is_fuzzy_num+cmp_deeply in default range';

done_testing();
