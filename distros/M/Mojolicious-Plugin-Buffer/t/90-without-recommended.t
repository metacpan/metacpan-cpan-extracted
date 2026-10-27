use strict;
use warnings;

use Test::More;
use File::Basename qw(basename dirname);
use File::Spec ();
use File::Temp ();

$| = 1;

# The optional modules named in Makefile.PL.  Hiding them in the child
# processes is what makes the fallback paths, particularly the one without
# HTML::Packer, real rather than simulated.  The level 2 fallback lives in
# 20-optimise.t, so there is no separate simulated no-Packer test file.
my @MODULES = qw(HTML::Packer CHI IO::Compress::Brotli Compress::Zstd);

my $have_test_without_module = eval { require Test::Without::Module; 1 };
plan skip_all => 'Test::Without::Module is required to run the suite without the recommended modules'
	unless $have_test_without_module;

my $module_list = join(',', @MODULES);
my $test_dir = dirname(File::Spec->rel2abs($0));
my $root = dirname($test_dir);
my @inc = map { "-I$_" } grep { -d } map { "$root/$_" } qw(lib blib/lib blib/arch);
my $self = File::Spec->rel2abs($0);
my @tests = sort grep { File::Spec->rel2abs($_) ne $self } glob("$test_dir/*.t");

sub run_captured {
	my ($log, @command) = @_;

	open(my $saved_stdout, '>&', \*STDOUT) or die "Cannot duplicate stdout: $!";
	open(my $saved_stderr, '>&', \*STDERR) or die "Cannot duplicate stderr: $!";
	open(STDOUT, '>&', $log) or die "Cannot redirect stdout: $!";
	open(STDERR, '>&', $log) or die "Cannot redirect stderr: $!";

	my $status = system(@command);

	open(STDOUT, '>&', $saved_stdout) or die "Cannot restore stdout: $!";
	open(STDERR, '>&', $saved_stderr) or die "Cannot restore stderr: $!";
	close($saved_stdout);
	close($saved_stderr);

	return $status;
}

subtest 'the recommended modules are hidden in a child process' => sub {
	for my $module (@MODULES) {
		my $code = "exit(eval { require $module; 1 } ? 2 : 0)";
		my $status = system(
			$^X, @inc,
			"-MTest::Without::Module=$module_list",
			'-e', $code,
		);
		is($status, 0, "$module is unavailable");
	}
};

subtest 'the suite passes without the recommended modules' => sub {
	plan skip_all => 'no test files found' unless @tests;
	ok(@tests > 1, 'found the distribution test files');

	my %included = map { basename($_) => 1 } @tests;
	ok($included{'05-lite.t'} && $included{'20-optimise.t'},
		'the HTML::Packer fallback cases are included');

	for my $test (@tests) {
		my $name = basename($test);
		subtest $name => sub {
			my ($log) = File::Temp::tempfile(UNLINK => 1);
			my $status = run_captured(
				$log,
				$^X, @inc,
				"-MTest::Without::Module=$module_list",
				$test,
			);

			seek($log, 0, 0);
			my $output = do { local $/; <$log> };
			close($log);

			is($status, 0, "$name passes without the recommended modules");
			diag("$name output:\n$output") if $status != 0;
		};
	}
};

done_testing();
