use Test::Most;

use File::Basename;
use lib dirname($0);
use Test::Pb::Bin;


# N.B.: As with args, error messages for failing validation are checked in t/errors.t.


# an opt for a flow
pb_basecmd(flowvar => <<'END');
	use Pb;
	use Types::Standard -types;
	command show =>
		opt foo => must_be Int,
	flow
	{
		say "opt is $OPT{foo}";
	};
	Pb->go;
END
check_output pb_run('show', '--foo', 33), "opt is 33", "opt is available in container";

# handle multiple opts
pb_basecmd(multiple => <<'END');
	use Pb;
	use Types::Standard -types;
	command show =>
		opt foo => must_be Int,
		opt bar => must_be Str,
	flow
	{
		say "opts: $OPT{foo}$OPT{bar}";
	};
	Pb->go;
END
check_output pb_run('show', '--foo', 33, '--bar', 'x'), "opts: 33x", "flow can take multiple opts";

# simple boolean options
pb_basecmd(flowvar => <<'END');
	use Pb;
	use Types::Standard -types;
	command show =>
		opt foo => must_be Bool,
	flow
	{
		say "opt is ", $OPT{foo} ? 1 : 0;
	};
	Pb->go;
END
check_output pb_run('show', '--foo'), "opt is 1", "opt is boolean true when set";
check_output pb_run('show'         ), "opt is 0", "opt is boolean false when unset";

# default type is boolean
pb_basecmd(flowvar => <<'END');
	use Pb;
	command show =>
		opt foo =>,
	flow
	{
		say "opt is ", $OPT{foo} ? 1 : 0;
	};
	Pb->go;
END
check_output pb_run('show', '--foo'), "opt is 1", "opt w/o type is boolean true when set";
check_output pb_run('show'         ), "opt is 0", "opt w/o type is boolean false when unset";

# specify type by name
pb_basecmd(typename => <<'END');
	use Pb;
	command show =>
		opt foo => must_be 'Int',
	flow
	{
		say "opt is $OPT{foo}";
	};
	Pb->go;
END
check_output pb_run('show', '--foo', 33), "opt is 33", "opt type can be specified with string";

# shortcut for enums
pb_basecmd(typename => <<'END');
	use Pb;
	command show =>
		opt foo => one_of [qw< a b c >],
	flow
	{
		say "opt is $OPT{foo}";
	};
	Pb->go;
END
check_output pb_run('show', '--foo', 'b'), "opt is b", "opt type can be specified with list";

# base commands should be able to have opts too
pb_basecmd(flowvar => <<'END');
	use Pb;
	use Types::Standard -types;
	base_command
		opt foo => must_be Int,
	flow
	{
		say "opt is $OPT{foo}";
	};
	Pb->go;
END
check_output pb_run('--foo', 33), "opt is 33", "base_command can take an opt";


# OPTION PROPERTIES

# save opt as a context var
pb_basecmd(optvar => <<'END');
	use Pb;
	use Types::Standard -types;
	command show =>
		opt foox => must_be Int, also(-access_as_var),
	flow
	{
		say "opt is $FLOW->{foox}";
	};
	Pb->go;
END
check_output pb_run('show', '--foox', 33), "opt is 33", "opt value can be saved as a context var";


done_testing;
