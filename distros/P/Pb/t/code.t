use Test::Most;

use File::Basename;
use lib dirname($0);
use Test::Pb::Bin;

use File::Temp;


pb_basecmd(code_test => <<'END');
	use Pb;

	command succeed => flow
	{
		CODE sub { say "inside code"; 1 };
		say "should get here";
	};

	command explode => flow
	{
		CODE sub { 0 };
		say "should never get here";
	};

	Pb->go;
END

# CODE should be fine on true
check_output pb_run('succeed'), "inside code", "should get here", "if CODE returns true, doesn't blow up";

# double check that CODE blows up on false
# (this is also checked in t/errors.t)
check_error pb_run('explode'), 1, "code_test: code block returned false value [0]",
		"`CODE` calls `fatal` on false return";


done_testing;
