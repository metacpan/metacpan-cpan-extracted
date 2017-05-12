use strict;
use warnings;

use Test::More;
use Test::Exception;

use PID::File;

my $file = '';

my $pid_file = PID::File->new;

$pid_file->create;

$file = $pid_file->file;

$pid_file->remove;

`echo $$ > $file`;

ok( ! $pid_file->create( sleep => 1, retries => 2 ), "could not create pid file after waiting" );

unlink $file;

ok( $pid_file->create( retries => 2, sleep => 4 ), "could create pid file after waiting now" );

$pid_file->remove;

done_testing();
