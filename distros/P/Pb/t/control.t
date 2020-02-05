use Test::Most;

use File::Basename;
use lib dirname($0);
use Test::Pb::Bin;

use File::Temp			qw< tempdir >;


my $ctldir = tempdir( TMPDIR => 1, CLEANUP => 1 );

# sanity check: make sure empty control structure doesn't try to do anything wacky
my $test_cmd = <<'END';
	use Pb;

	command faux_control =>
		control_via {},
	flow
	{
	};

	Pb->go;
END
pb_basecmd(test_pb => $test_cmd);
check_output pb_run('faux_control'), "can supply empty control struct";


$test_cmd = <<'END';
	use Pb;

	my %dispatch =
	(
		hang		=>	sub {	sleep 300;							},
		pidfile		=>	sub {	say $FLOW->pidfile;					},
		testfail	=>	sub {	die("this should never happen");	},
		fail_verify	=>	sub {	verify { 0 } "can't continue";		},
		dirty_exit	=>	sub {	SH exit => 33;						},
		nothing		=>	sub {	;									},
	);

	command control =>
		arg action => one_of [sort keys %dispatch],
		control_via
		{
			# using a subdir of the tmpdir means we're also testing that dirs get created if necessary
			pidfile => "%%/run/%ME.pid",
			statusfile => "%%/%ME.lastrun",
			unless_clean_exit => 'bad thing: %ERR',
		},
	flow
	{
		$dispatch{ $FLOW->{action} }->();
	};

	Pb->go;
END
$test_cmd =~ s/%%/$ctldir/g;
my $cmd = pb_basecmd(test_pb => $test_cmd);


# STATUS FILE TESTS
my $statfile = "$ctldir/test_pb.lastrun";
sub _check_statfile
{
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $status = _slurp($statfile);
	my $timestamp = localtime =~ s/\d/\\d/gr;
	like $status, qr/last run: \Q$_[0]\E at $timestamp/,
			"status filename contains proper status ($_[1])";
}

# before we truly begin: certain errors should *not* trigger the creation of a statfile
{
	my $fail_msg;
	# "already running" tested below
	# `unless_clean_exit` tested below (search for "accumulate")
	# syntax failure (`unless_clean_exit` w/o `statusfile`) tested in t/errors.t

	# validation failure:
	$fail_msg = 'arg action fails validation [bmoogle must be one of: '
			. 'dirty_exit, fail_verify, hang, nothing, pidfile, testfail]';
	check_error pb_run(control => 'bmoogle'), "test_pb: $fail_msg", "sanity check: failed as expected";
	is _slurp($statfile), undef, "validation failure doesn't goto statfile";
	unlink $statfile;								# JIC the test failed, don't confound further tests

	# verify failure:
	$fail_msg = "pre-flow check failed [can't continue]";
	check_error pb_run(control => 'fail_verify'), "test_pb: $fail_msg", "sanity check: failed as expected";
	is _slurp($statfile), undef, "verify failure doesn't goto statfile";
	unlink $statfile;								# JIC the test failed, don't confound further tests
}

# first, when a statusfile is requested, a clean exit gets recorded
check_output pb_run(control => 'nothing'), "sanity check: nothing run completed successfully";
eq_or_diff [glob("$ctldir/*")], [ "$ctldir/run", $statfile ], "status filename expanded and file created";
_check_statfile( 'exited cleanly', "clean exit");

# next, a bad exit from a directive should be indicated thusly in the statfile
my $fail_msg = 'command [exit 33] exited non-zero [33]';
check_error pb_run(control => 'dirty_exit'), "test_pb: $fail_msg", "sanity check: failed as expected";
_check_statfile( $fail_msg, "directive failed");

# now that we got a bad exit, it shouldn't run any more
check_error pb_run(control => 'testfail'), "test_pb: bad thing: $fail_msg", "unless_clean_exit works";
_check_statfile( $fail_msg, "doesn't accumulate");

unlink $statfile;									# to avoid triggering the `unless_clean_exit` clause


# BASE PIDFILE TEST:
# background one that hangs, then make sure a second one exits immediately

if (my $pid = fork())
{
	# in parent; child should be running now
	# (but give it an extra second just to avoid race conditions)
	sleep 1;
	ok kill(0 => $pid), "sanity check: child appears to be running";

	check_error pb_run(control => 'testfail'), "test_pb: previous instance already running [$pid]",
			"setting pidfile blocks simultaneous runs"
					or diag "$ctldir/run/test_pb.pid: " . _slurp("$ctldir/run/test_pb.pid");
	is _slurp($statfile), undef, "already running failure doesn't goto statfile";

	ok kill(TERM => $pid), "sanity check: didn't leave child $pid hanging";
	wait;											# probably not necessary, but better safe than sorry
}
else
{
	die "cannot fork: $!" unless defined $pid;
	exec($cmd, control => 'hang');
}

# since we forcibly killed the child, we should see an indication of that in the statfile
_check_statfile( 'terminated due to signal TERM', "show signal death");
unlink $statfile;									# to avoid triggering the `unless_clean_exit` clause

# ANCILLARY PIDFILE TEST:
# now run again and it should work this time
# (while we're here, verify that the context var in the pidfile name got expanded)
eq_or_diff [glob("$ctldir/run/*")], [], "pidfile is cleared after run" or diag qx|ps f -t `tty`|;
check_output pb_run(control => 'pidfile'), "$ctldir/run/test_pb.pid", "pidfile is expanded with context vars";


done_testing;
