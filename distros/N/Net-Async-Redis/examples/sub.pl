#!/usr/bin/env perl
use strict;
use warnings;

use feature qw(say);

=head1 NAME

sub.pl - simple Redis subscription example

=head1 SYNOPSIS

 sub.pl channel_name other_channel third_channel

=cut

use Net::Async::Redis;
use IO::Async::Loop;

use Getopt::Long;
use Pod::Usage;

use Log::Any::Adapter qw(Stdout), log_level => 'trace';

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
    $redis->connect
        ->then(sub {
            $redis->subscribe(@channels)
                ->then(sub {
                    Future->needs_all(
                        map $_->events
                            ->sprintf_methods('%s => %s', qw(channel payload))
                            ->say
                            ->completed
                            ->on_done(sub {
                                say $_ // '<undef>' for @_;
                            }), @_
                    )
                })
        }),
    $loop->timeout_future(after => $timeout),
)->get;

