use Test::Most;

use File::Basename;
use lib dirname($0);
use Test::Pb::Bin;


my $test_cmd = <<'END';
	use Pb;
	use Types::Standard -types;

	command dumb => flow
	{
		SH echo => 'hello';
	};

	command show_debug => flow
	{
		verify { not $FLOW->{DEBUG} } 'debug starting from fresh "off" state';
		say "debug state is ", $FLOW->{DEBUG};
	};

	# these are just to verify that commands have a flexible syntax
	command flow_on_top => flow
	{
	},
	log_to '/nowhere';

	command flow_on_bottom =>
		arg foo => must_be Str,
		arg bar => must_be Int,
		log_to '/nowhere',
	flow
	{
	};

	# this is what you get if you don't specify a subcommand
	base_command
	flow
	{
		SH echo => join(',', grep { defined } 'goodbye', $FLOW->{name});
	};

	Pb->go;
END
my @commands = sort (qw< commands help info >, $test_cmd =~ /\bcommand\s+(\w+)\b/g);
pb_basecmd(test_pb => $test_cmd);

# Note that, if the following test succeeds, it also proves that all our syntactical elements are
# properly exported, including:
# 	*	modern Perl syntax such as `use strict` and `say`
# 	*	Pb keywords such as `command` and `flow`
# 	*	Pb directives such as `SH`
# 	*	Pb containers such as `$FLOW`
check_output pb_run('commands'), @commands, "command keyword generates an Osprey subcommand";

check_output pb_run('dumb'), "hello", "can execute stupid-simple single-SH-directive flow";
check_output pb_run('show_debug'), "debug state is 0", "can access flow context vars";
check_output pb_run(), "goodbye", "can run base command";

# `command` name is legal
pb_basecmd(good_command => <<'END');
	use Pb;
	command 'legal-name' =>
	flow
	{
		say "success";
	};
	Pb->go;
END
check_output pb_run('legal-name'), "success", "`command` identifiers allow dashes";


# Now check some things that we verify by the command _failing_.

# `use warnings` should be exported
pb_basecmd(test_warn => <<'END');
	use Pb;
	my $x = 1 + "a";
	exit 1;
END
check_error pb_run('help'), 1, qr/isn't numeric in addition/, "warnings are turned on";

# `use autodie` should be exported
pb_basecmd(test_autodie => <<'END');
	use Pb;
	open my $in, "/this/file/cannot/possibly/exist";
	exit 2;
END
check_error pb_run('help'), 2, qr/No such file or directory/, "autodie is turned on";

# `verify` demands its second argument (otherwise the error message wouldn't be very useful)
pb_basecmd(test_verify_syntax => <<'END');
	use Pb;
	command bad => flow
	{
		verify { 1 };
	};
	Pb->go;
END
check_error pb_run('bad'), 255, qr/not enough arguments for .*verify/i, "verify syntax demands both args";


done_testing;
