use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Exception;
use Test::More;

use Test::CPAN::Health::Check::MinPerl;
use Test::CPAN::Health::Distribution;

my $check = Test::CPAN::Health::Check::MinPerl->new;
isa_ok($check, 'Test::CPAN::Health::Check::MinPerl');
isa_ok($check, 'Test::CPAN::Health::Check');

is($check->id,       'min_perl',            'id');
is($check->name,     'Minimum Perl Version', 'name');
is($check->weight,   3,                      'weight');
is($check->category, 'packaging',            'category');

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub make_dist {
	my $tmp = tempdir(CLEANUP => 1);
	return ($tmp, Test::CPAN::Health::Distribution->new(path => $tmp));
}

sub write_file {
	my ($path, $content) = @_;
	open my $fh, '>', $path or die "Cannot write $path: $!";
	print {$fh} $content;
	close $fh;
}

# META.json with runtime prereq for perl 5.010.
my $META_WITH_PERL_PREREQ = <<'END';
{"abstract":"test","author":["Test Author"],"license":["perl_5"],"meta-spec":{"version":"2"},"name":"Test-Dist","version":"1.0.0","prereqs":{"runtime":{"requires":{"perl":"5.010","strict":"0"}}}}
END
chomp $META_WITH_PERL_PREREQ;

# META.json with no perl prereq in runtime.requires.
my $META_NO_PERL_PREREQ = <<'END';
{"abstract":"test","author":["Test Author"],"license":["perl_5"],"meta-spec":{"version":"2"},"name":"Test-Dist","version":"1.0.0","prereqs":{"runtime":{"requires":{"strict":"0"}}}}
END
chomp $META_NO_PERL_PREREQ;

my $HAS_PMV = eval { require Perl::MinimumVersion; 1 };

# ---------------------------------------------------------------------------
# No META file -> skip
# ---------------------------------------------------------------------------

{
	my (undef, $dist) = make_dist();
	my $result = $check->run($dist);

	is($result->status, 'skip', 'no META -> skip');
	like($result->summary, qr/No META/i, 'summary explains skip reason');
}

# ---------------------------------------------------------------------------
# META with no perl prereq declared -> fail, score 0
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'), $META_NO_PERL_PREREQ);

	my $result = $check->run($dist);
	is($result->status, 'fail', 'no perl prereq -> fail');
	is($result->score,  0,      'no perl prereq -> score 0');
	like($result->summary, qr/No minimum Perl/i, 'summary explains missing prereq');
}

# ---------------------------------------------------------------------------
# META with perl prereq, no source files -> pass (unverified)
# Score is 80 when Perl::MinimumVersion is available (no files to scan)
# or 80 when it is not available.  Either way: pass, score >= 80.
# ---------------------------------------------------------------------------

{
	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'), $META_WITH_PERL_PREREQ);

	my $result = $check->run($dist);
	is($result->status, 'pass', 'declared min perl, no source -> pass');
	is($result->score,  80,     'declared min perl, no source -> score 80');
	is($result->data->{declared}, '5.010', 'data carries declared version');
}

# ---------------------------------------------------------------------------
# Perl::MinimumVersion integration: declared ok vs. source (optional)
# ---------------------------------------------------------------------------

SKIP: {
	skip 'Perl::MinimumVersion not installed', 4 unless $HAS_PMV;

	# Write a .pm file that uses a feature available since 5.010 (say).
	# Perl::MinimumVersion should detect >= 5.010 from "use 5.010;".

	my ($tmp, $dist) = make_dist();
	write_file(File::Spec->catfile($tmp, 'META.json'), $META_WITH_PERL_PREREQ);
	my $lib = File::Spec->catdir($tmp, 'lib');
	make_path($lib);
	write_file(File::Spec->catfile($lib, 'Foo.pm'), "package Foo;\nuse 5.010;\n1;\n");

	my $result = $check->run($dist);
	ok(
		$result->status eq 'pass' || $result->status eq 'warn',
		'PMV integration: result is pass or warn',
	);
	ok(defined $result->data->{detected}, 'PMV integration: detected version recorded');

	# Write a .pm that needs a newer Perl than declared (5.020 feature: say with //=).
	# Use "use 5.020;" explicitly so PMV reliably detects the minimum.

	my ($tmp2, $dist2) = make_dist();
	write_file(File::Spec->catfile($tmp2, 'META.json'), $META_WITH_PERL_PREREQ);
	my $lib2 = File::Spec->catdir($tmp2, 'lib');
	make_path($lib2);
	write_file(File::Spec->catfile($lib2, 'Bar.pm'), "package Bar;\nuse 5.020;\n1;\n");

	my $result2 = $check->run($dist2);
	is($result2->status, 'warn', 'source requires > declared -> warn');
	is($result2->score,  40,     'underdeclared -> score 40');
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
	is($result->check_id, 'min_perl', 'result carries correct check_id');
}

done_testing;
