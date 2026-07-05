use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::Complexity;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::Complexity->new;
isa_ok($check, 'Test::CPAN::Health::Check::Complexity');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'complexity',           'id');
is($check->name,     'Cyclomatic Complexity', 'name');
is($check->weight,   4,                       'weight');
is($check->category, 'quality',               'category');

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
# Simple subroutines (low complexity) -> pass
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'Simple.pm', <<'END');
package Simple;

use strict;
use warnings;

sub new   { bless {}, shift }
sub hello { return 'hi' }
sub add   { return $_[1] + $_[2] }

1;
END

	my $result = $check->run($dist);
	is($result->status, 'pass', 'simple subs -> pass');
	is($result->score,  100,    'no complex subs -> score 100');
	is($result->data->{complex}, 0, 'data: 0 complex subs');
}

# ---------------------------------------------------------------------------
# Subroutine with high cyclomatic complexity -> warn or fail
# A sub with 25 if/elsif branches has complexity >= 25 > threshold of 20.
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();

	my $branches = join("\n", map { "	elsif (\$x == $_) { return $_ }" } 1..24);
	write_lib_pm($tmp, 'Complex.pm', <<"END");
package Complex;
use strict;
use warnings;

sub complex_sub {
	my (\$x) = \@_;
	if (\$x == 0) { return 0 }
$branches
	else { return -1 }
}

1;
END

	my $result = $check->run($dist);
	isnt($result->status, 'pass', 'complex sub is not pass');
	ok($result->data->{complex} > 0, 'data: at least 1 complex sub');
	ok($result->score < 100, 'complex code: score < 100');
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
	is($result->check_id, 'complexity', 'result carries correct check_id');
}

done_testing;
