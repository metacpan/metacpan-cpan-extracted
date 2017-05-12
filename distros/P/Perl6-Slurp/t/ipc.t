use Test::More "no_plan";
BEGIN {use_ok(Perl6::Slurp)};

my $desc;
sub TEST { $desc = $_[0] };

my $data = "input data\n";

{
	my $TEST;
	{ local *STDERR;
	  open STDERR, '>', \my $err;
	  open $TEST, "echo $data|" or exit;
	}
	$test = <$TEST>;
	exit unless $test eq $data;
	ok 1, "test reads from pipe";
}

TEST "scalar slurp from 'system command|'";
$str = slurp 'echo input data|';
is $str, $data, $desc;

TEST "scalar slurp from '-|', 'system command'";
$str = slurp '-|', 'echo input data';
is $str, $data, $desc;

if ($^O ne 'MSWin32') {
    TEST "scalar slurp from '-|', 'system', 'command', 'etc'";
    $str = slurp '-|', qw(echo input data);
    is $str, $data, $desc;
}
