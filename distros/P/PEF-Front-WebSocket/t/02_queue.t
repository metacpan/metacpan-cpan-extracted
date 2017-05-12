package QueueTest;
use Clone 'clone';
use Data::Structure::Util qw( unbless );

sub new {
	bless \my $result, $_[0];
}

sub on_queue {
	my ($self, $queue, $id_message, $message) = @_;
	$$self = [$queue, $id_message, $message];
}

sub result {
	my $c = clone $_[0];
	unbless $c;
	$$c;
}

sub clear {
	$$_[0] = undef;
}

sub on_queue_error { }

package main;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

use PEF::Front::WebSocket::QueueServer;
use PEF::Front::WebSocket::QueueClient;

use Data::Dumper;

use AnyEvent;

my $cv = AnyEvent->condvar();

my $server = PEF::Front::WebSocket::QueueServer->new;
my @clients;
@clients = (
	{   client => PEF::Front::WebSocket::QueueClient->new,
		test   => [QueueTest->new(), QueueTest->new(), QueueTest->new(), QueueTest->new(),]
	},
	{   client => PEF::Front::WebSocket::QueueClient->new,
		test   => [QueueTest->new(), QueueTest->new(), QueueTest->new(), QueueTest->new(),]
	},
	{   client => PEF::Front::WebSocket::QueueClient->new,
		test   => [QueueTest->new(), QueueTest->new(), QueueTest->new(), QueueTest->new(),]
	},
);

$clients[0]{client}->subscribe("test0", $clients[0]{test}[0]);
$clients[1]{client}->subscribe("test0", $clients[1]{test}[0]);
$clients[2]{client}->subscribe("test0", $clients[2]{test}[0]);

$clients[0]{client}->subscribe("test1", $clients[0]{test}[1]);
$clients[0]{client}->subscribe("test1", $clients[0]{test}[2]);
$clients[1]{client}->subscribe("test1", $clients[1]{test}[1]);

$clients[0]{client}->subscribe("test2", $clients[0]{test}[3]);
$clients[1]{client}->subscribe("test2", $clients[1]{test}[3]);
$clients[2]{client}->subscribe("test2", $clients[2]{test}[3]);
$clients[1]{client}->subscribe("test2", $clients[1]{test}[2]);
$clients[2]{client}->subscribe("test2", $clients[2]{test}[2]);

my $tt;
$tt = AnyEvent->timer(
	after => 0.05,
	cb    => sub {
		$clients[0]{client}->publish("test0", 1, {message => 'test message 1'});
		$clients[1]{client}->publish("test1", 2, {message => 'test message 2'});
		$clients[2]{client}->publish("test2", 3, {message => 'test message 3'});
		$clients[2]{client}->unsubscribe("test2", $clients[2]{test}[2]);
		$tt = AnyEvent->timer(
			after => 0.05,
			cb    => sub {
				is_deeply($clients[0]{test}[0]->result, ["test0", 1, {message => 'test message 1'}], 't 1.1');
				is_deeply($clients[1]{test}[0]->result, ["test0", 1, {message => 'test message 1'}], 't 1.2');
				is_deeply($clients[2]{test}[0]->result, ["test0", 1, {message => 'test message 1'}], 't 1.3');
				is_deeply($clients[0]{test}[1]->result, ["test1", 2, {message => 'test message 2'}], 't 2.2');
				is_deeply($clients[0]{test}[2]->result, ["test1", 2, {message => 'test message 2'}], 't 2.3');
				is_deeply($clients[1]{test}[1]->result, ["test1", 2, {message => 'test message 2'}], 't 2.4');
				is_deeply($clients[0]{test}[3]->result, ["test2", 3, {message => 'test message 3'}], 't 3.1');
				is_deeply($clients[1]{test}[3]->result, ["test2", 3, {message => 'test message 3'}], 't 3.2');
				is_deeply($clients[2]{test}[3]->result, ["test2", 3, {message => 'test message 3'}], 't 3.3');
				is_deeply($clients[1]{test}[2]->result, ["test2", 3, {message => 'test message 3'}], 't 3.4');
				is_deeply($clients[2]{test}[2]->result, ["test2", 3, {message => 'test message 3'}], 't 3.5');
				$tt = AnyEvent->timer(
					after => 0.05,
					cb    => sub {
						$clients[1]{client}->unsubscribe("test2", $clients[1]{test}[2]);
						$clients[1]{client}->publish("test2", 4, {message => 'test message 4'});
						$tt = AnyEvent->timer(
							after => 0.05,
							cb    => sub {
								is_deeply($clients[0]{test}[3]->result, ["test2", 4, {message => 'test message 4'}], 't 4.1');
								is_deeply($clients[1]{test}[3]->result, ["test2", 4, {message => 'test message 4'}], 't 4.2');
								is_deeply($clients[2]{test}[3]->result, ["test2", 4, {message => 'test message 4'}], 't 4.3');
								is_deeply($clients[1]{test}[2]->result, ["test2", 3, {message => 'test message 3'}], 't 4.4');
								is_deeply($clients[2]{test}[2]->result, ["test2", 3, {message => 'test message 3'}], 't 4.5');
								$clients[0]{client}->unregister_client($clients[0]{test}[3]);
								$clients[0]{test}[3]->clear;
								$clients[0]{client}->subscribe("test2", $clients[0]{test}[3], 3);
								$tt = AnyEvent->timer(
									after => 0.05,
									cb    => sub {
										is_deeply(
											$clients[0]{test}[3]->result,
											["test2", 4, {message => 'test message 4'}],
											't 5.1'
										);
									}
								);
							}
						);
					}
				);
			}
		);
	}
);

my $et = AnyEvent->timer(
	after => 0.4,
	cb    => sub {
		$cv->send;
	}
);

$cv->recv;

done_testing();
