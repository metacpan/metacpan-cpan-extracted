use strict;
use warnings;
use Test::More tests => 8;
use POE;
use POE::Session;

BEGIN {
	my $mq = "POE::Component::MessageQueue";
	require_ok($mq."::Message");
	require_ok($mq."::Logger");
	require_ok($mq."::Storage::Complex");
	require_ok($mq."::Storage::BigMemory");
};

my $logger = POE::Component::MessageQueue::Logger->new;
$logger->set_log_function(sub{});
my $complex = POE::Component::MessageQueue::Storage::Complex->new(
	front       => POE::Component::MessageQueue::Storage::BigMemory->new,
	back        => POE::Component::MessageQueue::Storage::BigMemory->new,
	timeout     => 2,
	granularity => 1,
	front_max   => 64 * 8, # should hold 8 messages!
);
$complex->set_logger($logger);

ok($complex, "store created");
my $now = time();
my $p = 1;

sub mkmsg 
{
	my ($id, $timestamp, $persistent, $expire) = @_;
	my $msg = POE::Component::MessageQueue::Message->new(
		id          => $id,
		timestamp   => $timestamp,
		persistent  => $persistent,
		destination => "/queue/completely/unimportant",
		body        => "." x 64,
	);
	$msg->expire_at($now + $expire) if $expire;
	return $msg;
}

my @messages = (
	mkmsg('quickie', $now, 0, 1),                       # this should get bumped
	mkmsg('long_expire', $now, 0, $complex->timeout+3), # this should persist
  map mkmsg($_, $now+$_, $p = !$p), (1..64),
);

sub _last_count {
	$complex->back->get_all(sub {
		is(@{$_[0]}, 32, "persistent messages stored.");
		$complex->storage_shutdown();
	});
}

sub _final_delay {
	my $kernel = $_[KERNEL];
	$kernel->delay(_last_count => 5);
}

sub _count {
	my ($kernel,$session) = @_[KERNEL, SESSION];
	$complex->front->get_all(sub {
		my $aref = shift;
		is(@$aref, 8, "front store size");
		$complex->back->get([q(long_expire)], sub {
			ok($_[0]->[0], "nonpersistent expiration");
			$kernel->post($session, '_final_delay');
		});
	});
}

sub _store {
	my ($kernel, $session, $messages) = @_[KERNEL, SESSION, ARG0..ARG1];
	if (my $m = shift(@$messages)) {
		$complex->store($m, sub {
			$kernel->post($session, '_store', $messages);
		});	
	}
	else {
		$kernel->delay(_count => $complex->timeout+1);
	}
}

sub _start {
	my ($kernel, $session) = @_[KERNEL, SESSION];
	$kernel->post($session, '_store', \@messages); 	
}

POE::Session->create(inline_states => { 
	_start       => \&_start,
	_store       => \&_store,
	_count       => \&_count,
	_final_delay => \&_final_delay,
	_last_count  => \&_last_count,
});
$poe_kernel->run();
