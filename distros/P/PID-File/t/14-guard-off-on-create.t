use strict;
use warnings;

use Test::More;
use Test::Exception;

use PID::File;

my $file;

{
	my $pid_file = PID::File->new;

	ok( $pid_file->create( guard => 0 ), "created pid file ok with guard");

	$file = $pid_file->file;

	ok( -e $pid_file->file, "pid file ('" . $pid_file->file . "') does exist");
}

ok( -e $file, "pid_file went out of scope and pid file ('" . $file . "') still exists");

unlink $file;

done_testing();
