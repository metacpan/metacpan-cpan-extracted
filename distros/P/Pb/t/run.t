use Test::Most;

use File::Basename;
use lib dirname($0);
use Test::Pb::Bin;


my $test_cmd = <<'END';
	use Pb;
	use Types::Standard -types;

	command foo => flow
	{
		say 'foo';
	};

	command bar => flow
	{
		say 'bar';
	};

	command echo =>
		arg thing => must_be Str,
	flow
	{
		say $FLOW->{thing};
	};

	command nested =>
		arg flow => must_be Str,
	flow
	{
		RUN $FLOW->{flow};
	};

	command do_all => flow
	{
		RUN 'foo';
		RUN 'bar';
		RUN echo => 'something';
		RUN nested => 'foo';
	};

	Pb->go;
END
my @commands = sort (qw< commands help info >, $test_cmd =~ /\bcommand\s+(\w+)\b/g);
pb_basecmd(test_pb => $test_cmd);

# Testing all in one go:
# 	*	you can `RUN` a thing
# 	*	you can `RUN` multiple things
# 	*	you can `RUN` things with args
# 	*	you can `RUN` things that `RUN` things
check_output pb_run('do_all'), qw< foo bar something foo >, "RUN directive can run sub-flows";


done_testing;
