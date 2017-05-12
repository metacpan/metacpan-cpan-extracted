# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
# 1
BEGIN { use_ok('Statistics::KruskalWallis') };

#########################

@group_1 = (6.4,6.8,7.2,8.3,8.4,9.1,9.4,9.7);
@group_2 = (2.5,3.7,4.9,5.4,5.9,8.1,8.2);
@group_3 = (1.3,4.1,4.9,5.2,5.5,8.2);

# 2
ok (my $kw = new Statistics::KruskalWallis, 'created a Kruskal Wallis object');

# 3
ok ($kw->load_data('group 1',@group_1), 'loaded data');
$kw->load_data('group 2',@group_2);
$kw->load_data('group 3',@group_3);

#4
ok (my ($H,$p_value)=$kw->perform_kruskal_wallis_test(),'perform log rank test');

#5
is ($H, 9.83627087198516, 'Kruskal Wallis correct');

#6
is ($p_value, 0.0073128, 'p value correct');

# test post hoc stuff
# lets cheat and construct a blank test
my @null =('');
my $kw2 = new Statistics::KruskalWallis;

$kw2->load_data('group 1',@null);
$kw2->load_data('group 2',@null);
$kw2->load_data('group 3',@null);

$kw2->{rank_data}->{'group 1'}->{n} = 5;
$kw2->{rank_data}->{'group 1'}->{sum} = 54;
$kw2->{no_of_samples}=5;

$kw2->{rank_data}->{'group 2'}->{n} = 4;
$kw2->{rank_data}->{'group 2'}->{sum} = 26;
$kw2->{no_of_samples}+=4;

$kw2->{rank_data}->{'group 3'}->{n} = 4;
$kw2->{rank_data}->{'group 3'}->{sum} = 11;
$kw2->{no_of_samples}+=4;

#7
ok (my ($q,$p) = $kw2->post_hoc('Newman-Keuls','group 1','group 3'), 'perform Newman-Keuls test');
 
#8
is ($q, 3.08137498446259, 'Newman-Keuls statistic correct');

#9
is ($p, '>0.01', 'p value correct (as far as it goes)');




