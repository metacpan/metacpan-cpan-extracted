use strict;
use warnings;

use Test::More tests => 9;
use Redis::AOF::Tail::File;

my $test_aof_file = "t/material/test_appendonly.aof";


for ( 36 .. 38)
{
	my $redis_aof = Redis::AOF::Tail::File->new(aof_filename => $test_aof_file, seekpos => $_ );

	my $pos;
	my $cmd;

	$cmd = $redis_aof->read_command();

	is( $cmd, "set a 2", "Normal read");

	($pos, $cmd) = $redis_aof->read_command();

	is( $cmd, "set b 100", "Array read - cmd");
	is( $pos, 80, "Array read - pos ");
}
