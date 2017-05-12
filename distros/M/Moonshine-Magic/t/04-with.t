use Moonshine::Test qw/:all/;

package Test::One;

use Moonshine::Magic;

use parent 'UNIVERSAL::Object';

with 't::roles::Bro';
with 't::roles::MiamiSpace';
with 't::roles::NLX2';

package Test::Two;

use Moonshine::Magic;

use parent 'UNIVERSAL::Object';

with (
    't::roles::Bro',
    't::roles::MiamiSpace',
    't::roles::NLX2',
);

package main;

my $instance = Test::One->new();

moon_test(
    name => 'with',
    instance => $instance,
    instructions => [
        { 
            test => 'true',
            func => 'true',
        },
        {
            test => 'false',
            func => 'false',
        },
        {
            test => 'true',
            func => 'plus',
        },
        {
            test => 'false',
            func => 'minus',
        },
        {
            test => 'scalar',
            func => 'nlx_rank',
            expected => 5,
        },
        {
            test => 'scalar',
            func => 'bro_rank',
            expected => 3,
        },
        {
            test => 'scalar',
            func => 'miamispace_rank',
            expected => 9,
        }, 
    ],
);

my $inst = Test::Two->new();

moon_test(
    name => 'with',
    instance => $inst,
    instructions => [
        { 
            test => 'true',
            func => 'true',
        },
        {
            test => 'false',
            func => 'false',
        },
        {
            test => 'true',
            func => 'plus',
        },
        {
            test => 'false',
            func => 'minus',
        },
        {
            test => 'scalar',
            func => 'nlx_rank',
            expected => 5,
        },
        {
            test => 'scalar',
            func => 'bro_rank',
            expected => 3,
        },
        {
            test => 'scalar',
            func => 'miamispace_rank',
            expected => 9,
        }, 
    ],
);

sunrise(16);
