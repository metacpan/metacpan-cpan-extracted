use Test::More tests => 13;

use strict;
use warnings;

use threads;
use threads::shared;

use_ok('Pots::Message');
can_ok('Pots::Message',
       qw(new type get set)
);

use_ok('Pots::MessageQueue');
can_ok('Pots::MessageQueue',
       qw(new postmsg getmsg nbmsg)
);

my $q = Pots::MessageQueue->new();
my $q2 = Pots::MessageQueue->new();
isa_ok($q, 'Pots::MessageQueue');

my $th = async {
    my $msg = $q->getmsg();

    isa_ok($msg, 'Pots::Message');
    is($msg->type(), 'TestMessage', "Message type");
    is($msg->get('data'), 'TestData', "Message data");

    $msg->type('TestReply');
    $msg->set('data', 'TestReplyData');
    $q2->postmsg($msg);

    $msg = $q->getmsg();
    is($msg->type(), 'quit', "Bi-directionnal communication");
};

my $msg = Pots::Message->new();
isa_ok($msg, 'Pots::Message');

$msg->type('TestMessage');
$msg->set('data', 'TestData');
$q->postmsg($msg);

$msg = $q2->getmsg();
isa_ok($msg, 'Pots::Message');
is($msg->type(), 'TestReply', "Return message type");
is($msg->get('data'), 'TestReplyData', "Return message data");

my $msg2 = Pots::Message->new('quit', {key1 => 'value1'});
$q->postmsg($msg2);

$th->join();
