use Test::Most;

use File::Basename;
use lib dirname($0);
use Test::Pb::Bin;

use File::Temp			qw< tempdir >;


my $logdir = tempdir( TMPDIR => 1, CLEANUP => 1 );

my $test_cmd = <<'END';
	use Pb;
	use Time::Piece;

	command get_logfile2 =>
		log_to '%%/some/other/file',
	flow
	{
		say $FLOW->{LOGFILE};
	};

	command get_logfile1 =>
		log_to '%%/some/file',
	flow
	{
		say $FLOW->{LOGFILE};

		# verify that our logfile's dir gets created
		-d '%%/some' or die("failed to create parent dir for our logfile [%%/some]");
		# and that the logfile dir of other commands _don't_
		not -d '%%/some/other' or die("created parent log dir for the wrong command");

		# now do something that will actually create a logfile
		SH echo => "this is a test";
		CODE sub { say "a second line" };
		CODE sub { say STDERR "third line" };
		# get a little tricky
		SH $^X => -le => 'print STDERR "fourth line"';
		# this is probably the trickiest one of all ...
		SH echo => "fifth line", '>&2';
	};

	command logfile_var =>
		log_to '%%/log-%ME',
	flow
	{
		say $FLOW->{LOGFILE};
	};

	command timestamped =>
		log_to '%%/log-%TIME',
	flow
	{
		die("not getting timestamp in logfile name! [$FLOW->{LOGFILE}]")
				unless $FLOW->{LOGFILE} eq '%%/log-' . localtime($^T)->strftime("%Y%m%d%H%M%S");
		say "works";
	};

	command datestamped =>
		log_to '%%/log-%DATE',
	flow
	{
		die("not getting date in logfile name! [$FLOW->{LOGFILE}]")
				unless $FLOW->{LOGFILE} eq '%%/log-' . localtime($^T)->strftime("%Y%m%d");
		say "works";
	};

	Pb->go;
END
$test_cmd =~ s/%%/$logdir/g;
pb_basecmd(test_pb => $test_cmd);

check_output pb_run('get_logfile1'), "$logdir/some/file", "logfile name saved in context container";
check_output pb_run('get_logfile2'), "$logdir/some/other/file", "logfile name individuates by command";

# verify that we got our logfile output
my $log = _slurp("$logdir/some/file");
my @lines = ( "this is a test", "a second line", "third line", "fourth line", "fifth line", );
is $log, join('', map { "$_\n" } @lines), "base logging works (SH directive)";

# can we do variable substitutions in logfile names?
check_output pb_run('logfile_var'), "$logdir/log-test_pb", "can use a flow context var in logfile name";
# how about timestamps and datestamps?
# (for these, we're just making sure they don't die; the real logic of the tests is in the flow definitions above)
check_output pb_run('timestamped'), "works", "can use a timestamp in logfile name";
check_output pb_run('datestamped'), "works", "can use a date in logfile name";


done_testing;
