use Test::Most;
use Debuggit DEBUG => 1;

use File::Basename;
use lib dirname($0);
use Test::Pb::Bin;


pb_basecmd(test_pb => <<'END');
	use Pb;											# this is basically the simplest Pb command you can write
	Pb->go;
END

check_output pb_run(), "base command functions (no args)";
check_output pb_run('commands'), qw< commands help info >, "default commands are in place";

check_error  pb_run(qw< info bmoogle >), 'test_pb: no such setting [bmoogle]', "info can handle errors";
check_output pb_run(qw< info ME >), 'test_pb', "basename set properly";
check_output pb_run(qw< info DEBUG >), 0, "DEBUG starts at zero";
check_output pb_run(qw< DEBUG=2 info DEBUG >), 2, "DEBUG set properly";


done_testing;
