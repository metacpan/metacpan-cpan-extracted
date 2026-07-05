use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('Test::CPAN::Health::Report');
use_ok('Test::CPAN::Health::Result');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_result {
	my (%args) = @_;
	my %result_args = (
		check_id => $args{check_id} // 'test',
		status   => $args{status}   // 'pass',
		data     => { category => $args{category} // 'quality', %{ $args{data} // {} } },
	);
	$result_args{score} = $args{score} if exists $args{score};
	return Test::CPAN::Health::Result->new(%result_args);
}

# Minimal mock check object -- Report only needs ->id and ->weight
{
	package MockCheck;
	sub new { bless { id => $_[1], weight => $_[2] }, $_[0] }
	sub id     { $_[0]->{id}     }
	sub weight { $_[0]->{weight} }
}

# ---------------------------------------------------------------------------
# Empty report
# ---------------------------------------------------------------------------

my $empty = Test::CPAN::Health::Report->new;
is($empty->overall_score, 0,  'empty report scores 0');
is(scalar @{$empty->results}, 0, 'empty results');

# ---------------------------------------------------------------------------
# Single passing result
# ---------------------------------------------------------------------------

my $report = Test::CPAN::Health::Report->new(
	checks => [MockCheck->new('sem_ver', 3)],
);
$report->add_result(make_result(check_id => 'sem_ver', status => 'pass', score => 100));
is($report->overall_score, 100, 'single pass = 100');

# ---------------------------------------------------------------------------
# Weighted average
# ---------------------------------------------------------------------------

my $w_report = Test::CPAN::Health::Report->new(
	checks => [
		MockCheck->new('check_a', 1),
		MockCheck->new('check_b', 3),
	],
);
$w_report->add_result(make_result(check_id => 'check_a', score => 100));
$w_report->add_result(make_result(check_id => 'check_b', score =>  60));

# Expected: (100*1 + 60*3) / (1+3) = 280/4 = 70
is($w_report->overall_score, 70, 'weighted average score');

# ---------------------------------------------------------------------------
# Hard cap: security_advisories fail caps at 60
# ---------------------------------------------------------------------------

my $cap_report = Test::CPAN::Health::Report->new(
	checks => [MockCheck->new('security_advisories', 10)],
);
$cap_report->add_result(make_result(
	check_id => 'security_advisories',
	status   => 'fail',
	score    => 0,
));
ok($cap_report->overall_score <= 60, 'security_advisories fail caps score at 60');

# ---------------------------------------------------------------------------
# Score is re-computed after add_result (cache invalidation)
# ---------------------------------------------------------------------------

my $inc = Test::CPAN::Health::Report->new(
	checks => [MockCheck->new('c', 1)],
);
$inc->add_result(make_result(check_id => 'c', score => 50));
is($inc->overall_score, 50, 'score after first add');
$inc->add_result(make_result(check_id => 'd', score => 100));
isnt($inc->overall_score, 50, 'score invalidated and recomputed after second add');

# ---------------------------------------------------------------------------
# Skip results are excluded from scoring
# ---------------------------------------------------------------------------

my $skip_report = Test::CPAN::Health::Report->new(
	checks => [MockCheck->new('skip_me', 5)],
);
$skip_report->add_result(make_result(check_id => 'skip_me', status => 'skip'));
$skip_report->add_result(make_result(check_id => 'real',    status => 'pass', score => 80));
is($skip_report->overall_score, 80, 'skip results excluded from weighted average');

# ---------------------------------------------------------------------------
# by_status / by_category
# ---------------------------------------------------------------------------

my $grp = Test::CPAN::Health::Report->new;
$grp->add_result(make_result(status => 'pass',  category => 'quality'));
$grp->add_result(make_result(status => 'fail',  category => 'security'));
$grp->add_result(make_result(status => 'warn',  category => 'quality'));

my $by_s = $grp->by_status;
is(scalar @{$by_s->{pass}},  1, 'by_status pass count');
is(scalar @{$by_s->{fail}},  1, 'by_status fail count');
is(scalar @{$by_s->{warn}},  1, 'by_status warn count');

my $by_c = $grp->by_category;
is(scalar @{$by_c->{quality}},  2, 'by_category quality count');
is(scalar @{$by_c->{security}}, 1, 'by_category security count');

# ---------------------------------------------------------------------------
# Convenience counts
# ---------------------------------------------------------------------------

is($grp->pass_count,  1, 'pass_count');
is($grp->fail_count,  1, 'fail_count');
is($grp->warn_count,  1, 'warn_count');
is($grp->skip_count,  0, 'skip_count');
is($grp->error_count, 0, 'error_count');

# ---------------------------------------------------------------------------
# add_result returns $self (chainable)
# ---------------------------------------------------------------------------

my $chain = Test::CPAN::Health::Report->new;
isa_ok(
	$chain->add_result(make_result(status => 'pass', score => 100)),
	'Test::CPAN::Health::Report',
	'add_result is chainable',
);

done_testing;
