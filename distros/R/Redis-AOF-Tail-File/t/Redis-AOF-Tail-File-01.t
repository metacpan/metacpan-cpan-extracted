use strict;
use warnings;

use Test::More tests => 3;
use Redis::AOF::Tail::File;

my $test_aof_file = "t/material/test_appendonly.aof";

my $redis_aof = Redis::AOF::Tail::File->new(aof_filename => $test_aof_file);

my $pos;
my $cmd;

$cmd = $redis_aof->read_command();

is( $cmd, "SELECT 0", "Normal read");

($pos, $cmd) = $redis_aof->read_command();

is( $cmd, "set a 1", "Array read - cmd");
is( $pos, 38, "Array read - pos ");
