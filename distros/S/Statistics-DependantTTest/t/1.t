# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Statistics::DependantTTest') };

#########################

ok ($t_test = new Statistics::DependantTTest, 'created a t_test object');
ok ($t_test->load_data('before','4','4','5','5','3'), 'loaded data');
$t_test->load_data('after','6','5','6','6','5');
ok (($t_value,$deg_freedom) = $t_test->perform_t_test('before','after'), 'perform t test');
is ($deg_freedom, 4, 'degrees freedom correct');
is ($t_value, -5.71547606649408, 't value correct');
