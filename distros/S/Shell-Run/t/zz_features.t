#!perl
use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Compare qw(is T F array item end FDNE);

use Shell::Run 'bash';

my $output;
my $rc;

# no input
$rc = bash 'echo hello', $output;
is $output, "hello\n", 'capture output';
is $rc, T(), 'retcode ok';

# copy input to output
my $input = <<EOF;
first line
second line
third line
EOF
$rc = bash 'cat', $output, $input;
is $output, $input, 'pipe input';
is $rc, T(), 'retcode ok';

# cmd fails
$rc = bash 'false', $output;
is $rc, F(), 'retcode fail';

# logical check
my $fail;
bash 'false' or $fail = 1;
is $fail, 1, 'fail check';

# provide env var
$rc = bash 'echo $foo', $output, undef, foo => 'var from env';
is $output, "var from env\n", 'var from env';
is $rc, T(), 'retcode ok';

# special bash feature
$rc = bash 'cat <(echo -n "$foo")', $output, undef, foo => $input;
is $output, $input, 'special bash feature';
is $rc, T(), 'retcode ok';

# partial input processing
my $block = 'a' x 262144;
my $warn;
{
	local $SIG{__WARN__} = sub {$warn = $_[0]};
	eval {
		$rc = bash 'dd bs=64 count=8 2>/dev/null', $output, $block;
	};
	# next test fails if command exits before warning is issued
	todo "warning depends on timing" => sub {
		like $warn, qr/^write to cmd failed at/, 'warning issued';
	};

	is length($output), 512, 'partial input processing';
	is $rc, T(), 'retcode ok';
}

my $cc;

# capture completion code on failure
($cc, $rc) = bash 'exit 2';
is $rc, F(), 'cmd failed, list result';
is $cc, 2, 'completion code 2';

# capture completion code on success
($cc, $rc) = bash 'exit';
is $rc, T(), 'cmd succeeded, list result';
is $cc, 0, 'completion code zero';

done_testing;
