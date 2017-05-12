use strict;
use warnings;
use lib 't/lib';
use Test::More;
require Module::Requires;

eval {
    Module::Requires->import(
        'ClassD',
    );
};
like($@, qr/Can't load ClassD\nCan't locate ClassD.pm/);
ok(!ClassA->can('package'));

eval {
    Module::Requires->import(
        'ClassD',
        'ClassA',
    );
};
like($@, qr/Can't load ClassD\nCan't locate ClassD.pm/);
ok(ClassA->can('package'));

eval {
    Module::Requires->import(
        'ClassE',
    );
};
like($@, qr/Can't load ClassE\nClassE.pm did not return a true value/);

eval {
    Module::Requires->import(
        'ClassF',
    );
};
like($@, qr/Can't load ClassF\nClassF.pm did not return a true value/);

eval {
    Module::Requires->import(
        'ClassG',
    );
};
like($@, qr/Can't load ClassG\nBareword "aaaaaa" not allowed while "strict subs" in use/);

done_testing;
