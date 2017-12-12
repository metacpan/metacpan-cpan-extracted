#!/usr/bin/env perl
use strict;
use warnings;

use feature qw(say);

=head1 NAME

job-worker.pl - simple Redis job worker where each job is fully contained in a list item

=head1 SYNOPSIS

 sub.pl channel_name other_channel third_channel

=cut

use Net::Async::Redis;
use IO::Async::Loop;
use Future::Utils qw(repeat);

use Getopt::Long;
use Pod::Usage;

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

my (@channels) = @ARGV or die 'need at least one channel to listen on';

Future->wait_any(
    $redis->connect,
    $loop->timeout_future(after => $timeout),
)->get;

my $src_queue = 'jobs::pending';
my $dst_queue = 'jobs::active';
STDOUT->autoflush(1);
print "Awaiting items...\n";
(repeat {
    $redis->brpoplpush(
        $src_queue => $dst_queue, 0
    )->then(sub {
        my ($id, @details) = @_;
        print "Have job - $id with details @details\n";
        warn for @details;
        $redis->lrem($dst_queue => 1, $id);
    })
} while => sub { 1 })->get;

