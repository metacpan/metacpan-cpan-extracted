#!/usr/bin/env perl
use strict;
use warnings;

use feature qw(say);

=head1 NAME

job-worker.pl - simple Redis job worker with data stored in hashes

=head1 SYNOPSIS

 sub.pl channel_name other_channel third_channel

=cut

use Net::Async::Redis;
use IO::Async::Loop;
use Future::Utils qw(repeat);

use Getopt::Long;
use Pod::Usage;
use Log::Any qw($log);

my %config;
GetOptions(
    'u|uri'       => \$config{uri},
    'p|port'      => \$config{port},
    'h|host'      => \$config{host},
    'a|auth'      => \$config{auth},
    'h|help'      => \my $help,
    't|timeout=i' => \my $timeout,
) or pod2usage(1);
pod2usage(2) if $help;

$SIG{PIPE} = 'IGNORE';
my $loop = IO::Async::Loop->new;

$loop->add(
    my $redis = Net::Async::Redis->new
);
$redis->configure(map { defined $config{$_} ? ($_ => $config{$_}) : () } keys %config);

Future->wait_any(
    $redis->connect,
    ($timeout ? $loop->timeout_future(after => $timeout) : ()),
)->get;

my $src_queue = 'jobs::pending';
my $dst_queue = 'jobs::active';
STDOUT->autoflush(1);
print "Awaiting items...\n";
(repeat {
    $redis->brpoplpush(
        $src_queue => $dst_queue, 0
    )->then(sub {
        my ($id, $queue, @details) = @_;
        $log->debugf('Received job %s from queue %s', $id, $queue);
        $redis->hgetall('job::' . $id)->then(sub {
            my ($items) = @_;
            warn "Have - $_\n" for @$items;
            my %details = @$items;
            $redis->multi(sub {
                my $tx = shift;
                $tx->publish('client::' . $details{reply}, 'done');
                $tx->lrem($dst_queue => 1, $id);
                $tx->del('job::' . $id);
            })
        })
    })
} while => sub { 1 })->get;

