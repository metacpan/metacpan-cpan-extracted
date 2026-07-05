use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('Test::CPAN::Health::Check::SemVer');

# ---------------------------------------------------------------------------
# Minimal mock distribution that exposes a meta() with a given version.
# ---------------------------------------------------------------------------

use Test::CPAN::Health::Distribution ();   # load so MockDist can satisfy isa()

{
	package MockMeta;
	sub new     { bless { version => $_[1] }, $_[0] }
	sub version { $_[0]->{version} }

	package MockDist;
	# Inherit just enough to satisfy blessed($dist)->isa('...Distribution')
	our @ISA = ('Test::CPAN::Health::Distribution');
	sub new     { bless { _version => $_[1] }, $_[0] }
	sub meta    { defined $_[0]->{_version} ? MockMeta->new($_[0]->{_version}) : undef }
	sub name    { 'Mock-Dist' }
	sub version { $_[0]->{_version} }
	sub path    { '/mock' }
}

my $check = Test::CPAN::Health::Check::SemVer->new;
isa_ok($check, 'Test::CPAN::Health::Check::SemVer');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'sem_ver',           'id');
is($check->name,     'Semantic Versioning','name');
is($check->weight,   3,                   'weight');
is($check->category, 'packaging',         'category');

sub run_check { $check->run(MockDist->new($_[0])) }

# ---------------------------------------------------------------------------
# No META -> skip
# ---------------------------------------------------------------------------

my $r = run_check(undef);
is($r->status, 'skip', 'no META -> skip');

# ---------------------------------------------------------------------------
# Strict semver: pass, score 100
# ---------------------------------------------------------------------------

for my $v (qw(1.0.0  1.2.3  0.0.1  v1.2.3  1.0.0-alpha  1.0.0-alpha.1  1.0.0+build.123)) {
	my $result = run_check($v);
	is($result->status, 'pass',  "semver $v -> pass");
	is($result->score,  100,     "semver $v -> score 100");
}

# ---------------------------------------------------------------------------
# Perl decimal: warn, score 60
# ---------------------------------------------------------------------------

for my $v (qw(1.23  0.27  1.000001  v1.2)) {
	my $result = run_check($v);
	is($result->status, 'warn', "decimal $v -> warn");
	is($result->score,  60,     "decimal $v -> score 60");
}

# ---------------------------------------------------------------------------
# Garbage: fail, score 0
# ---------------------------------------------------------------------------

for my $v ('', 'abc', 'r2025.07.01', '1', 'LATEST') {
	my $dist   = MockDist->new($v);
	my $result = $check->run($dist);

	if ($v eq '') {
		is($result->status, 'fail', "empty version -> fail");
		is($result->score,  0,      "empty version -> score 0");
	} else {
		is($result->status, 'fail', "garbage '$v' -> fail");
		is($result->score,  0,      "garbage '$v' -> score 0");
	}
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
# Result is a proper Result object
# ---------------------------------------------------------------------------

my $res = run_check('1.2.3');
isa_ok($res, 'Test::CPAN::Health::Result');
is($res->check_id, 'sem_ver', 'result carries correct check_id');

done_testing;
