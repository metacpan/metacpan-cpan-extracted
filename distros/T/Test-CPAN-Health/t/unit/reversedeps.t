use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::ReverseDeps;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::ReverseDeps->new;
isa_ok($check, 'Test::CPAN::Health::Check::ReverseDeps');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'reverse_deps',        'id');
is($check->name,     'Reverse Dependencies', 'name');
is($check->weight,   2,                      'weight');
is($check->category, 'quality',              'category');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return ($tmp, Test::CPAN::Health::Distribution->new(path => $tmp));
}

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
	my $nn_check = Test::CPAN::Health::Check::ReverseDeps->new(no_network => 1);
	my (undef, $dist) = make_dist();
	my $result = $nn_check->run($dist);
	is($result->status, 'skip', 'no_network -> skip');
	like($result->summary, qr/network/i, 'summary mentions network');
}

# ---------------------------------------------------------------------------
# Result from the no_network fast path is a valid Result object
# ---------------------------------------------------------------------------

{
	my $c = Test::CPAN::Health::Check::ReverseDeps->new(no_network => 1);
	my (undef, $dist) = make_dist();
	my $result = $c->run($dist);
	isa_ok($result, 'Test::CPAN::Health::Result');
	is($result->check_id, 'reverse_deps', 'result carries correct check_id');
}

# ---------------------------------------------------------------------------
# Live MetaCPAN call -- skipped only when NO_NETWORK_TESTING is set
# ---------------------------------------------------------------------------

SKIP: {
	skip q{Live network tests skipped (unset NO_NETWORK_TESTING to run)}, 6
		if $ENV{NO_NETWORK_TESTING};

	# LWP-UserAgent is a well-known dist with many reverse deps.
	my $live_check = Test::CPAN::Health::Check::ReverseDeps->new;

	package MockDist;
	use parent -norequire, 'Test::CPAN::Health::Distribution';
	sub new  { bless { _name => $_[1] }, $_[0] }
	sub name { $_[0]->{_name} }
	sub path { '/nonexistent' }

	package main;

	my $dist   = MockDist->new('LWP-UserAgent');
	my $result = $live_check->run($dist);

	isa_ok($result, 'Test::CPAN::Health::Result', 'live: returns a Result');
	ok(grep({ $result->status eq $_ } qw(pass warn fail error skip)),
		'live: status is valid');

	SKIP: {
		skip 'live: result was error/skip: ' . $result->summary, 4
			unless grep { $result->status eq $_ } qw(pass warn);

		ok(defined $result->score,      'live: score defined');
		ok($result->score >= 0,         'live: score >= 0');
		ok(defined $result->data->{count}, 'live: data.count defined');
		ok($result->data->{count} > 0,  'live: LWP-UserAgent has reverse deps');
	}
}

done_testing;
