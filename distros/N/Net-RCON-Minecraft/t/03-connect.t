#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Test::Exception;
use Test::More;
use Test::Warnings ':all';
use Local::Helpers;
use Carp; # for mocked subs

use Net::RCON::Minecraft;

my $rcon = Net::RCON::Minecraft->new(error_mode => 'error');
dies_ok { $rcon->connect } 'Blank password rejected';

my $mock = rcon_mock(new => sub { $! = 111; return });
$rcon = Net::RCON::Minecraft->new(password => 'secret');
is ref($rcon), 'Net::RCON::Minecraft';
throws_ok { $rcon->connect }
    qr/Connection to localhost:25575 failed: /;

$rcon = Net::RCON::Minecraft->new(password => 'wrong');
$mock = rcon_mock();
disp_add($mock, '1:3:wrong'  => sub { [-1, 2, ''] });
throws_ok { $rcon->connect } qr/^\QRCON authentication failed\E/;

$mock = rcon_mock();
$rcon = Net::RCON::Minecraft->new(password => 'secret');
ok $rcon->connect, 'Connects';

$rcon = Net::RCON::Minecraft->new(password => 'fluffy');
disp_add($mock, '1:3:fluffy' => sub { [31, 2, ''] });
throws_ok { $rcon->connect } qr/\QExpected ID\E/, 'Server errors';

disp_add($mock, '1:3:fluffy' => sub { [ 1, 3, ''] });
throws_ok { $rcon->connect } qr/^\QExpected AUTH_RESPONSE\E/;

$rcon = Net::RCON::Minecraft->new(password => 'fluffy');
disp_add($mock, '1:3:fluffy' => sub { [ 1, 3, ''] });
throws_ok { $rcon->connect } qr/^\QExpected AUTH_RESPONSE\E/;

$rcon = Net::RCON::Minecraft->new(password => 'fluffy');
$mock = rcon_mock();
disp_add($mock, '1:3:fluffy' => sub { [ 1, 3, ''] });
throws_ok { $rcon->connect } qr/^\QExpected AUTH_RESPONSE\E/;

disp_add($mock, '1:3:fluffy' => sub { [1, 2, 'Not Blank'] });
throws_ok { $rcon->connect } qr/^\QNon-blank payload <Not Blank>\E/;

$rcon = Net::RCON::Minecraft->new(password => 'secret');
ok $rcon->connect,    'Connects';
ok $rcon->connect,    'Already connected';
ok $rcon->disconnect, 'Disconnects';
ok $rcon->disconnect, 'Disconnects twice ok';
ok !$rcon->connected, 'Disconnected';

$rcon = Net::RCON::Minecraft->new(password => 'secret');
ok $rcon->disconnect, 'Disconnect without connect ok';

$rcon = Net::RCON::Minecraft->new(password => 'secret');
ok !$rcon->connected, 'Not connected yet';
$rcon->connect;
ok  $rcon->connected, 'Now we are connected';
$rcon->disconnect;
ok !$rcon->connected, 'Disconnected again';

done_testing;
