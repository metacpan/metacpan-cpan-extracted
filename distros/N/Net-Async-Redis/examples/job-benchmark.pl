#!/usr/bin/env perl
use strict;
use warnings;

use feature qw(say);

=head1 NAME

job-benchmark.pl - test performance of some job queuing implementations

=head1 SYNOPSIS

 sub.pl channel_name other_channel third_channel

=cut

no indirect;

use Net::Async::Redis;
use IO::Async::Loop;
use Future::Utils qw(repeat fmap0);
use Future qw(call);

use Math::Random::Secure qw(irand);
use Getopt::Long;
use Pod::Usage;
use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'info';
use Test::More;

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

STDOUT->autoflush(1);
$SIG{PIPE} = 'IGNORE';

sub uuid {
    # UUIDv4 (random)
    return sprintf '%04x%04x-%04x-%04x-%02x%02x-%04x%04x%04x',
        (map { Math::Random::Secure::irand(2**16) } 1..3),
        (Math::Random::Secure::irand(2**16) & 0x0FFF) | 0x4000,
        (Math::Random::Secure::irand(2**8)) & 0xBF,
        (Math::Random::Secure::irand(2**8)),
        (map { Math::Random::Secure::irand(2**16) } 1..3)
}

my @child;
for my $idx (1..4) {
    if(my $pid = fork // die) {
        push @child, $pid;
    } else {
        # child
        my $client_id = uuid();
        local $log->{context}{client_id} = $client_id;
        undef $IO::Async::Loop::ONE_TRUE_LOOP;
        my $loop = IO::Async::Loop->new;

        # Our client has a single Redis connection, a UUID to
        # represent the client, and expects to see job announcements
        # on the pubsub channel client::$client_id. For each
        # announcement, the payload represents the job ID, and we get
        # the actual details from the job hash.
        $loop->add(
            my $client = Net::Async::Redis->new(
                client_name => 'client:' . $client_id,
            )
        );
        $loop->add(
            my $subscriber = Net::Async::Redis->new(
                client_name => 'subscriber:' . $client_id,
            )
        );
        $loop->add(
            my $submitter = Net::Async::Redis->new(
                client_name => 'submitter:' . $client_id,
            )
        );
        my $processed = 0;
        my $start = Time::HiRes::time;
        $loop->add(
            my $timer = IO::Async::Timer::Periodic->new(
                interval => 1,
                on_tick => sub {
                    my $runtime = Time::HiRes::time() - $start;
                    $log->infof('Client %s has %d processed, %.2f/sec', $client_id, $processed, $processed / ($runtime || 1));
                }
            )
        );
        $timer->start;

        $log->infof("Client awaiting Redis connections");
        Future->wait_all(
            $client->connect,
            $submitter->connect,
            $subscriber->connect
        )->get;
        $log->infof("Subscribing to notifications");
        my $count = 0;
        $subscriber->subscribe('client::' . $client_id)
            ->then(sub {
                my ($sub) = @_;
                # Every time someone tells us they finished a job, we pull back the details
                # and check the results
                my %pending_job;
                $sub->events
                    ->map('payload')
                    ->each(sub {
                        my ($id) = @_;
                        # $log->infof('Completion notification for %s', $id);
                        $client->hmget('job::' . $id, qw(left right result))->then(sub {
                            my ($x, $y, $result) = @{$_[0]};
                            my $expected = delete $pending_job{$id};
                            die 'invalid left' unless $x eq $expected->{left};
                            die 'invalid right' unless $y eq $expected->{right};
                            die 'invalid result' unless $result eq $x + $y;
                            ++$processed;
                            # $log->infof('Job result for %s was %s', $id, $result);
                            my $f = $client->del('job::' . $id);
                            $expected->{completion}->done($result);
                            $f
                        })->on_fail(sub { $log->errorf("A failure! %s", shift) })->retain;
                    });

                $log->infof("Redis connections established, starting client operations");
                my $queue = 'jobs::pending';
                (fmap0 {
                    my $f = $loop->new_future;
                    $submitter->multi(sub {
                        my $tx = shift;
                        my $id = uuid();
                        my $x = irand(10000);
                        my $y = irand(10000);
                        $pending_job{$id} = {
                            left => $x,
                            right => $y,
                            completion => $f,
                        };
                        $tx->hmset(
                            'job::' . $id,
                            reply => $client_id,
                            left  => $x,
                            right => $y
                        );
                        $tx->lpush($queue, $id);
                    })->then(sub { $f }),
                } generate => sub { return 1 if ++$count < 10000; return })
            })->get;
        $log->infof('Client completed');
        exit 0;
    }
}
$log->infof('Total of %d child workers', 0 + @child);

my $loop = IO::Async::Loop->new;

$loop->add(
    my $redis = Net::Async::Redis->new(
        client_name => 'server',
    )
);
$loop->add(
    my $handler = Net::Async::Redis->new(
        client_name => 'handler',
    )
);
$redis->configure(map { defined $config{$_} ? ($_ => $config{$_}) : () } keys %config);

Future->wait_any(
    Future->needs_all(
        $redis->connect,
        $handler->connect,
    ),
    ($timeout ? $loop->timeout_future(after => $timeout) : ()),
)->get;
my $processed = 0;
my $start = Time::HiRes::time;
$loop->add(
    my $timer = IO::Async::Timer::Periodic->new(
        interval => 1,
        on_tick => sub {
            my $runtime = Time::HiRes::time() - $start;
            $log->infof('Server %d processed, %.2f/sec', $processed, $processed / ($runtime || 1));
        }
    )
);
$timer->start;

sub worker {
    my (%details) = @_;
    return Future->fail('missing parameter `left`') unless defined $details{left};
    return Future->fail('missing parameter `right`') unless defined $details{right};
    return Future->done($details{left} + $details{right});
}

my $src_queue = 'jobs::pending';
my $dst_queue = 'jobs::active';
$redis->del($src_queue)->get;
$redis->del($dst_queue)->get;
(fmap0 {
    $redis->brpoplpush(
        $src_queue => $dst_queue, 0
    )->then(sub {
        my ($id, $queue, @details) = @_;
        $log->debugf('Received job %s from queue %s', $id, $queue);
        $redis->hgetall('job::' . $id)->then(sub {
            my ($items) = @_;
            my %details = @$items;
            worker(%details)->then(sub {
                my ($result) = @_;
                $handler->multi(sub {
                    my $tx = shift;
                    ++$processed;
                    $tx->hset('job::' . $id, result => $result);
                    # warn "sending to client::$details{reply}";
                    $tx->publish('client::' . $details{reply}, $id)->on_done(sub {
                        warn "no subscribers for $id => $details{reply} - @_" unless $_[0];
                    });
                    $tx->lrem($dst_queue => 1, $id);
                })
            })
        })
    })->on_fail(sub { warn "failed to process jobs - @_" })
} generate => sub { 1 }, concurrent => 1)->get;

exit 0;
