use Test::Most;

use File::Basename;
use lib dirname($0);
use Test::Pb::Bin;

use File::Temp;


# SYNTACTICAL FAILURES

# `command` declaration syntax with random garbage
pb_basecmd(bad_command => <<'END');
	use Pb;
	command explode =>
		random => 'crap',
	flow
	{
		say "should have died already";
	};
	Pb->go;
END
check_error pb_run('explode'), 1, "bad_command: unknown command attribute [random]",
		"`command` syntax rejects unknown elements";

# `command` name is illegal
pb_basecmd(bad_command => <<'END');
	use Pb;
	command '1llegal_name' =>
	flow
	{
		say "should have died already";
	};
	Pb->go;
END
check_error pb_run(), 1, "bad_command: illegal command name [1llegal_name]",
		"`command` syntax rejects invalid identifiers";

# `base_command` can't take args
pb_basecmd(bad_base_command => <<'END');
	use Pb;
	use Types::Standard -types;
	base_command
		arg foo => must_be Int,
	flow
	{
		say "should have died already";
	};
	Pb->go;
END
check_error pb_run(), 1, "bad_base_command: base commands cannot take arguments (try an option instead)",
		"`base_command` syntax rejects `arg`";

# unknown `arg` type
pb_basecmd(bad_type => <<'END');
	use Pb;
	command explode =>
		arg foo => must_be 'bogus-type',
	flow
	{
	};
	Pb->go;
END
check_error pb_run('explode'), 1, "bad_type: not a valid type [bogus-type]", "detects illegal type";

# no real proper constraint
pb_basecmd(bad_type => <<'END');
	use Pb;
	command explode =>
		arg foo => 'bogus-type',
	flow
	{
	};
	Pb->go;
END
check_error pb_run('explode'), 1, "bad_type: not a constraint [bogus-type]", "detects lack of constraint keyword";

# no proper control structure
pb_basecmd(bad_control => <<'END');
	use Pb;
	command explode =>
		control_via 'bmoogle',
	flow
	{
	};
	Pb->go;
END
check_error pb_run('explode'), 1, "bad_control: `control_via' requires hashref", "control_via checks arg";

# control structure with illegal keys
my $statfile = File::Temp->new( TMPDIR => 1 ); close $statfile;			# again, just like Path::Tiny::tempfile
# File::Temp will have created it, but we want to see if our command will create it, so start fresh.
unlink($statfile);
my $test_cmd = <<'END';
	use Pb;
	command explode =>
		control_via
		{
			bmoogle => 1,
			frobnobdicate => 1,
			statusfile => '%%',
		},
	flow
	{
	};
	Pb->go;
END
$test_cmd =~ s/%%/$statfile/;
pb_basecmd(bad_control => $test_cmd);
check_error pb_run('explode'), 1, "bad_control: unknown parameter(s) in control structure [bmoogle,frobnobdicate]",
		"control_via verifies parameters";
# also make sure that syntax errors are creating statusfiles
is _slurp($statfile), undef, "syntax error doesn't goto statfile";

# control structure with `unless_clean_exit` but no `statusfile`
pb_basecmd(bad_control => <<'END');
	use Pb;
	command explode =>
		control_via
		{
			unless_clean_exit => 'whatever',
		},
	flow
	{
	};
	Pb->go;
END
check_error pb_run('explode'), 1, "bad_control: cannot specify `unless_clean_exit' without `statusfile'",
		"control structure won't try to verify clean exit with no statusfile";


# OPERATIONAL FAILURES (arguments)

# `arg` failure to validate type
pb_basecmd(argfail => <<'END');
	use Pb;
	use Types::Standard -types;
	command explode =>
		arg foo => must_be Int,
	flow
	{
	};
	Pb->go;
END
check_error pb_run('explode', "x"), 1, "argfail: arg foo fails validation [x is not a Int]",
		"can validate arg type";

# `arg` failure to validate type as string
pb_basecmd(argfail => <<'END');
	use Pb;
	command explode =>
		arg foo => must_be 'Int',
	flow
	{
	};
	Pb->go;
END
check_error pb_run('explode', "x"), 1, "argfail: arg foo fails validation [x is not a Int]",
		"can validate arg typestring";

# `arg` failure to validate one of a given list
pb_basecmd(argfail => <<'END');
	use Pb;
	command explode =>
		arg foo => one_of [qw< a b c >],
	flow
	{
	};
	Pb->go;
END
check_error pb_run('explode', "x"), 1, "argfail: arg foo fails validation [x must be one of: a, b, c]",
		"can validate arg list";


# OPERATIONAL FAILURES (options)

# `opt` failure to validate type
pb_basecmd(optfail => <<'END');
	use Pb;
	use Types::Standard -types;
	command explode =>
		opt foo => must_be Int,
	flow
	{
	};
	Pb->go;
END
check_error pb_run('explode', '--foo', "x"), 1, "optfail: opt foo fails validation [x is not a Int]",
		"can validate opt type";

# `opt` failure to validate type as string
pb_basecmd(optfail => <<'END');
	use Pb;
	command explode =>
		opt foo => must_be 'Int',
	flow
	{
	};
	Pb->go;
END
check_error pb_run('explode', '--foo', "x"), 1, "optfail: opt foo fails validation [x is not a Int]",
		"can validate opt typestring";

# `opt` failure to validate one of a given list
pb_basecmd(optfail => <<'END');
	use Pb;
	command explode =>
		opt foo => one_of [qw< a b c >],
	flow
	{
	};
	Pb->go;
END
check_error pb_run('explode', '--foo', "x"), 1, "optfail: opt foo fails validation [x must be one of: a, b, c]",
		"can validate opt list";


# OPERATIONAL FAILURES (other)

# `verify` failure
pb_basecmd(verify => <<'END');
	use Pb;
	command explode => flow
	{
		verify { 0 } "AAAH! We're all gonna die!";
	};
	Pb->go;
END
check_error pb_run('explode'), 1, "verify: pre-flow check failed [AAAH! We're all gonna die!]",
		"`verify` calls `fatal` when condition fails";

# failure of an `SH` directive
pb_basecmd(sh_dirty_exit => <<'END');
	use Pb;
	command explode => flow
	{
		SH exit => 33;
		SH echo => "should never get here";
	};
	Pb->go;
END
check_error pb_run('explode'), 1, "sh_dirty_exit: command [exit 33] exited non-zero [33]",
		"`SH` calls `fatal` on dirty exit";

# failure of a `CODE` directive (no name, defined retval)
pb_basecmd(code_returns_false => <<'END');
	use Pb;
	command explode => flow
	{
		CODE sub { 0 };
		SH echo => "should never get here";
	};
	Pb->go;
END
check_error pb_run('explode'), 1, "code_returns_false: code block returned false value [0]",
		"`CODE` calls `fatal` on false return";

# failure of a `CODE` directive (name, undefined retval)
pb_basecmd(code_returns_false => <<'END');
	use Pb;
	command explode => flow
	{
		CODE 'failure block' => sub {};
		SH echo => "should never get here";
	};
	Pb->go;
END
check_error pb_run('explode'), 1, "code_returns_false: code block [failure block] returned false value [undef]",
		"`CODE` calls `fatal` (with block name) on false return";

# failure of a `CODE` directive (name, no retval because block `die`s)
pb_basecmd(code_dies => <<'END');
	use Pb;
	command explode => flow
	{
		CODE 'death block' => sub { die "dying here" };
		SH echo => "should never get here";
	};
	Pb->go;
END
check_error pb_run('explode'), 1, "code_dies: code block [death block] died [dying here]",
		"`CODE` calls `fatal` (with block name) on `die`";

# variable accessed but not passed in
pb_basecmd(varfail => <<'END');
	use Pb;
	command explode =>
		log_to => '/tmp/%bmoogle.log',
	flow
	{
	};
	Pb->go;
END
check_error pb_run('explode'), 1, "varfail: variable bmoogle used in expansion but never defined",
		"intelligent error message for failure to expand context var";


# LOW-LEVEL OPS FAILURES
# (these can be tricky to simulate, so we're calling private functions directly)

# failure of a file operation
pb_basecmd(bad_file_write => <<'END');
	use Pb;
	command explode => flow
	{
		$FLOW->_safe_file_rw("/cant/possibly/exist", "boom");
		Pb::fatal($FLOW->error) if $FLOW->error;
	};
	Pb->go;
END
my $extended_msg = qq[Can't open '/cant/possibly/exist' for writing: '$ERRNO{ENOENT}'];
check_error pb_run('explode'), "bad_file_write: file read/write failure [$extended_msg]",
		"catches failures in file ops";

# but failure to open a file for reading should *not* be a fatal error
pb_basecmd(bad_file_write => <<'END');
	use Pb;
	command no_explode => flow
	{
		my $content = $FLOW->_safe_file_rw("/cant/possibly/exist");
		say $content // $FLOW->error // '<<undef>>';
	};
	Pb->go;
END
check_output pb_run('no_explode'), "<<undef>>", "read on missing file just returns undefined";


done_testing;
