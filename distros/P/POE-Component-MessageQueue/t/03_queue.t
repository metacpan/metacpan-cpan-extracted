use strict;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use POE::Component::MessageQueue::Client;

BEGIN
{
#	plan tests => 13;
plan skip_all => "This API has changed a lot, needs cleanup.";

	use_ok("POE::Component::MessageQueue::Message");
	use_ok("POE::Component::MessageQueue::Queue");
	use_ok("Event::Notify");
}

my $mq	  = Test::MockObject::Extends->new( 'POE::Component::MessageQueue' );
my $storage = Test::MockObject->new;
my $qname   = '/queue/test';

$mq->set_always(log => 1);
$mq->set_always(storage => $storage);

{   
		# No reason to test that Moose is working, but let's construct one.
	my $q = POE::Component::MessageQueue::Queue->new({ 
		parent => $mq, 
		name => $qname 
	});
}

{
	my $ack_type = 'client';
	my $notify   = Event::Notify->new;
	my @clients  = map {Test::MockObject::Extends->new(
		POE::Component::MessageQueue::Client->new(id => $_)
	)} (1..2);

	local $mq->{notify} = $notify;
	$storage->mock(claim_and_retrieve => sub {
		ok(1, 'claim_and_retrieve called');
		return ()
	});

	my $queue	= POE::Component::MessageQueue::Queue->new( 
			parent => $mq, 
			name   => $qname 
	);

	foreach my $client (@clients) {
		$client->subscribe($queue, $ack_type);
		$client->mock(send_frame => sub {
			my ($self, $frame) = @_;
			is( $frame->headers->{destination}, $qname, "correct queue" );
			is( $frame->body, 'DUMMY', "correct body" );

			return 1;
		});
	}

	$mq->mock( push_unacked_message => sub {
		my ($self, $message, $cl) = @_;

		ok( $message->{message_id} eq 1 || $message->{message_id} eq 2, "correct message IDs (1 or 2)" );
	} );
	foreach my $message_id (1..10) {
		my $message =  POE::Component::MessageQueue::Message->new( {
			id  => $message_id,
			persistent => 0,
			destination => $qname,
			body		=> "DUMMY"
		} );
		$storage->mock(store => sub {
			my ($self, $msg) = @_;
			my $id = $msg->id;
			is($id, $message_id, "got the right message ($id <-> $message_id)");
		} );
		$queue->send($message);

	}
}
