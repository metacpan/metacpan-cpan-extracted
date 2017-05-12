use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Warnings;

use Protocol::FIX;

my $proto = Protocol::FIX->new('FIX44')->extension('t/data/extension-sample.xml');

my $serialized = $proto->message_by_name('IOI')->serialize([
        SenderCompID => 'me',
        TargetCompID => 'you',
        MsgSeqNum    => 1,
        SendingTime  => '20090107-18:15:16',
        IOIID        => 'abc',
        IOITransType => 'CANCEL',
        IOIQty       => 'LARGE',
        Side         => 'BORROW',
        Instrument   => [
            Symbol  => 'EURUSD',
            EvntGrp => [NoEvents => [[EventType => 'PUT'], [EventType => 'CALL'], [EventType => 'OTHER']]],
        ],
        OrderQtyData => [
            OrderQty => '499',
        ],
    ]);
ok $serialized;

my ($message_instance, $error) = $proto->parse_message(\$serialized);
ok $message_instance;
is $error, undef;

is $message_instance->name,     'IOI', "message name";
is $message_instance->category, 'app', "message category";

is $message_instance->value('SenderCompID'), 'me',     "Access to tags from header";
is $message_instance->value('IOITransType'), 'CANCEL', "Access to tags from message body";
is $message_instance->value('OrderQtyData')->value('OrderQty'), '499', "Access to tags from components";

my $group = $message_instance->value('Instrument')->value('EvntGrp')->value('NoEvents');
ok $group, "access to group of elements";
is ref($group), 'ARRAY';
is scalar(@$group), 3;
is $group->[0]->value('EventType'), 'PUT', "Access to individual elements in groups";

done_testing;

