use strict;
use warnings;

use Test::More tests => 1;
use Redis::AOF::Tail::File;

my $test_aof_file = "t/material/test_appendonly.aof";

my $redis_aof = Redis::AOF::Tail::File->new(aof_filename => $test_aof_file, seekpos => 39 );

my $pos;
my $cmd;

$cmd = $redis_aof->read_command();

is( $cmd, "set b 100", "Normal read");
