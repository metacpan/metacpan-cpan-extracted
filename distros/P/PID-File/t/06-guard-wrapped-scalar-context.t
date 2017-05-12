use strict;
use warnings;

use Test::More;
use Test::Exception;

use PID::File;

my $pid_file = PID::File->new;
	
my $file;

{
	ok( $pid_file->create, "created pid file ok");

	my $guard;
	
	lives_ok { $guard = $pid_file->guard; } "created guard ok in scalar context";
	
	$file = $pid_file->file;
		
	ok( -e $pid_file->file, "pid file ('" . $pid_file->file . "') does exist");
}

ok( ! -e $file, "guard went out of scope and pid file ('" . $file . "') does not exist");



done_testing();
