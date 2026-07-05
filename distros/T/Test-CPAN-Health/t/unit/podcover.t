use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::PODCoverage;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::PODCoverage->new;
isa_ok($check, 'Test::CPAN::Health::Check::PODCoverage');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'pod_coverage', 'id');
is($check->name,     'POD Coverage', 'name');
is($check->weight,   5,              'weight');
is($check->category, 'quality',      'category');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return ($tmp, Test::CPAN::Health::Distribution->new(path => $tmp));
}

sub write_lib_pm {
	my ($tmp, $filename, $content) = @_;
	my $lib = File::Spec->catdir($tmp, 'lib');
	make_path($lib);
	my $path = File::Spec->catfile($lib, $filename);
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} $content;
	close $fh;
	return $path;
}

# ---------------------------------------------------------------------------
# No .pm files -> skip
# ---------------------------------------------------------------------------

{
	my (undef, $dist) = make_dist();
	my $result = $check->run($dist);
	is($result->status, 'skip', 'no pm files -> skip');
}

# ---------------------------------------------------------------------------
# All public subs documented -> pass, score 100
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'Foo.pm', <<'END');
package Foo;

sub new    { bless {}, shift }
sub greet  { 'hello' }
sub _private { 1 }

=head1 NAME

Foo - a test module

=head2 new

Constructor.

=head2 greet

Returns a greeting.

=cut

1;
END

	my $result = $check->run($dist);
	is($result->status, 'pass', 'fully documented -> pass');
	is($result->score,  100,    'fully documented -> score 100');
	is($result->data->{covered}, 2, 'data: 2 subs covered');
	is($result->data->{total},   2, 'data: 2 total (private excluded)');
}

# ---------------------------------------------------------------------------
# Some subs undocumented -> warn
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'Bar.pm', <<'END');
package Bar;

sub new         { bless {}, shift }
sub documented  { 1 }
sub undocumented { 2 }

=head1 NAME

Bar - test

=head2 new

ctor

=head2 documented

does stuff

=cut

1;
END

	my $result = $check->run($dist);
	isnt($result->status, 'pass', 'partial coverage is not pass');
	ok($result->score < 100, 'partial coverage: score < 100');
	like($result->summary, qr/\d+ of \d+/, 'summary has coverage ratio');
}

# ---------------------------------------------------------------------------
# No public subs at all -> skip
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'Empty.pm', <<'END');
package Empty;

our $VERSION = '1.0';

=head1 NAME

Empty - nothing here

=cut

1;
END

	my $result = $check->run($dist);
	is($result->status, 'skip', 'no public subs -> skip');
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

{
	my (undef, $dist) = make_dist();
	my $result = $check->run($dist);
	isa_ok($result, 'Test::CPAN::Health::Result');
	is($result->check_id, 'pod_coverage', 'result carries correct check_id');
}

done_testing;
