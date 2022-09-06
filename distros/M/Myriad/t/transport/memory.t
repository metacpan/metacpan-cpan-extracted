use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Scalar::Util qw(looks_like_number);

use Object::Pad;
use Myriad::Transport::Memory;

use IO::Async::Loop;
my $loop = IO::Async::Loop->new();

$loop->add(my $transport = Myriad::Transport::Memory->new());

subtest 'In-Memory streams tests' => sub {
    my $id = $transport->add_to_stream('stream_1', key => 'value')->get();
    ok(looks_like_number($id), 'it should return new message id');

    $id = $transport->add_to_stream('stream_1', key => 'value')->get();
    is($id, 1, 'it should return a new ID for new message in the same stream');
};


subtest 'In-Memory streams read' => sub {
    $transport->add_to_stream('stream_read', key => $_)->get() for (0..9);
    my $messages = $transport->read_from_stream('stream_read')->get();
    is(0 + keys(%$messages), 50, 'messages has been received correctly');

    $messages = $transport->read_from_stream('stream_read', 5, 1)->get();
    is(keys %$messages, 1, 'it should respect messages read limit');
    is($messages->{5}->{key}, 5, 'it should respect messages read offset');

    $messages = $transport->read_from_stream('does not exist')->get();
    is(keys %$messages, 0, 'it should return an empty array of stream not found');
};

subtest 'In-Memory strams consumer groups' => sub {
    like(exception {
            $transport->create_consumer_group('stream does not exist', 'group_name')->get();
    }, qr{^The given stream does not exist.*}, 'it should throw an exception if stream does not exist');

    $transport->create_consumer_group('consumer_stream', 'test_group', 0, 1)->get();

    $transport->add_to_stream('consumer_stream', key => $_)->get() for (0..99);

    my $first_consumer_message  = $transport->read_from_stream_by_consumer('consumer_stream', 'test_group', 'consumer_1', 0, 1)->get();
    my $second_consumer_message = $transport->read_from_stream_by_consumer('consumer_stream', 'test_group', 'consumer_2', 0, 1)->get();
    ok($first_consumer_message->{0} && $second_consumer_message->{1}, 'it should deliver two different messages');

    # you can't claim a message after acknowledging it
    $transport->ack_message('consumer_stream', 'test_group', 0)->get();
    my $message = $transport->claim_message('consumer_stream', 'test_group', 'new_consumer', 0)->get();

    ok(keys %$message == 0, 'it should not allow claiming acknowledged messages');

    $message = $transport->claim_message('consumer_stream', 'test_group', 'new_consumer', 1)->get();
    ok($message, 'it should allow re-claiming messages');

};


subtest 'In-Memory pub/sub' => sub {
    my $sub = $transport->subscribe('sub')->get();
    isa_ok($sub, 'Ryu::Source', 'it should return a Ryu::Source');

    $sub->take(1)->each(sub {
        is(shift, 'message', 'it should publish the messages');
    });

    $transport->publish('sub', 'message')->get();
};

done_testing();
