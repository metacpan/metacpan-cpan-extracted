#!/usr/bin/env perl
use strict;
use warnings;

use feature qw(say);

use Net::Async::Redis;
use IO::Async::Loop;

use Getopt::Long;

GetOptions(
    'p|port' => \my $port,
    'h|host' => \my $host,
    'a|auth' => \my $auth,
    'h|help' => \my $help,
    't|timeout=i' => \my $timeout,
) or pod2usage(1);
pod2usage(2) if $help;

# Defaults
$timeout //= 30;
$host //= 'localhost';
$port //= 6379;

$SIG{PIPE} = 'IGNORE';
my $loop = IO::Async::Loop->new;

$loop->add(
    my $redis = Net::Async::Redis->new
);

Future->wait_any(
    $redis->connect
        ->then(sub {
            $redis->multi(sub {
                my $tx = shift;
                $tx->incr('test::some_key')->on_done(sub {
                    print "Incr - @_\n";
                });
                $tx->set('test::other_key' => 'key value')->on_done(sub {
                    print "Set - @_\n";
                });
                $tx->del('test::deleted_key')->on_done(sub {
                    print "Del - @_\n";
                });
            })
        })->on_done(sub {
            say $_ // '<undef>' for @_;
        }),
    $loop->timeout_future(after => $timeout),
)->get;

