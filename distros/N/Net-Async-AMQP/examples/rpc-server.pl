#!/usr/bin/env perl 
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout);

use IO::Async::Loop;

use Net::Async::AMQP::RPC::Server;
use Net::Async::AMQP::RPC::Client;

my %args;
GetOptions(
	"help|?"      => \my $help,
	"host|h=s"    => \$args{host},
	"user|u=s"    => \$args{user},
	"pass=s"      => \$args{pass},
	"port=i"      => \$args{port},
	"vhost|v=s"   => \$args{vhost},
	"queue|q=s"   => \$args{queue},
	"exchange|e=s"   => \$args{exchange},
) or pod2usage(2);
pod2usage(1) if $help;

$args{user} //= 'guest';
$args{pass} //= 'guest';
$args{host} //= 'localhost';
$args{port} //= 5672;
$args{vhost} //= '/';

# Establish an event loop first
my $loop = IO::Async::Loop->new;

# We keep a Future around that we can wait on for user shutdown requests
my $shutdown = $loop->new_future->set_label('shutdown request');

# Now set up our RPC endpoint
$loop->add(
	my $srv = Net::Async::AMQP::RPC::Server->new(
		# We could pass an 'mq' parameter here with an existing AMQP
		# connection. Since the RPC server is the only user of the
		# connection, allow it to connect automatically.
		host  => $args{host},
		user  => $args{user},
		pass  => $args{pass},
		port  => $args{port},
		vhost => $args{vhost},
		queue => $args{queue},
		exchange => $args{exchange},
		# We're using JSON for the protocol because it's somewhat
		# portable and easy to trace. 'handler' could be used instead
		# for raw data.
		json_handler => {
			shutdown => sub {
				my %args = @_;
				$log->infof("Shutdown request received (queue %s, reply %s)", $args{from}{queue}, $args{from}{reply_to});
				$shutdown->done('user request');
				return { status => 'ok' }
			},
			ping => sub {
				my %args = @_;
				$log->infof("Ping request received (queue %s, reply %s)", $args{from}{queue}, $args{from}{reply_to});
				return { status => 'ok', message => 'pong' }
			},
		}
	)
);

$srv->active->get;
$log->infof("RPC server listening on exchange [%s]", $srv->exchange);

for my $sig (qw(INT TERM QUIT)) {
	$loop->attach_signal($sig => sub { warn "received $sig"; $shutdown->done('SIG' . $sig) })
}

# We're now ready to accept messages. Sit and wait for things to happen,
# processing messages and any other event loop activity until the user
# requests a shutdown.
$log->infof("Shutdown received: %s", $shutdown->get);

$srv->mq->close->get;
$log->info("Closed MQ connection");

