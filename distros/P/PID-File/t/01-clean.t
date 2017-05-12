use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin qw($Bin);
use File::Basename qw(fileparse);

use PID::File;

my $pid_file;

lives_ok { $pid_file = PID::File->new; } "instantiated pid file ok";

ok( ! $pid_file->running, "pid file is not running" );

lives_ok { $pid_file->create; } "created pid file ok";

ok( $pid_file->pid == $$, "pid is me" );

my $expected_filename = '';
{
	my @filename = fileparse( $0 );
	$expected_filename = $Bin . '/';
	$expected_filename .= shift @filename;
	$expected_filename .= '.pid';
}
	
ok( $pid_file->file eq $expected_filename, "pid file is '" . $expected_filename . "' as expected");
	
ok( -e $pid_file->file, "pid file ('" . $pid_file->file . "') does exist");

ok( $pid_file->running, "pid file is running (me)" );

lives_ok { $pid_file->remove; } "removed pid file ok";

ok ( ! defined $pid_file->pid, "pid is now undef");

ok( ! -e $pid_file->file, "pid file ('" . $pid_file->file . "') does not exist");

ok( ! $pid_file->running, "pid file is not running" );

done_testing();
