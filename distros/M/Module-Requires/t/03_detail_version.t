use strict;
use warnings;
use lib 't/lib';
use Test::More;
require Module::Requires;

eval {
    Module::Requires->import('ClassA', [ '>' => 0.04 ]);
};
like($@, qr/ClassA version > 0.04 required--this is only version 0.02/);

ok(ClassA->can('package'));

eval {
    Module::Requires->import('ClassA', [ '<' => 0.02 ]);
};
like($@, qr/ClassA version < 0.02 required--this is only version 0.02/);

eval {
    Module::Requires->import('ClassA', [ '<' => 0.02, '>' => 0.02 ]);
};
like($@, qr/ClassA version < 0.02 AND > 0.02 required--this is only version 0.02/);

eval {
    Module::Requires->import('ClassA', [ '<=' => 0.01, '>=' => 0.03 ]);
};
like($@, qr/ClassA version <= 0.01 AND >= 0.03 required--this is only version 0.02/);

eval {
    Module::Requires->import('ClassA', [ '>' => 0.01, '!=' => 0.02 ]);
};
like($@, qr/ClassA version > 0.01 AND != 0.02 required--this is only version 0.02/);

eval {
    Module::Requires->import('ClassA', [ '>' => 0.02, '=' => 0.02 ]);
};
like($@, qr/ClassA version check syntax error/);

eval {
    Module::Requires->import('ClassA', [ '>' => 0.02, 'y' ]);
};
like($@, qr/ClassA version check syntax error/);

eval {
    Module::Requires->import('ClassA', [ '>' => 0.01, '!=' => 0.03 ]);
};
is($@, '');

done_testing;
