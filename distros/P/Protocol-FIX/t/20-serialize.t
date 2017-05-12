use strict;
use warnings;

use Test::Fatal;
use Test::More;
use Test::Warnings;

use Protocol::FIX qw/humanize/;

my $proto = Protocol::FIX->new('FIX44');

subtest "Logon Message serialization" => sub {
    my $buff = $proto->serialize_message(
        'Logon' => [
            SenderCompID  => 'me',
            TargetCompID  => 'you',
            MsgSeqNum     => 1,
            SendingTime   => '20090107-18:15:16',
            EncryptMethod => 'NONE',
            HeartBtInt    => 60,
        ]);
    is humanize($buff), '8=FIX.4.4 | 9=56 | 35=A | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 98=0 | 108=60 | 10=110 | ';
};

subtest "Advertisement Message serialization (i.e. with component)" => sub {
    my $buff = $proto->serialize_message(
        'Advertisement' => [
            SenderCompID => 'me',
            TargetCompID => 'you',
            MsgSeqNum    => 1,
            SendingTime  => '20090107-18:15:16',
            AdvId        => 'some-id',
            AdvTransType => 'NEW',
            AdvSide      => 'BUY',
            Quantity     => 5,
            Instrument   => [Symbol => 'USDJPY'],
        ]);
    is humanize($buff),
        '8=FIX.4.4 | 9=77 | 35=7 | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 2=some-id | 5=N | 4=B | 53=5 | 55=USDJPY | 10=064 | ';
};

subtest "Logon Message serialization (i.e. with group)" => sub {
    my $buff = $proto->serialize_message(
        'Logon' => [
            SenderCompID  => 'me',
            TargetCompID  => 'you',
            MsgSeqNum     => 1,
            SendingTime   => '20090107-18:15:16',
            EncryptMethod => 'NONE',
            HeartBtInt    => 60,
            NoMsgTypes    => [[
                    RefMsgType   => 'abc',
                    MsgDirection => 'SEND'
                ],
                [
                    RefMsgType   => 'def',
                    MsgDirection => 'RECEIVE'
                ],
            ],
        ]);
    is humanize($buff),
        '8=FIX.4.4 | 9=90 | 35=A | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 98=0 | 108=60 | 384=2 | 372=abc | 385=S | 372=def | 385=R | 10=229 | ';
};

subtest "missing mandatory fields" => sub {
    like exception {
        $proto->serialize_message(
            'Logon' => [
                TargetCompID  => 'you',
                MsgSeqNum     => 1,
                SendingTime   => '20090107-18:15:16',
                EncryptMethod => 'NONE',
                HeartBtInt    => 60,
            ])
    }, qr/'SenderCompID' is mandatory for message 'Logon'/, "missing mandatory field in head";

    like exception {
        $proto->serialize_message(
            'Logon' => [
                SenderCompID  => 'me',
                TargetCompID  => 'you',
                MsgSeqNum     => 1,
                SendingTime   => '20090107-18:15:16',
                EncryptMethod => 'NONE',
            ])
    }, qr/'HeartBtInt' is mandatory for message 'Logon'/, "missing mandatory field in body";

    like exception {
        $proto->serialize_message(
            'Advertisement' => [
                SenderCompID => 'me',
                TargetCompID => 'you',
                MsgSeqNum    => 1,
                SendingTime  => '20090107-18:15:16',
                AdvId        => 'some-id',
                AdvTransType => 'NEW',
                AdvSide      => 'BUY',
                Quantity     => 5,
            ])
    }, qr/'Instrument' is mandatory for message 'Advertisement'/, "missing mandatory component in body";
};

subtest "trying to add field, which is n/a for particular message" => sub {
    like exception {
        $proto->serialize_message(
            'Logon' => [
                AdvId => 'some-id',
            ])
    }, qr/Composite 'AdvId' is not available for message 'Logon'/, "dies with explanation";
};

subtest "wrong values for field" => sub {
    like exception {
        $proto->serialize_message(
            'Logon' => [
                SenderCompID  => 'me',
                TargetCompID  => 'you',
                MsgSeqNum     => 1,
                SendingTime   => '20090107-18:15:16',
                EncryptMethod => 'NONE',
                HeartBtInt    => 'zzzz',
            ])
    }, qr/The value 'zzzz' is not acceptable for field HeartBtInt/;

    like exception {
        $proto->serialize_message(
            'Logon' => [
                SenderCompID  => 'me',
                TargetCompID  => 'you',
                MsgSeqNum     => 'zzzz',
                SendingTime   => '20090107-18:15:16',
                EncryptMethod => 'NONE',
                HeartBtInt    => 60,
            ])
    }, qr/The value 'zzzz' is not acceptable for field MsgSeqNum/;

    like exception {
        $proto->serialize_message(
            'Logon' => [
                SenderCompID  => 'me',
                TargetCompID  => 'you',
                MsgSeqNum     => 5,
                SendingTime   => '20090107',
                EncryptMethod => 'NONE',
                HeartBtInt    => 60,
            ])
    }, qr/The value '20090107' is not acceptable for field SendingTime/;
};

done_testing;
