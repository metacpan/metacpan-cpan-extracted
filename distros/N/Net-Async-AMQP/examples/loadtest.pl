#!/usr/bin/env perl
use strict;
use warnings;
{
	package App::loadtest::Child;
	use parent qw(Process::Async::Child);

	sub configure_unknown {
		my ($self, %args) = @_;
		$self->{$_} = $args{$_} for keys %args;
	}

	sub target { shift->{target} }
	sub conntarget { shift->{conntarget} }

	sub stats { shift->{stats} }

	sub adjust_stat {
		my ($self, $k, $v) = @_;
		$self->{stats}{$k} += $v;
	}

	sub cmd_stats {
		my $self = shift;
		my ($k, $v) = split ' ', shift;
		my $current = $self->adjust_stat($k => $v);
		return unless $k eq 'success' and !$self->conntarget->is_ready;
		$self->conntarget->done if $current >= $self->target;
	}
}
{
	package App::loadtest::Worker;
	use parent qw(Process::Async::Worker);

	use Future::Utils qw(fmap0);

	sub configure_unknown {
		my ($self, %args) = @_;
		$self->{$_} = $args{$_} for keys %args;
	}

	sub queue_prefix { shift->{queue_prefix} }
	sub exchange_prefix { shift->{exchange_prefix} }

	sub hosts { @{shift->{hosts}} }

	sub on_command {
		my ($self, $cmd, @v) = @_;
		warn "Had command: $cmd\n";
	}

	sub run {
		my ($self, $loop) = @_;
		my $continue = 1;
		my @hosts = $self->hosts;
		my $true = (Net::AMQP->VERSION >= 0.06) ? Net::AMQP::Value->true : 1;
		my %mq;
		(fmap0 {
			$self->send_command(stats => active => 1);
			my $mq = Net::Async::AMQP->new(
				loop               => $loop,
				heartbeat_interval => 0,
			);
			my $k = "$mq";
			push @hosts, my $host = shift @hosts;
			$mq{$k} = Future->wait_any(
				$mq->connect(
					%{$self->{mq_args}},
					local_host => $host,
					client_properties => {
						capabilities => {
							'consumer_cancel_notify' => $true,
							'connection.blocked'     => $true,
						},
					},
				)->then(sub {
					my ($mq) = @_;
					$mq->open_channel
				})->then(sub {
					my ($ch) = @_;
					my ($exch_name, $qname) = (
						$self->exchange_prefix . '_some_exch',
						$self->queue_prefix . $k,
					);
					Future->needs_all(
						$ch->queue_declare(
							queue => $qname
						),
						$ch->exchange_declare(
							type => 'fanout',
							exchange => $exch_name,
							autodelete => 1,
						)
					)->then(sub {
						my ($q) = @_;
						$q->bind_exchange(
							exchange => $exch_name
						)
					})
				})->on_fail(sub {
					$self->send_command(stats => failed => 1);
					warn "Failure: @_\n"
				})->on_done(sub {
					$self->send_command(stats => success => 1);
				}),
				$loop->timeout_future(after => 30)
				 ->on_fail(sub {
					$self->send_command(stats => timeout => 1);
				})
			)->on_ready(sub {
				$self->send_command(stats => active => -1);
				$self->send_command(stats => total => 1);
			})
			 ->on_fail(sub { delete $mq{$k} })
			 ->else(sub { Future->wrap })
		} concurrent => $self->{parallel},
		  generate => sub { $continue })->get;
	}
}

use Getopt::Long;
use Net::Async::AMQP;
use IO::Async::Loop;
use IO::Async::Loop::Epoll;
use IO::Async::Timer::Periodic;
use Process::Async::Manager;

use feature qw(say);

my %args;
$args{localhost} = [];
GetOptions(
	"host|h=s"    => \$args{host},
	"user|u=s"    => \$args{user},
	"pass=s"      => \$args{pass},
	"port=i"      => \$args{port},
	"vhost|v=s"   => \$args{vhost},
	"queue_prefix|qp=s"   => \$args{queue_prefix},
	"exchange_prefix|ep=s"   => \$args{exchange_prefix},
	"parallel=i"  => \$args{parallel},
	"forks=i"     => \$args{forks},
	"target=i"    => \$args{target},
	"localhost=s" => $args{localhost},
) or die("Error in command line arguments\n");

my $loop = IO::Async::Loop->new;
$loop->resolver->configure(
	min_workers => 1,
	max_workers => 1,
);

my %stats;
$loop->add(IO::Async::Timer::Periodic->new(
	interval => 2,
	reschedule => 'skip',
	on_tick => sub {
		say join ', ', map { sprintf "%d %s", $stats{$_}, $_ } sort keys %stats;
	}
)->start);

say "Starting";
my @hosts = @{ delete($args{localhost}) || [qw(localhost)] };
my $parallel = delete $args{parallel} || 1;
my $forks = delete $args{forks} || 1;
my $target = delete $args{target} || 1_000_000;

my $conntarget = $loop->new_future;
$loop->add(my $pm = Process::Async::Manager->new);
my $ep = delete $args{exchange_prefix};
my $qp = delete $args{queue_prefix};
my @child = map $pm->spawn(
	child => sub {
		App::loadtest::Child->new(
			target => $target,
			conntarget => $conntarget,
			stats => \%stats,
		)
	},
	worker => sub {
		App::loadtest::Worker->new(
			hosts    => \@hosts,
			parallel => $parallel,
			queue_prefix => $qp // 'xx',
			exchange_prefix => $ep // 'xx',
			mq_args  => \%args,
		)
	}
), 1..$forks;
eval {
	$loop->run;
	1
} or warn $@;

$_->kill(9) for @child;

