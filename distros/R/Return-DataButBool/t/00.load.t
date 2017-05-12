use Test::More tests => 24;

BEGIN {
use_ok( 'Return::DataButBool' );
}

diag( "Testing Return::DataButBool $Return::DataButBool::VERSION" );

ok(zero_but_true() eq '0e0', 'zero but true');

my $false_str = data_but_false(42,"hello");
ok(!$false_str ? 1 : 0, 'false 2 arg bool');
ok($false_str == 42, 'false 2 arg int');
ok($false_str eq 'hello', 'false 2 arg str');

my $false_def = data_but_false(3.14);
ok(!$false_def ? 1 : 0, 'false 1 arg bool');
ok($false_def == 3.14, 'false 1 arg int');
ok($false_def eq '3.14', 'false 1 arg str');

my $false_space = data_but_false(2,'');
ok($false_space eq '', 'false space');

my $true_str = data_but_true(0,"goodbye");
ok($true_str ? 1 : 0, 'true 2 arg bool');
ok($true_str == 0, 'true 2 arg int');
ok($true_str eq 'goodbye', 'true 2 arg str');

my $true_def = data_but_true(0);
ok($true_def ? 1 : 0, 'true 1 arg bool');
ok($true_def == 0, 'true 1 arg int');
ok($true_def eq '0', 'true 1 arg str');

my $true_space = data_but_true(2,'');
ok($true_space eq '', 'true space');

ok(Return::DataButBool::_get_num_from('3') eq '3', '_get_num_from whole');
ok(Return::DataButBool::_get_num_from('+3') eq '+3', '_get_num_from whole signed pos');
ok(Return::DataButBool::_get_num_from('-3') eq '-3', '_get_num_from whole signed neg');
ok(Return::DataButBool::_get_num_from('3.12') eq '3.12', '_get_num_from dec');
ok(Return::DataButBool::_get_num_from('+3.12') eq '+3.12', '_get_num_from dec signed pos');
ok(Return::DataButBool::_get_num_from('-3.12') eq '-3.12', '_get_num_from dec signed neg');
ok(Return::DataButBool::_get_num_from('42howdy') eq '42', 'string int() start');
ok(Return::DataButBool::_get_num_from('howdy') eq '0', 'string int() no num');