use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('Test::CPAN::Health::Result');

# ---------------------------------------------------------------------------
# Constructor: required fields
# ---------------------------------------------------------------------------

throws_ok(
	sub { Test::CPAN::Health::Result->new(status => 'pass') },
	qr/check_id/i,
	'new() croaks without check_id',
);

throws_ok(
	sub { Test::CPAN::Health::Result->new(check_id => 'x') },
	qr/status/i,
	'new() croaks without status',
);

throws_ok(
	sub { Test::CPAN::Health::Result->new(check_id => 'x', status => 'bogus') },
	qr/invalid status/i,
	'new() croaks on unknown status',
);

# ---------------------------------------------------------------------------
# Minimal construction
# ---------------------------------------------------------------------------

my $result = Test::CPAN::Health::Result->new(
	check_id => 'sem_ver',
	status   => 'pass',
);

isa_ok($result, 'Test::CPAN::Health::Result');
is($result->check_id, 'sem_ver', 'check_id accessor');
is($result->status,   'pass',    'status accessor');
is($result->score,    undef,     'score defaults to undef');
is($result->summary,  '',        'summary defaults to empty string');
is_deeply($result->details, [],  'details defaults to empty arrayref');
is($result->url,      undef,     'url defaults to undef');
is_deeply($result->data, {},     'data defaults to empty hashref');

# ---------------------------------------------------------------------------
# Status predicates
# ---------------------------------------------------------------------------

for my $status (qw(pass warn fail skip error)) {
	my $r = Test::CPAN::Health::Result->new(check_id => 'x', status => $status);
	my $pred = "is_$status";
	ok($r->$pred(),   "$pred() true  for status=$status");
	for my $other (qw(pass warn fail skip error)) {
		next if $other eq $status;
		my $other_pred = "is_$other";
		ok(!$r->$other_pred(), "$other_pred() false for status=$status");
	}
}

# ---------------------------------------------------------------------------
# Full construction and as_hash
# ---------------------------------------------------------------------------

my $full = Test::CPAN::Health::Result->new(
	check_id => 'security_advisories',
	status   => 'fail',
	score    => 0,
	summary  => 'CVE found',
	details  => ['CVE-2024-1234 in Foo 1.00'],
	url      => 'https://example.com/advisory',
	data     => { count => 1 },
);

my $h = $full->as_hash;

is($h->{check_id},   'security_advisories',      'as_hash check_id');
is($h->{status},     'fail',                      'as_hash status');
is($h->{score},      0,                           'as_hash score');
is($h->{summary},    'CVE found',                 'as_hash summary');
is_deeply($h->{details}, ['CVE-2024-1234 in Foo 1.00'], 'as_hash details');
is($h->{url},        'https://example.com/advisory', 'as_hash url');
is_deeply($h->{data}, { count => 1 },             'as_hash data');

# as_hash must return a deep copy of mutable fields
$h->{details}[0] = 'mutated';
isnt($full->details->[0], 'mutated', 'as_hash details are a deep copy');

done_testing;
