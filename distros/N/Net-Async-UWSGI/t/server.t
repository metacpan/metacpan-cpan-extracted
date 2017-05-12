use strict;
use warnings;

use Test::More;
use Net::Async::UWSGI::Server;
use IO::Async::Loop;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);
my $loop = IO::Async::Loop->new;
my $path = "$dir/uwsgi.sock";
ok(!-S $path, 'start without socket');
$loop->add(
	my $srv = new_ok('Net::Async::UWSGI::Server', [
		path => $path,
		mode => '0622',
	])
);
ok(-S $path, 'socket created');
is((stat $path)[2] & 0777, 0622, 'mode is correct');

done_testing;

