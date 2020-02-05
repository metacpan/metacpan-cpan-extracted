use Test::Most;

use Pb;


foreach (qw< pwd >)
{
	# don't like `can_ok` because it doesn't allow a testname
	ok( main->can($_), "function $_ gets exported to calling package");
}


done_testing;
