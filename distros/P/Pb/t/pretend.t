use Test::Most;

use File::Basename;
use lib dirname($0);
use Test::Pb::Bin;

use File::Temp;


# This is pretty much how Path::Tiny::tempfile does it.
my $logfile = File::Temp->new( TMPDIR => 1 ); close $logfile;

my $test_cmd = <<'END';
	use Pb;

	command ptest =>
		log_to '%%',
	flow
	{
		verify { SH echo => "xx: verify line"; 1 } "can't fail";
		SH echo => "sh: first line";
		SH echo => "sh: second line";
		CODE "pretend test" => sub { say "cd: not printed under --pretend" };
	};

	command nested => flow
	{
		RUN 'ptest';
	};

	Pb->go;
END
$test_cmd =~ s/%%/$logfile/g;
pb_basecmd(test_pb => $test_cmd);

# first, run in standard mode
check_output pb_run('ptest'), "sanity check: output not going to term";
my $log = _slurp($logfile);
my @lines = ( "xx: verify line", "sh: first line", "sh: second line", "cd: not printed under --pretend", );
is $log, join('', map { "$_\n" } @lines), "sanity check: output going to log";

# have to remove the logfile or else output will just keep getting tacked on
unlink $logfile;

# now run in pretend mode
my %PRETEND = ( xx => sub {$_}, sh => sub { "would run: echo $_" }, cd => sub { "would run code block [pretend test]" }, );
my @pretend_lines = map { $PRETEND{ /^(..):/ && $1 }->() } @lines;
check_output pb_run('--pretend', 'ptest'), @pretend_lines, "basic pretend mode: good output";
$log = _slurp($logfile);
is $log, undef, "basic pretend mode: no execution";

# nested flows should inherit the context, including the runmode
check_output pb_run('--pretend', 'nested'), @pretend_lines, "pretend mode for nested: good output";


done_testing;
