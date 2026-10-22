#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::More;

use Net::ADB;
use Test::Net::ADB::Server;

plan skip_all => 'fork is not available' if $^O eq 'MSWin32';

my $server = Test::Net::ADB::Server::start();
my $adb    = Net::ADB->new(port => $server->port, timeout => 1);

note("Fake ADB server started at port: ", $server->port);

is $adb->version, 41, 'version';

subtest 'FAIL' => sub {
    ok !eval { $adb->state(serial => 'offline'); 1 }, 'croaks';
    like $@, qr/^adb FAIL: device offline/, 'message from ADB server';
};

subtest 'shell_v2' => sub {
    my $res = eval { $adb->shell_v2(command => 'echo Hello') } or return fail("shell_v2: $@");
    is $res->stdout,    "Hello\n", 'stdout';
    is $res->stderr,    "",        'stderr';
    is $res->exit_code, 0,         'exit';
};

subtest 'devices' => sub {
    my @devices = $adb->devices;
    is scalar @devices, 3, 'list devices';

    is $devices[0]->{serial}, 'emulator-5554',     'device #1 - serial';
    is $devices[1]->{serial}, '192.168.0.10:5555', 'device #2 - serial';
    is $devices[2]->{serial}, 'EX0123456789',      'device #3 - serial';
};

done_testing();
