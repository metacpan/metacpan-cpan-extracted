use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::DuplicateCode;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::DuplicateCode->new;
isa_ok($check, 'Test::CPAN::Health::Check::DuplicateCode');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'duplicate_code', 'id');
is($check->name,     'Duplicate Code',  'name');
is($check->weight,   3,                 'weight');
is($check->category, 'quality',         'category');

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
# No source files -> skip
# ---------------------------------------------------------------------------

{
	my (undef, $dist) = make_dist();
	my $result = $check->run($dist);
	is($result->status, 'skip', 'no source files -> skip');
}

# ---------------------------------------------------------------------------
# Single file, no duplication possible -> pass
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'Solo.pm', <<'END');
package Solo;

sub new  { bless {}, shift }
sub foo  { return 42 }
sub bar  { return 'hello' }
sub baz  { return [] }

1;
END

	my $result = $check->run($dist);
	is($result->status, 'pass', 'single file -> pass');
	is($result->data->{duplicates}, 0, 'data: 0 duplicates');
}

# ---------------------------------------------------------------------------
# Two files with distinct code -> pass, score 100
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_lib_pm($tmp, 'Alpha.pm', <<'END');
package Alpha;

sub new { bless {}, shift }
sub alpha_method { return 'alpha result' }
sub unique_alpha { return 'only in alpha' }
sub another_alpha { return 'alpha again' }

1;
END
	write_lib_pm($tmp, 'Beta.pm', <<'END');
package Beta;

sub new { bless {}, shift }
sub beta_method { return 'beta result' }
sub unique_beta { return 'only in beta' }
sub another_beta { return 'beta again' }

1;
END

	my $result = $check->run($dist);
	is($result->status, 'pass', 'distinct code -> pass');
	is($result->score,  100,    'distinct code -> score 100');
}

# ---------------------------------------------------------------------------
# Two files with an identical 6-line code block -> duplicate detected
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();

	# A distinct 6-line block copied verbatim into both files.
	my $shared_block = <<'BLOCK';
my $a = 10;
my $b = 20;
my $c = $a + $b;
my $d = $c * 2;
my $e = $d - 5;
return $e;
BLOCK

	write_lib_pm($tmp, 'Dup1.pm', <<"END");
package Dup1;
sub compute {
$shared_block}
sub other_dup1 { return 1 }
1;
END

	write_lib_pm($tmp, 'Dup2.pm', <<"END");
package Dup2;
sub compute {
$shared_block}
sub other_dup2 { return 2 }
1;
END

	my $result = $check->run($dist);
	ok($result->data->{duplicates} > 0, 'cross-file block -> duplicate detected');
	isnt($result->status, 'pass', 'duplicate found -> not pass');
	ok(@{ $result->details }, 'details list populated');
	like($result->details->[0], qr/Dup[12]\.pm/, 'detail names affected files');
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
	is($result->check_id, 'duplicate_code', 'result carries correct check_id');
}

done_testing;
