use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Types::Common::String qw(
    SimpleStr
    NonEmptySimpleStr
    LowerCaseSimpleStr
    UpperCaseSimpleStr
    Password
    StrongPassword
    NonEmptyStr
    LowerCaseStr
    UpperCaseStr
    NumericCode
);

# TODO: need to check both the inlined and non-inlined versions!

ok(is_SimpleStr(''), 'SimpleStr');
ok(is_SimpleStr('a string'), 'SimpleStr 2');
ok(!is_SimpleStr("another\nstring"), 'SimpleStr 3');
ok(!is_SimpleStr(join('', ("long string" x 25))), 'SimpleStr 4');

ok(!is_NonEmptyStr(''), 'NonEmptyStr');
ok(is_NonEmptyStr('a string'), 'NonEmptyStr 2');
ok(is_NonEmptyStr("another string"), 'NonEmptyStr 3');
ok(is_NonEmptyStr(join('', ("long string" x 25))), 'NonEmptyStr 4');

ok(is_NonEmptySimpleStr('good str'), 'NonEmptySimplrStr');
ok(!is_NonEmptySimpleStr(''), 'NonEmptyStr 2');

ok(!is_Password('no'), 'Password');
ok(is_Password('okay'), 'Password 2');

ok(!is_StrongPassword('notokay'), 'StrongPassword');
ok(is_StrongPassword('83773r_ch01c3'), 'StrongPassword 2');

ok(!is_LowerCaseSimpleStr('NOTOK'), 'LowerCaseSimpleStr');
ok(is_LowerCaseSimpleStr('ok'), 'LowerCaseSimpleStr 2');
ok(!is_LowerCaseSimpleStr('NOTOK_123`"'), 'LowerCaseSimpleStr 3');
ok(is_LowerCaseSimpleStr('ok_123`"'), 'LowerCaseSimpleStr 4');

ok(!is_UpperCaseSimpleStr('notok'), 'UpperCaseSimpleStr');
ok(is_UpperCaseSimpleStr('OK'), 'UpperCaseSimpleStr 2');
ok(!is_UpperCaseSimpleStr('notok_123`"'), 'UpperCaseSimpleStr 3');
ok(is_UpperCaseSimpleStr('OK_123`"'), 'UpperCaseSimpleStr 4');

ok(!is_LowerCaseStr('NOTOK'), 'LowerCaseStr');
ok(is_LowerCaseStr("ok\nok"), 'LowerCaseStr 2');
ok(!is_LowerCaseStr('NOTOK_123`"'), 'LowerCaseStr 3');
ok(is_LowerCaseStr("ok\n_123`'"), 'LowerCaseStr 4');

ok(!is_UpperCaseStr('notok'), 'UpperCaseStr');
ok(is_UpperCaseStr("OK\nOK"), 'UpperCaseStr 2');
ok(!is_UpperCaseStr('notok_123`"'), 'UpperCaseStr 3');
ok(is_UpperCaseStr("OK\n_123`'"), 'UpperCaseStr 4');

ok(is_NumericCode('032'),  'NumericCode lives');
ok(!is_NumericCode('abc'),  'NumericCode dies' );
ok(!is_NumericCode('x18'),  'mixed NumericCode dies');

done_testing;
