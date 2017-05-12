#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Mojo::IOLoop;
use IO::Socket::INET;

plan skip_all => "Unable to open raw socket: $!"
  unless IO::Socket::INET->new(Type => SOCK_RAW);

plan tests => 5;

use_ok 'MojoX::Ping';

my $ping = new_ok 'MojoX::Ping' => [timeout => 1];

my $result;

$ping->ping(
    '127.0.0.1',
    2,
    sub {
        my ($ping, $lres) = @_;

        $result = $lres;

        $ping->ioloop->stop;
    }
);

$ping->ioloop->start;

is_deeply $result, [['OK', $result->[0][1]], ['OK', $result->[1][1]]],
  'ping 127.0.0.1';

# Check two concurrent ping
my @res;
$ping->ping('127.0.0.1', 4, \&ping_cb);
$ping->ping('127.0.0.1', 4, \&ping_cb);
$ping->ioloop->start;
is $res[0][0][0], 'OK', 'first concurrent ping ok';
is $res[1][0][0], 'OK', 'second concurrent ping ok';

sub ping_cb {
    my ($ping, $res) = @_;
    push @res, $res;
    $ping->ioloop->stop if @res >= 2;
}
