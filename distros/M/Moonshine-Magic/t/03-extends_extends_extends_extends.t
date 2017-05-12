use Moonshine::Test qw(:all);

use lib 't/extends';
use BlackMagic;
use Wand;
use Spell;
use Fairy;

moon_test(
    name => 'base level',
    build => {
        class => 'BlackMagic',   
    },
    instructions => [
        {
            test => 'scalar',
            func => 'base',
            expected => 'we start here',
        }
    ],        
);

moon_test(
    name => 'one levels',
    build => {
        class => 'Wand',   
    },
    instructions => [
        {
            test => 'scalar',
            func => 'base',
            expected => 'we start here',
        },
        {
            test => 'scalar',
            func => 'draw',
            expected => 'extend one level'
        },
    ],        
);

moon_test(
    name => 'two levels',
    build => {
        class => 'Spell',   
    },
    instructions => [
        {
            test => 'scalar',
            func => 'base',
            expected => 'we start here',
        },
        {
            test => 'scalar',
            func => 'draw',
            expected => 'extend one level',
        },
        {
            test => 'scalar',
            func => 'cast',
            expected => 'almost...',
        },
    ],        
);

moon_test(
    name => 'three levels',
    build => {
        class => 'Fairy',   
    },
    instructions => [
        {
            test => 'scalar',
            func => 'base',
            expected => 'we start here',
        },
        {
            test => 'scalar',
            func => 'draw',
            expected => 'extend one level',
        },
        {
            test => 'scalar',
            func => 'cast',
            expected => 'almost...',
        },
        {
            test => 'scalar',
            func => 'destroy',
            expected => 'We made it.',
        },
    ],
);

sunrise(14, '*\o/*');
