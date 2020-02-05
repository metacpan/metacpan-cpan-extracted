use Test::Most;

use File::Basename;
use lib dirname($0);
use Test::Pb::Bin;


# N.B.: Error messages for failing argument validation are checked in t/errors.t.


# use an arg inside a flow
pb_basecmd(flowvar => <<'END');
	use Pb;
	use Types::Standard -types;
	command show =>
		arg foo => must_be Int,
	flow
	{
		say "arg is $FLOW->{foo}";
	};
	Pb->go;
END
check_output pb_run('show', 33), "arg is 33", "arg is available in context container";

# handle multiple args
pb_basecmd(multiple => <<'END');
	use Pb;
	use Types::Standard -types;
	command show =>
		arg foo => must_be Int,
		arg bar => must_be Str,
	flow
	{
		say "args: $FLOW->{foo}$FLOW->{bar}";
	};
	Pb->go;
END
check_output pb_run('show', 33, 'x'), "args: 33x", "flow can take multiple args";

# specify type by name
pb_basecmd(typename => <<'END');
	use Pb;
	command show =>
		arg foo => must_be 'Int',
	flow
	{
		say "arg is $FLOW->{foo}";
	};
	Pb->go;
END
check_output pb_run('show', 33), "arg is 33", "arg type can be specified with string";

# shortcut for enums
pb_basecmd(typename => <<'END');
	use Pb;
	command show =>
		arg foo => one_of [qw< a b c >],
	flow
	{
		say "arg is $FLOW->{foo}";
	};
	Pb->go;
END
check_output pb_run('show', 'b'), "arg is b", "arg type can be specified with list";


done_testing;
