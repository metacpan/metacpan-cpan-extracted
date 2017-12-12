#!/usr/bin/env perl
use strict;
use warnings;

use feature qw(say);

=head1 NAME

job-worker.pl - simple Redis job worker

=head1 SYNOPSIS

 sub.pl channel_name other_channel third_channel

=cut

use Net::Async::Redis;
use IO::Async::Loop;

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

my (@details) = @ARGV or die 'need at least one job to submit';

Future->wait_any(
    $redis->connect,
    $loop->timeout_future(after => $timeout),
)->get;

my $src_queue = 'jobs::pending';
STDOUT->autoflush(1);
print "Submitting job...\n";
my ($job) = $redis->lpush(
    $src_queue, @details
)->get;

print "Have job - $job\n";

