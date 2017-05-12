#!/usr/bin/env perl
use strict;
use warnings;

use Net::Async::AMQP;
use IO::Async::Loop;
use IO::Async::Loop::Epoll;
use IO::Async::Timer::Periodic;
use Future::Utils qw(fmap0 repeat);
use feature qw(say);

use Getopt::Long;

my %args;
$args{localhost} = [];
GetOptions(
	"host|h=s"    => \$args{host},
	"user|u=s"    => \$args{user},
	"pass=s"      => \$args{pass},
	"port=i"      => \$args{port},
	"vhost|v=s"   => \$args{vhost},
	"parallel=i"  => \$args{parallel},
	"channels=i"  => \$args{channels},
	"localhost=s" => $args{localhost},
) or die("Error in command line arguments\n");

my $loop = IO::Async::Loop->new;
$loop->resolver->configure(
	min_workers => 2,
	max_workers => 2,
);

say "start";
my %stats;
my $total = 0;
my $start = $loop->time;
my $timer = IO::Async::Timer::Periodic->new(
	interval => 0.2,
	on_tick => sub {
		my $elapsed = $loop->time - $start;
		say join ', ', map { sprintf "%d (%f/s) %s", $stats{$_}, $stats{$_} / ($elapsed || 1), $_ } sort keys %stats;
	}
);
$timer->start;
$loop->add($timer);
my $true = (Net::AMQP->VERSION >= 0.06) ? Net::AMQP::Value->true : 1;
my %mq;
my @hosts = @{ delete($args{host}) || [qw(localhost)] };
my $parallel = delete $args{parallel} || 1;

$loop->add(my $mq = Net::Async::AMQP->new(
	heartbeat_interval => 0,
));
$mq->connect(
	%args,
	client_properties => {
		capabilities => {
			'consumer_cancel_notify' => $true,
			'connection.blocked'     => $true,
		},
	},
)->then(sub {
	my ($mq) = @_;
	$start = $loop->time;
	(fmap0 {
		$mq->open_channel->then(sub {
			shift->confirm_mode
		})->then(sub {
			my ($ch) = @_;
			(repeat {
				$ch->publish(
					exchange => '',
					routing_key => 'whatever',
					type => 'some_type',
				)->on_done(sub { ++$stats{sent} })
				 ->on_fail(sub { warn "oh noes: @_"; ++$stats{fail} })
			} while => sub { 1 })
		})
	} foreach => [1..$args{channels}], concurrent => $args{channels})
})->get;

