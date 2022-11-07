use Test::More;

use_ok('SQL::Load');

can_ok(
    'SQL::Load',
    'new',
    'load'
);

use_ok('SQL::Load::Method');

can_ok(
    'SQL::Load::Method',
    'new',
    'default',
    'name',
    'at',
    'next',
    'first',
    'last',
    'replace'
);

use_ok('SQL::Load::Util');

can_ok(
    'SQL::Load::Util',
    'name_list',
    'parse',
    'remove_extension',
    'trim'
);

done_testing;
