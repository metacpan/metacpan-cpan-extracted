#!/usr/bin/perl
# 011PiFlash_Command.t - tests for PiFlash::Command module

use strict;
use warnings;
use autodie;

use Test::More tests => 1 + 6*3 + 9*9;                      # last test to print
use PiFlash::State;
use PiFlash::Command;
use Data::Dumper;

# detect debug mode from environment
# run as "DEBUG=1 perl -Ilib t/011PiFlash_Command.t" to get debug output to STDERR
my $debug_mode = exists $ENV{DEBUG};

# expand parameter variable names in parameters
sub expand
{
	my $varhash = shift;
	my $varname = shift;
	my $prog = PiFlash::State::system("prog");
	my $varname_re = join('|', (keys %$varhash, keys %$prog));
	my $value = $varhash->{$varname} // "";
	if (ref $value eq "ARRAY") {
		for (my $i=0; $i<scalar @$value; $i++) {
			(defined $value->[$i]) or next;
			while ($value->[$i] =~ /\$($varname_re)/) {
				my $match = $1;
				my $subst = $varhash->{$match} // $prog->{$match};
				$value->[$i] =~ s/\$$match/$subst/g;
			}
		}
	} else {
		while ($value =~ /\$($varname_re)/) {
			my $match = $1;
			my $subst = $varhash->{$match} // $prog->{$match};
			$value =~ s/\$$match/$subst/g;
		}
	}
	return $value;
}

# test PiFlash::Command::prog()
sub test_prog
{
	my $params = shift; # hash structure of test parameters
	my $prog = PiFlash::State::system("prog");
	my $progname = expand($params, "progname");
	my ($progpath, $exception);

	# set test-fixture data in environment if provided
	my %saved_env;
	my $need_restore_env = 0;
	if ((exists $params->{env}) and (ref $params->{env} eq "HASH")) {
		foreach my $key (keys %{$params->{env}}) {
			if (exists $ENV{$key}) {
				$saved_env{$key} = $ENV{$key};
			}
			$ENV{$key} = $params->{env}{$key};
		}
		$need_restore_env = 1;
	}

	# run prog function
	$debug_mode and warn "prog test for $progname";
	eval { $progpath = PiFlash::Command::prog($progname) };
	$exception = $@;

	# test and report results
	my $test_set = "path ".$params->{test_set_suffix};
	if ($debug_mode) {
		if (exists $prog->{$progname}) {
			warn "comparing ".$prog->{$progname}." eq $progpath";
		} else {
			warn "$progname cache missing\n".Dumper($prog);
		}
	}
	if (!exists $params->{expected_exception}) {
		is($prog->{$progname}, $progpath, "$test_set: path in cache: $progname -> $progpath");
		ok(-e $progpath, "$test_set: path points to executable program");
		is($exception, '', "$test_set: no exceptions");
	} else {
		ok(!exists $prog->{$progname}, "$test_set: path not in cache as expected after exception");
		is($progpath, undef, "$test_set: path undefined after expected exception");
		my $expected_exception = expand($params, "expected_exception");
		like($exception, qr/$expected_exception/, "$test_set: expected exception");
	}

	# restore environment and remove test-fixture data from it
	if ($need_restore_env) {
		foreach my $key (keys %{$params->{env}}) {
			if (exists $ENV{$key}) {
				$ENV{$key} = $saved_env{$key};
			} else {
				delete $ENV{$key};
			}
		}
	}
}

# function to check log results in last command in log
sub check_cmd_log
{
	my $key = shift;
	my $expected_value = shift;
	my $params = shift;

	# fetch the log value for comparison
	my $log = PiFlash::State::log("cmd");
	my $log_entry = $log->[(scalar @$log)-1];
	my $log_value = $log_entry->{$key};

	# if it's an array, loop through to compare elements
	if (ref $expected_value eq "ARRAY") {
		if (ref $log_value ne "ARRAY") {
			# mismatch if both are not array refs
			$debug_mode and warn "mismatch ref type: log value not ARRAY";
			return 0;
		}
		if ($log_value->[(scalar @$log_value)-1] eq "") {
			# eliminate blank last line for comparison due to appended newline
			pop @$log_value;
		}
		if ((scalar @$expected_value) != (scalar @$log_value)) {
			# mismatch if result arrays are different numbers of lines
			$debug_mode and warn "mismatch array length ".(scalar @$expected_value)." != ".(scalar @$log_value);
			return 0;
		}
		my $i;
		for ($i=0; $i<scalar @$expected_value; $i++) {
			if ($expected_value->[$i] ne $log_value->[$i]) {
				# mismatch if any lines aren't equal
				$debug_mode and warn "mismatch line: $expected_value->[$i] ne $log_value->[$i]";
				return 0;
			}
		}
		return 1; # if we got here, it's a match
	}

	# if both values are undefined, that's a special case match because eq operator doesn't like them
	if ((!defined $expected_value) and (!defined $log_value)) {
		return 1;
	}

	# with previous case tested, they are not both undefined; so undef in either is a mismatch
	if ((!defined $expected_value) or (!defined $log_value)) {
		$debug_mode and warn "mismatch on one undef";
		return 0;
	}

	# otherwise compare values
	chomp $log_value;
	if ((exists $params->{regex}) and $params->{regex}) {
		return $expected_value =~ qr/$log_value/;
	}
	return $expected_value eq $log_value;
}

# test PiFlash::Command::fork_exec()
# function to run a set of tests on a fork_exec command
sub test_fork_exec
{
	my $params = shift; # hash structure of test parameters

	my ($out, $err, $exception);
	my $cmdname = expand($params, "cmdname");
	my $cmdline = expand($params, "cmdline");

	# run command
	$debug_mode and warn "running '$cmdname' as: ".join(" ", @$cmdline);
	eval { ($out, $err) = PiFlash::Command::fork_exec(($params->{input} // ()), $cmdname, @$cmdline) };
	$exception = $@;

	# tweak captured data for comparison
	chomp $out if defined $out;
	chomp $err if defined $err;

	# test and report results
	my $test_set = "fork_exec ".$params->{test_set_suffix};
	ok(check_cmd_log("cmdname", $cmdname), "$test_set: command name logged: $cmdname");
	ok(check_cmd_log("cmdline", $cmdline), "$test_set: command line logged: ".join(" ", @$cmdline));
	if (exists $params->{expected_exception}) {
		my $expected_exception = expand($params, "expected_exception");
		like($exception, qr/$expected_exception/, "$test_set: expected exception");
	} else {
		is($exception, '', "$test_set: no exceptions");
	}
	if (exists $params->{expected_signal}) {
		my $expected_signal = expand($params, "expected_signal");
		ok(check_cmd_log("signal", $expected_signal, {regex => 1}), "$test_set: $expected_signal");
	} else {
		ok(check_cmd_log("signal", undef), "$test_set: no signals");
	}
	ok(check_cmd_log("returncode", $params->{returncode}), "$test_set: returncode is $params->{returncode}");
	is($out, $params->{expected_out}, "$test_set: output capture match");
	ok(check_cmd_log("out", $params->{expected_out}), "$test_set: output log match");
	is($err, $params->{expected_err}, "$test_set: error capture match");
	ok(check_cmd_log("err", $params->{expected_err}), "$test_set: error log match");
}

# initialize program state storage
my @top_level_params = ("system", "input", "output", "cli_opt", "log");
PiFlash::State->init(@top_level_params);
PiFlash::State::cli_opt("verbose", 1);

# strings used for tests
my $test_string = "Ad astra per alas porci"; # test string: random text intended to look different from normal output

# test forking a simple process that returns a true value using fork_child()
{
	my $pid = PiFlash::Command::fork_child(sub {
		# in child process
		return 0; # 0 = success on exit of a program; test is successful if received by parent process
	});
	waitpid( $pid, 0 );
	my $returncode = $? >> 8;
	is($returncode, 0, "simple fork test");
}

# test PiFlash::Command::prog() and check for existence of prerequisite programs for following tests
my @prog_tests = (
	{ progname => "cat" },
	{ progname => "echo" },
	{ progname => "sh" },
	{ progname => "kill" },
	{
		progname => "xyzzy-notfound",
		expected_exception => "unknown secure location for \$progname",
	},
	{
		env => {
			XYZZY_NOTFOUND_PROG => "/usr/bin/true",
		},
		progname => "xyzzy-notfound",
	},
);

# run fork_exec() tests
PiFlash::Command::prog(); # init cache
{
	my $count = 0;
	foreach my $prog_test (@prog_tests) {
		$count++;
		$prog_test->{test_set_suffix} = $count;
		test_prog($prog_test);
	}
}

# use prog cache from previous tests to check for existence of prerequisite programs for following tests
my $prog = PiFlash::State::system("prog");
my @prog_names = qw(cat echo sh kill);
my @missing;
foreach my $progname (@prog_names) {
	if (!exists $prog->{$progname}) {
		push @missing, $progname;
	}
}
if (@missing) {
	BAIL_OUT("missing command required for tests: ".join(" ", @missing));
}

# data for fork_exec() test sets
my @fork_exec_tests = (
	# test capturing output of a fixed string from a program with fork_exec()
	# runs command: echo "$test_string"
	{
		cmdname => "echo string to stdout",
		cmdline => [q{$echo}, $test_string],
		returncode => 0,
		expected_out => $test_string,
		expected_err => undef,
	},

	# test sending input and receiving the same string back as output from a program with fork_exec()
	# runs command: cat
	# input piped to the program: $test_string
	{
		input => [ $test_string ],
		cmdname => "cat input to output",
		cmdline => [q{$cat}],
		returncode => 0,
		expected_out => $test_string,
		expected_err => undef,
	},

	# test capturing an error output
	{
		cmdname => "echo string to stderr",
		cmdline => [q{$sh}, "-c", qq{\$echo $test_string >&2}],
		returncode => 0,
		expected_out => undef,
		expected_err => $test_string,
	},

	# test capturing an error 1 result
	# exception expected during this test
	{
		cmdname => "return errorcode \$returncode",
		cmdline => [q{$sh}, "-c", q{exit $returncode}],
		returncode => 1,
		expected_out => undef,
		expected_err => undef,
		expected_exception => "\$cmdname command exited with value \$returncode",
	},

	# test capturing an error 2 result
	# exception expected during this test
	{
		cmdname => "return errorcode \$returncode",
		cmdline => [q{$sh}, "-c", q{exit $returncode}],
		returncode => 2,
		expected_out => undef,
		expected_err => undef,
		expected_exception => "\$cmdname command exited with value \$returncode",
	},

	# test receiving signal 1 SIGHUP
	{
		cmdname => "signal \$signal SIGHUP",
		cmdline => [q{$sh}, "-c", q{$kill -$signal $$}],
		signal => 1,
		returncode => 0,
		expected_out => undef,
		expected_err => undef,
		expected_exception => "\$cmdname command died with signal \$signal,",
		expected_signal => "signal \$signal",
	},

	# test receiving signal 2 SIGINT
	{
		cmdname => "signal \$signal SIGINT",
		cmdline => [q{$sh}, "-c", q{$kill -$signal $$}],
		signal => 2,
		returncode => 0,
		expected_out => undef,
		expected_err => undef,
		expected_exception => "\$cmdname command died with signal \$signal,",
		expected_signal => "signal \$signal",
	},

	# test receiving signal 9 SIGKILL
	{
		cmdname => "signal \$signal SIGKILL",
		cmdline => [q{$sh}, "-c", q{$kill -$signal $$}],
		signal => 9,
		returncode => 0,
		expected_out => undef,
		expected_err => undef,
		expected_exception => "\$cmdname command died with signal \$signal,",
		expected_signal => "signal \$signal",
	},

	# test receiving signal 15 SIGTERM
	{
		cmdname => "signal \$signal SIGTERM",
		cmdline => [q{$sh}, "-c", q{$kill -$signal $$}],
		signal => 15,
		returncode => 0,
		expected_out => undef,
		expected_err => undef,
		expected_exception => "\$cmdname command died with signal \$signal,",
		expected_signal => "signal \$signal",
	},
);

# run fork_exec() tests
{
	my $count = 0;
	foreach my $fe_test (@fork_exec_tests) {
		$count++;
		$fe_test->{test_set_suffix} = $count;
		test_fork_exec($fe_test);
	}
}

$debug_mode and warn PiFlash::State::odump($PiFlash::State::state,0);

1;
