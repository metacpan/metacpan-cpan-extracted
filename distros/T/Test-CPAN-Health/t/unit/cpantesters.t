use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::CPANTesters;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::CPANTesters->new;
isa_ok($check, 'Test::CPAN::Health::Check::CPANTesters');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'cpan_testers', 'id');
is($check->name,     'CPAN Testers', 'name');
is($check->weight,   8,              'weight');
is($check->category, 'ci',           'category');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return ($tmp, Test::CPAN::Health::Distribution->new(path => $tmp));
}

# MockDist lets us supply a name without any filesystem layout.
package MockDist;
use parent -norequire, 'Test::CPAN::Health::Distribution';
sub new  { bless { _name => $_[1] }, $_[0] }
sub name { $_[0]->{_name} }
sub path { '/nonexistent' }

package main;

# ---------------------------------------------------------------------------
# run() croaks on wrong argument type
# ---------------------------------------------------------------------------

throws_ok(
	sub { $check->run('not a dist') },
	qr/must be a Test::CPAN::Health::Distribution/,
	'run() croaks on non-Distribution argument',
);

# ---------------------------------------------------------------------------
# Skip when no_network flag is set
# ---------------------------------------------------------------------------

{
	my $nn_check = Test::CPAN::Health::Check::CPANTesters->new(no_network => 1);
	my $dist     = MockDist->new('LWP-UserAgent');
	my $result   = $nn_check->run($dist);
	is($result->status, 'skip', 'no_network -> skip');
	like($result->summary, qr/network/i, 'summary mentions network');
}

# ---------------------------------------------------------------------------
# Skip when dist name not available (empty local checkout, no META)
# ---------------------------------------------------------------------------

{
	my $nn_check = Test::CPAN::Health::Check::CPANTesters->new(no_network => 1);
	my $dist     = MockDist->new(undef);    # undef name
	my $result   = $nn_check->run($dist);
	is($result->status, 'skip', 'undef dist name -> skip');
	like($result->summary, qr/network|name/i, 'summary explains skip reason');
}

# ---------------------------------------------------------------------------
# Result from the no_network fast path is a valid Result object
# ---------------------------------------------------------------------------

{
	my $c      = Test::CPAN::Health::Check::CPANTesters->new(no_network => 1);
	my $dist   = MockDist->new('Some-Dist');
	my $result = $c->run($dist);
	isa_ok($result, 'Test::CPAN::Health::Result');
	is($result->check_id, 'cpan_testers', 'result carries correct check_id');
}

# ---------------------------------------------------------------------------
# Live MetaCPAN call -- skipped only when NO_NETWORK_TESTING is set
# ---------------------------------------------------------------------------

SKIP: {
	skip q{Live network tests skipped (unset NO_NETWORK_TESTING to run)}, 8
		if $ENV{NO_NETWORK_TESTING};

	# LWP-UserAgent is a widely-used module with extensive CPAN Testers data.
	my $live_check = Test::CPAN::Health::Check::CPANTesters->new;
	my $dist       = MockDist->new('LWP-UserAgent');
	my $result     = $live_check->run($dist);

	isa_ok($result, 'Test::CPAN::Health::Result', 'live: returns a Result');
	ok(grep({ $result->status eq $_ } qw(pass warn fail error skip)),
		'live: status is valid');

	SKIP: {
		skip 'live: result was skip/error: ' . $result->summary, 6
			unless grep { $result->status eq $_ } qw(pass warn fail);

		ok(defined $result->score,                        'live: score defined');
		ok($result->score >= 0 && $result->score <= 100, 'live: score in 0..100');
		ok(exists $result->data->{pass},                  'live: data.pass exists');
		ok(exists $result->data->{fail},                  'live: data.fail exists');
		ok($result->data->{pass} + $result->data->{fail} > 0,
			'live: LWP-UserAgent has testers data');
		ok(defined $result->data->{pass_rate},            'live: data.pass_rate defined');
	}
}

done_testing;
