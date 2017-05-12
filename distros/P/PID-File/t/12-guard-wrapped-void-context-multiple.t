use strict;
use warnings;

use Test::More;
use Test::Exception;

use PID::File;

my $file;

{
	my $pid_file = PID::File->new;
	
	ok( $pid_file->create, "created pid file ok");

	lives_ok { $pid_file->guard; } "created guard ok in void context";
	
	$file = $pid_file->file;
		
	ok( -e $pid_file->file, "pid file ('" . $pid_file->file . "') does exist");

	
	$pid_file->remove;
	
	ok( ! -e $file, "guard went out of scope and pid file ('" . $file . "') does not exist");

	open my $fh, ">", $file;
	print $fh "TEST";
	close $file;

	ok( -e $file, "pid file ('" . $file . "') manually put back");	
}

ok( -e $file, "pid file ('" . $file . "') still there even tho pid_file went out of scope");

unlink $file;

ok( ! -e $file, "pid file ('" . $file . "') safely removed");


done_testing();
