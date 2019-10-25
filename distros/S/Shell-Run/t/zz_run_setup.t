#!perl
use strict;
use warnings;

use Test2::V0;

my $output;

use Shell::Run
	sh => {as => 'shell'},
	echo => {exe => 't/cmd.sh', args => ['-n']};

shell 'echo hello', $output;
is $output, "hello\n", 'echo from sh';

echo 'hello', $output;
is $output, "hello", 'echo from cmd';

done_testing;
