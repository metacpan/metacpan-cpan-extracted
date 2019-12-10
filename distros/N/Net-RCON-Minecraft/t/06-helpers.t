#!perl
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Test::Exception;
use Test::More;
use Local::Helpers;
use Carp;

use Net::RCON::Minecraft;

# ID rollover
{
    my $rcon = Net::RCON::Minecraft->new;
    my $next_id = $rcon->_next_id;

    is $rcon->_next_id, ++$next_id, 'next_id increments';
    is $rcon->_next_id, ++$next_id, 'next_id increments twice';

    $rcon->_next_id(2**31-2);
    is $rcon->_next_id, 2**31-1, 'next_id hits limit';
    is $rcon->_next_id, 0, 'next_id rolls over at limit';
}

# Normal ID usage
{
    my $mock = rcon_mock();
    my $rcon = Net::RCON::Minecraft->new(password => 'secret');
    $rcon->connect;
    my $next_id = $rcon->_next_id;
    is $next_id, 2, 'Correct initial _next_id';
    $next_id = $rcon->_next_id;
    is $next_id, 3, 'Actual command will use 4';

    ok cmd(foo => 'bar');

    is $rcon->_next_id, 4,
        'next_id increments on command but not on nonce';
}

{
    my $mock = rcon_mock();
    my $rcon = Net::RCON::Minecraft->new(password => 'secret');
    disp_add($mock, '10:2:', => sub { [10, RESPONSE_VALUE, 'Empty'] });
    $rcon->connect;
    lives_ok { $rcon->_send_encode(2, 10, undef) } 'Empty payload';

}

# For simulating misbehaving servers. If you want a terminator, add it yourself.
sub quickpack { pack 'VV!VA*', @_ }

{
    my $mock = rcon_mock();
    my $rcon = Net::RCON::Minecraft->new(password => 'secret');
    $rcon->connect; # Need explicit call here to call private method
    throws_ok { $rcon->_read_decode } qr/^Server timeout/;

    # Timeouts used to cause a desync. This tests for that:
    is cmd(foo => 'bar'), 'bar', 'Command OK immediately after timeout';

}

{
    my $mock = rcon_mock();
    my $rcon = Net::RCON::Minecraft->new(password => 'secret');
    $rcon->connect; # Need explicit call here to call private method
    throws_ok { $rcon->_read_decode } qr/^Server timeout/;

    $mock->{read_buf} = quickpack(8, 1, AUTH_RESPONSE, '');
    throws_ok { $rcon->_read_decode } qr/^Packet too short/;

    $mock->{read_buf} = quickpack(16, 1, AUTH_RESPONSE, 'Short');
    throws_ok { $rcon->_read_decode } qr!^Server timeout. Got 13/16 bytes!;

    $mock->{read_buf} = quickpack(26, 1, AUTH_RESPONSE, 'Missing terminator');
    throws_ok { $rcon->_read_decode } qr/^Server response missing terminator/;
}

{
    my $mock = rcon_mock(sysread => sub { $! = 11; return });
    my $rcon = Net::RCON::Minecraft->new(password => 'secret');
    throws_ok { $rcon->connect } qr/^Socket read error:/, 'sysread error';
}

{
    my $mock = rcon_mock(send => sub { $! = 11; return });
    my $rcon = Net::RCON::Minecraft->new(password => 'secret');
    throws_ok { $rcon->_send_encode(2, 2, undef) }
        qr/^Socket write failed:/, '_send_encode error';
}

done_testing;
