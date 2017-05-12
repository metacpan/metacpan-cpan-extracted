use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Warnings;

use Protocol::FIX qw/humanize/;
use Protocol::FIX::Field;
use Protocol::FIX::Group;
use Protocol::FIX::Component;
use Protocol::FIX::Message;

my $proto = Protocol::FIX->new('FIX44');

subtest "Logon Message" => sub {
    my @composites = (
        $proto->field_by_name('EncryptMethod')         => 1,
        $proto->field_by_name('HeartBtInt')            => 1,
        $proto->field_by_name('RawDataLength')         => 0,
        $proto->field_by_name('RawData')               => 0,
        $proto->field_by_name('ResetSeqNumFlag')       => 0,
        $proto->field_by_name('NextExpectedMsgSeqNum') => 0,
        $proto->field_by_name('MaxMessageSize')        => 0,
        # NoMsgTypes - it's group
        $proto->field_by_name('TestMessageIndicator') => 0,
        $proto->field_by_name('Username')             => 0,
        $proto->field_by_name('Password')             => 0,
    );

    my $m = Protocol::FIX::Message->new('Logon', 'admin', 'A', \@composites, $proto,);
    ok $m;

    is $m->{field_to_component}->{'EncryptMethod'}, 'Logon';

    my $s = $m->serialize([
        SenderCompID  => 'me',
        TargetCompID  => 'you',
        MsgSeqNum     => 1,
        SendingTime   => '20090107-18:15:16',
        EncryptMethod => 'NONE',
        HeartBtInt    => 21,
    ]);
    is humanize($s), '8=FIX.4.4 | 9=56 | 35=A | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 98=0 | 108=21 | 10=107 | ';
};

subtest "Email Message" => sub {
    my @composites = (
        $proto->field_by_name('EmailThreadID')      => 1,
        $proto->field_by_name('EmailType')          => 0,
        $proto->field_by_name('OrigTime')           => 0,
        $proto->field_by_name('Subject')            => 1,
        $proto->field_by_name('EncodedSubjectLen')  => 0,
        $proto->component_by_name('RoutingGrp')     => 0,
        $proto->component_by_name('InstrmtGrp')     => 0,
        $proto->component_by_name('UndInstrmtGrp')  => 0,
        $proto->component_by_name('InstrmtLegGrp')  => 0,
        $proto->field_by_name('OrderID')            => 0,
        $proto->field_by_name('ClOrdID')            => 0,
        $proto->component_by_name('LinesOfTextGrp') => 1,
        $proto->field_by_name('RawDataLength')      => 0,
        $proto->field_by_name('RawData')            => 0,
    );

    my $m = Protocol::FIX::Message->new('Email', 'app', 'C', \@composites, $proto,);
    ok $m;
    is $m->{field_to_component}->{'RoutingGrp'},     'Email';
    is $m->{field_to_component}->{'LinesOfTextGrp'}, 'Email';
    is $m->{field_to_component}->{'NoLinesOfText'},  'LinesOfTextGrp';

    my $s = $m->serialize([
            SenderCompID   => 'me',
            TargetCompID   => 'you',
            MsgSeqNum      => 1,
            SendingTime    => '20090107-18:15:16',
            EmailThreadID  => 'thread-id',
            Subject        => 'Hello!',
            LinesOfTextGrp => [
                NoLinesOfText => [[Text => 'message body']],
            ],
        ]);
    is humanize($s),
        '8=FIX.4.4 | 9=90 | 35=C | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 164=thread-id | 147=Hello! | 33=1 | 58=message body | 10=191 | ';
};

subtest "Logon Message (with group)" => sub {
    my $m = $proto->message_by_name('Logon');
    ok $m;

    my $s = $m->serialize([
            SenderCompID  => 'me',
            TargetCompID  => 'you',
            MsgSeqNum     => 1,
            SendingTime   => '20090107-18:15:16',
            EncryptMethod => 'NONE',
            HeartBtInt    => 21,
            NoMsgTypes    => [[
                    RefMsgType   => 'a',
                    MsgDirection => 'SEND'
                ],
                [
                    RefMsgType   => 'b',
                    MsgDirection => 'RECEIVE'
                ],
            ],
        ]);
    is humanize($s),
        '8=FIX.4.4 | 9=86 | 35=A | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 98=0 | 108=21 | 384=2 | 372=a | 385=S | 372=b | 385=R | 10=085 | ';
};

subtest "MarketDataRequestReject Message (with subcomponent)" => sub {
    my $m = $proto->message_by_name('MarketDataRequestReject');
    ok $m;

    my $s = $m->serialize([
            SenderCompID => 'me',
            TargetCompID => 'you',
            MsgSeqNum    => 1,
            SendingTime  => '20090107-18:15:16',
            MDReqID      => 'abc',
            MDRjctGrp    => [
                NoAltMDSource => [[AltMDSourceID => 'def']],
            ],
        ]);
    is humanize($s), '8=FIX.4.4 | 9=66 | 35=Y | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 262=abc | 816=1 | 817=def | 10=132 | ';
};

subtest "IOI message simple component + complex component (subcomponent + group)" => sub {
    my $m = $proto->message_by_name('IOI');
    ok $m;
    my $s = $m->serialize([
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
    is humanize($s),
        '8=FIX.4.4 | 9=108 | 35=6 | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 23=abc | 28=C | 27=L | 54=G | 55=EURUSD | 864=3 | 865=1 | 865=2 | 865=99 | 38=499 | 10=100 | ';
};

done_testing;
