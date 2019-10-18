#!perl
use strict;
use warnings;

use Shell::Run;
use Test2::V0;
use Test2::Tools::Class;

my $output;
my $rc;

my $bash = Shell::Run->new(name => 'bash');
isa_ok($bash, ['Shell::Run'], 'got blessed object');

# no input
$rc = $bash->run('echo hello', $output);
is $output, "hello\n", 'capture output';
is $rc, T(), 'retcode ok';

# copy input to output
my $input = <<EOF;
first line
second line
third line
EOF
$rc = $bash->run('cat', $output, $input);
is $output, $input, 'pipe input';
is $rc, T(), 'retcode ok';

# cmd fails
$rc = $bash->run('false', $output);
is $rc, F(), 'retcode fail';

# provide env var
$rc = $bash->run('echo $foo', $output, undef, foo => 'var from env');
is $output, "var from env\n", 'var from env';
is $rc, T(), 'retcode ok';

# special bash feature
$rc = $bash->run('cat <(echo -n "$foo")', $output, undef, foo => $input);
is $output, $input, 'special bash feature';
is $rc, T(), 'retcode ok';

# partial input processing
my $block = 'a' x 262144;
my $warn;
{
	local $SIG{__WARN__} = sub {$warn = $_[0]};
	eval {
		$rc = $bash->run('dd bs=64 count=8 status=none', $output, $block);
	};
	# next test fails if command exits before warning is issued
	todo "warning depends on timing" => sub {
		like $warn, qr/^write to cmd failed at/, 'warning issued';
	};

	is length($output), 512, 'partial input processing';
	is $rc, T(), 'retcode ok';
}

# specify exe and args
my $echo = Shell::Run->new(exe => 't/cmd.sh', args => ['-n']);
$echo->run('hello', $output);
is $output, 'hello', 'specific interpreter';

done_testing;
