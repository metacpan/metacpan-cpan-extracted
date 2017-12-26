#!/usr/bin/env perl
use strict;
use warnings;

use feature qw(say);

=head1 NAME

job-hash-submit.pl - simple Redis job worker with data stored in hashes

=head1 SYNOPSIS

 sub.pl channel_name other_channel third_channel

=cut

use Net::Async::Redis;
use IO::Async::Loop;
use Future::Utils qw(repeat);

use Getopt::Long;
use Pod::Usage;
use Math::Random::Secure qw(irand);

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
$loop->add(
    my $subscriber = Net::Async::Redis->new
);

sub uuid {
    return sprintf '%04x%04x-%04x-%04x-%02x%02x-%04x%04x%04x',
        (map { Math::Random::Secure::irand(2**16) } 1..3),
        (Math::Random::Secure::irand(2**16) & 0x0FFF) | 0x4000,
        (Math::Random::Secure::irand(2**8)) & 0xBF,
        (Math::Random::Secure::irand(2**8)),
        (map { Math::Random::Secure::irand(2**16) } 1..3)
}

Future->wait_any(
    Future->needs_all(
        $redis->connect,
        $subscriber->connect,
    ),
    $loop->timeout_future(after => $timeout),
)->get;

my $client_id = uuid();
$subscriber->subscribe('client::' . $client_id)
    ->then(sub {
        my ($sub) = @_;
        my $completion = $sub->events
            ->take(1)
            ->map('payload')
            ->say
            ->completed;
        my $queue = 'jobs::pending';
        Future->needs_all(
            $redis->multi(sub {
                my $tx = shift;
                my $id = uuid();
                $tx->hset('job::' . $id, reply => $client_id);
                $tx->lpush($queue, $id);
            }),
            $completion
        )
    })->get;

