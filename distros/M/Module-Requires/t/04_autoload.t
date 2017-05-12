use strict;
use warnings;
use lib 't/lib';
use Test::More;
require Module::Requires;

eval {
    Module::Requires->import(
        'ClassA' => {
            import => [qw/ foo bar baz /],
        }
    );
};
like($@, qr/ClassA is unloaded because -autoload an option is lacking./);

ok(!ClassA->can('package'));

eval {
    Module::Requires->import(
        'ClassA' => {
            import => [qw/ foo bar baz /],
        },
        'ClassC' => {
            import => [qw/ foo bar baz /],
        }
    );
};
like($@, qr/ClassA is unloaded because -autoload an option is lacking.\nClassC is unloaded because -autoload an option is lacking./);
ok(!ClassA->can('package'));
ok(!ClassC->can('package'));

eval {
    Module::Requires->import(
        '-autoload',
        'ClassA' => {
            import => [qw/ foo bar baz /],
        }
    );
};
is($@, '');
is(ClassA->params, 'ClassA, foo, bar, baz');

Module::Requires->import(
    '-autoload',
    'ClassI' => { import => [] },
);
eval {
    export();
};
like($@, qr/Undefined subroutine &main::export called/);

Module::Requires->import(
    '-autoload',
    'ClassI' => { import => [qw/ testa testb /] },
);
is(testa(), 'OK');
is(testb(), 'OK');
eval {
    export();
};
like($@, qr/Undefined subroutine &main::export called/);

Module::Requires->import(
    '-autoload',
    'ClassI',
);
is(export(), 'OK');

done_testing;
