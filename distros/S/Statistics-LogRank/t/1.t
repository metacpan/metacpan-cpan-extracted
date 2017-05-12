# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Statistics::LogRank') };

#########################

@group_1_survival = (99,98,95,90,90,87);
@group_1_deaths   = ( 1, 0, 3, 4, 0, 3);
@group_2_survival = (100,97,93,90,88,82);
@group_2_deaths   = (  0, 2, 4, 1, 2, 6);

ok (my $log_rank = new Statistics::LogRank, 'created a log rank object');
ok ($log_rank->load_data('group 1 survs',@group_1_survival), 'loaded data');
$log_rank->load_data('group 1 deaths',@group_1_deaths);
$log_rank->load_data('group 2 survs',@group_2_survival);
$log_rank->load_data('group 2 deaths',@group_2_deaths);
ok (my ($log_rank_stat,$p_value) = $log_rank->perform_log_rank_test('group 1 survs','group 1 deaths','group 2 survs','group 2 deaths'), 'perform log rank test');
is ($log_rank_stat, 0.757126797923934, 'log rank correct');
is ($p_value, 0.38423, 'p value correct');
