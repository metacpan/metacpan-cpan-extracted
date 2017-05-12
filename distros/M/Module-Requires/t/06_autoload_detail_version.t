use strict;
use warnings;
use lib 't/lib';
use Test::More;
require Module::Requires;

eval {
    Module::Requires->import(
        'ClassA' => {
            version => [ '>' => 0.01, '!=' => 0.02 ],
        },
    );
};
like($@, qr/ClassA is unloaded because -autoload an option is lacking./);

ok(!ClassA->can('package'));

eval {
    Module::Requires->import(
        '-autoload',
        'ClassA' => {
            import  => [qw/ foo bar baz /],
            version => [ '>' => 0.01, '!=' => 0.02 ],
        },
    );
};
like($@, qr/ClassA version > 0.01 AND != 0.02 required--this is only version 0.02/);
is(ClassA->params, '');

eval {
    Module::Requires->import(
        '-autoload',
        'ClassA' => {
            import  => [qw/ foo bar baz /],
            version => [ '>' => 0.01, '!=' => 0.02 ],
        },
        'ClassB' => '0.10',
        'ClassC' => {
            version => [ '>' => 5.8 ],
        }
    );
};
like($@, qr/ClassA version > 0.01 AND != 0.02 required--this is only version 0.02\nClassB version 0.10 required--this is only version 0.08\nClassC version > 5.8 required--this is only version 0.12/);
is(ClassA->params, '');

eval {
    Module::Requires->import(
        '-autoload',
        'ClassA' => {
            import  => [qw/ foo bar baz /],
            version => [ '>' => 0.01, '!=' => 0.02 ],
        },
        'ClassB' => '0.02',
        'ClassC' => {
            version => [ '>' => 5.8 ],
        }
    );
};
like($@, qr/ClassA version > 0.01 AND != 0.02 required--this is only version 0.02\nClassC version > 5.8 required--this is only version 0.12/);
unlike($@, qr/ClassB.+Module::Requires::import/);
is(ClassA->params, '');


eval {
    Module::Requires->import(
        '-autoload',
        'ClassA' => {
            import  => [qw/ foo bar baz /],
            version => [ '>' => 0.01, '!=' => 0.06 ],
        },
        'ClassB' => '0.02',
        'ClassC' => {
            version => [ '>' => 0.08 ],
        }
    );
};
is($@, '');
is(ClassA->params, 'ClassA, foo, bar, baz');

done_testing;
