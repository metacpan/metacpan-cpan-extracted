#!/usr/bin/env perl 
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

use IO::Async::Loop;
use Data::Dumper;

use Net::Async::AMQP::RPC::Server;
use Net::Async::AMQP::RPC::Client;

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout);

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

die 'need a command' unless defined(my $cmd = shift @ARGV);

$args{user} //= 'guest';
$args{pass} //= 'guest';
$args{host} //= 'localhost';
$args{port} //= 5672;
$args{vhost} //= '/';

# Establish an event loop and MQ connection first
my $loop = IO::Async::Loop->new;
$loop->add(my $mq = Net::Async::AMQP->new);
my $true = Net::AMQP::Value->true;
$mq->connect(
	host  => $args{host},
	user  => $args{user},
	pass  => $args{pass},
	port  => $args{port},
	vhost => $args{vhost},
	client_properties => {
		capabilities => {
			'consumer_cancel_notify' => $true,
		},
	},
)->get;

# Now set up our RPC endpoint
$loop->add(
	my $rpc = Net::Async::AMQP::RPC::Client->new(
		mq => $mq,
		queue => $args{queue},
		exchange => $args{exchange},
	)
);

# We could wait for ->active, but it's also safe to send requests
# immediately: they will be queued until the consumer is active.
eval {
	my $response = $rpc->json_request($cmd => { args => [ @ARGV ] })->get;
	print "Server response to [$cmd]: " . (delete $response->{status}) . ":\n" . Dumper($response);
} or do {
	warn "Server reports failure: $@\n"
};

