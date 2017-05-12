use strict;
use warnings;

use Test::Fatal;
use Test::More;
use Test::Warnings;

use Protocol::FIX qw/humanize/;

my $proto = Protocol::FIX->new('FIX44');

sub dehumanize {
    my $buff = shift;
    return $buff =~ s/ \| /\x{01}/gr;
}

subtest "header & trail errors" => sub {
    my ($m, $err);
    subtest "not enough data" => sub {
        ($m, $err) = $proto->parse_message(\"");
        ok !$m;
        is $err, undef;

        ($m, $err) = $proto->parse_message(\"8=FIX.4.4");
        ok !$m;
        is $err, undef;
    };

    subtest "protocol mismatch" => sub {
        ($m, $err) = $proto->parse_message(\"8=FIX.4.3");
        ok !$m;
        is $err, "Mismatch protocol introduction, expected: 8=FIX.4.4";
    };

    subtest "protocol error (wrong separator)" => sub {
        ($m, $err) = $proto->parse_message(\"8=FIX.4.4_");
        ok !$m;
        is $err, "Protocol error: separator expecter right after 8=FIX.4.4";
    };

    subtest "protocol error (wrong tag)" => sub {
        my $buff = dehumanize("8=FIX.4.4 | z=5");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, "Protocol error: sequence 'z=5' does not match tag pair";
    };

    subtest "protocol error (wrong tag)" => sub {
        my $buff = dehumanize("8=FIX.4.4 | zz");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, "Protocol error: sequence 'zz' does not match tag pair";
    };

    subtest "protocol error (wrong tag)" => sub {
        my $buff = dehumanize("8=FIX.4.4 | 999=5");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, "Protocol error: unknown tag '999' in tag pair '999=5'";
    };

    subtest "protocol error (not length)" => sub {
        my $buff = dehumanize("8=FIX.4.4 | 8=4");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, "Protocol error: expected field 'BodyLength', but got 'BeginString', in sequence '8=4'";
    };

    subtest "incomplete length tag pair" => sub {
        my $buff = dehumanize("8=FIX.4.4 | 9=4");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, undef;
    };

    subtest "incomplete length tag pair" => sub {
        my $buff = dehumanize("8=FIX.4.4 | 9=4");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, undef;
    };

    subtest "wrong body length" => sub {
        my $buff = dehumanize("8=FIX.4.4 | 9=0 | ");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, "Protocol error: value for field 'BodyLength' does not pass validation in tag pair '9=0'";
    };

    subtest "no checksum yet" => sub {
        my $buff = dehumanize("8=FIX.4.4 | 9=4 | ");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, undef;

        $buff = dehumanize("8=FIX.4.4 | 9=4 | 10=01");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, undef;
        # 10=A inside body
        $buff = $buff = dehumanize("8=FIX.4.4 | 9=5 | 10=A | ");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, undef;
    };

    subtest "wrong checksum" => sub {
        my $buff = dehumanize("8=FIX.4.4 | 9=4 | ... | 10=A | ");

        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, "Protocol error: value for field 'CheckSum' does not pass validation in tag pair '10=A'";

        $buff = dehumanize("8=FIX.4.4 | 9=4 | ... | 10=1000 | ");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, "Protocol error: value for field 'CheckSum' does not pass validation in tag pair '10=1000'";

        $buff = dehumanize("8=FIX.4.4 | 9=4 | ... | 10=256 | ");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, "Protocol error: value for field 'CheckSum' does not pass validation in tag pair '10=256'";

        $buff = dehumanize("8=FIX.4.4 | 9=4 | ... | 10=015 | ");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, "Protocol error: Checksum mismatch;  got 87, expected 015 for message '8=FIX.4.4 | 9=4 | ... | '";
    };

};

subtest "body errors" => sub {
    my ($m, $err, $buff);

    subtest "no MsgType" => sub {
        $buff = dehumanize("8=FIX.4.4 | 9=4 | 9=5 | 10=120 | ");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, "Protocol error: 'MsgType' was not found in body";
    };

    subtest "wrong MsgType" => sub {
        $buff = dehumanize("8=FIX.4.4 | 9=6 | 35=ZZ | 10=040 | ");
        ($m, $err) = $proto->parse_message(\$buff);
        ok !$m;
        is $err, "Protocol error: value for field 'MsgType' does not pass validation in tag pair '35=ZZ'";
    };

};

subtest "simple message (Logon)" => sub {
    my $buff = dehumanize('8=FIX.4.4 | 9=56 | 35=A | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 98=0 | 108=60 | 10=110 | ');

    my ($mi, $err) = $proto->parse_message(\$buff);
    ok $mi;
    is $err, undef;

    is $mi->name,     'Logon';
    is $mi->category, 'admin';
    is $mi->value('SenderCompID'),  'me';
    is $mi->value('TargetCompID'),  'you';
    is $mi->value('MsgSeqNum'),     '1';
    is $mi->value('SendingTime'),   '20090107-18:15:16';
    is $mi->value('EncryptMethod'), 'NONE';
    is $mi->value('HeartBtInt'),    60;
};

subtest "message with component (MarketDataRequestReject)" => sub {
    my $buff      = dehumanize('8=FIX.4.4 | 9=66 | 35=Y | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 262=abc | 816=1 | 817=def | 10=132 | ');
    my $buff_copy = $buff;

    my $check_message = sub {
        my ($mi, $err) = @_;
        ok $mi;
        is $err, undef;

        is $mi->name,     'MarketDataRequestReject';
        is $mi->category, 'app';
        is $mi->value('SenderCompID'), 'me';
        is $mi->value('TargetCompID'), 'you';
        is $mi->value('MsgSeqNum'),    '1';
        is $mi->value('SendingTime'),  '20090107-18:15:16';
        is $mi->value('MDReqID'),      'abc';

        my $group = $mi->value('MDRjctGrp')->value('NoAltMDSource');
        ok $group;
        is scalar(@$group), 1;
        is $group->[0]->value('AltMDSourceID'), 'def';
    };

    subtest "single message consumption" => sub {
        my ($mi, $err) = $proto->parse_message(\$buff);
        $check_message->($mi, $err);
        is $buff, '';
    };

    subtest "double message consumption" => sub {
        $buff = $buff_copy . $buff_copy;
        my ($mi1, $err1) = $proto->parse_message(\$buff);
        $check_message->($mi1, $err1);
        is $buff, $buff_copy;

        my ($mi2, $err2) = $proto->parse_message(\$buff);
        $check_message->($mi2, $err2);
        is $buff, '';
    };

    subtest "byte-by-byte feeding" => sub {
        for my $length (0 .. length($buff_copy) - 1) {
            $buff = substr($buff_copy, 0, $length);
            my ($mi, $err) = $proto->parse_message(\$buff);
            is $mi,  undef;
            is $err, undef;
        }
    };

    subtest "2 entities in group" => sub {
        my $buff =
            dehumanize('8=FIX.4.4 | 9=75 | 35=Y | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 262=abc | 816=2 | 817=def | 817=ghjl | 10=008 | ');
        my ($mi, $err) = $proto->parse_message(\$buff);
        ok $mi;
        is $err, undef;
    };
};

subtest "body errors" => sub {
    subtest "unexpected field (BeginString)" => sub {
        my $buff =
            dehumanize('8=FIX.4.4 | 9=76 | 35=Y | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 262=abc | 8=FIX.4.4 | 816=1 | 817=def | 10=166 | ');
        my ($mi, $err) = $proto->parse_message(\$buff);
        is $mi,  undef;
        is $err, "Protocol error: field 'BeginString' was not expected in message 'MarketDataRequestReject'";
    };

    subtest "unexpected field (HeartBtInt)" => sub {
        my $buff =
            dehumanize('8=FIX.4.4 | 9=73 | 35=Y | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 262=abc | 108=21 | 816=1 | 817=def | 10=188 | ');
        my ($mi, $err) = $proto->parse_message(\$buff);
        is $mi,  undef;
        is $err, "Protocol error: field 'HeartBtInt' was not expected in message 'MarketDataRequestReject'";
    };

    subtest "too many groups (1 declared, send 2)" => sub {
        my $buff =
            dehumanize('8=FIX.4.4 | 9=74 | 35=Y | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 262=abc | 816=1 | 817=def | 817=aaa | 10=132 | ');
        my ($mi, $err) = $proto->parse_message(\$buff);
        is $mi,  undef;
        is $err, "Protocol error: field 'AltMDSourceID' was not expected in message 'MarketDataRequestReject'";
    };

    subtest "too few groups (2 declared, send 1)" => sub {
        my $buff = dehumanize('8=FIX.4.4 | 9=66 | 35=Y | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 262=abc | 816=2 | 817=def | 10=133 | ');
        my ($mi, $err) = $proto->parse_message(\$buff);
        is $mi,  undef;
        is $err, "Protocol error: cannot construct item #2 for component 'MDRjctGrp' (group 'NoAltMDSource')";
    };

    subtest "missing mandatory field" => sub {
        my $buff = dehumanize('8=FIX.4.4 | 9=58 | 35=Y | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 816=1 | 817=def | 10=135 | ');
        my ($mi, $err) = $proto->parse_message(\$buff);
        is $mi,  undef;
        is $err, "Protocol error: 'MDReqID' is mandatory for message 'MarketDataRequestReject'";
    };

};

subtest "message with group (Logon)" => sub {
    my $buff =
        dehumanize('8=FIX.4.4 | 9=76 | 35=A | 49=me | 56=you | 34=1 | 52=20090107-18:15:16 | 98=0 | 108=60 | 384=1 | 372=abc | 385=S | 10=175 | ');

    my ($mi, $err) = $proto->parse_message(\$buff);
    ok $mi;
    is $err, undef;

    my $group = $mi->value('NoMsgTypes');
    ok $group;
    is scalar(@$group), 1;
    is $group->[0]->value('RefMsgType'),   'abc';
    is $group->[0]->value('MsgDirection'), 'SEND';
};

subtest "Complex message: component, with group of components" => sub {
    my $buff = dehumanize('8=FIX.4.4 | 9=108 | 35=6 | 49=me | 56=you | 34=1 | 52=20090107-18:15:16'
            . ' | 23=abc | 28=C | 27=L | 54=G | 55=EURUSD | 864=3 | 865=1 | 865=2 | 865=99 | 38=499 | 10=100 | ');

    my ($mi, $err) = $proto->parse_message(\$buff);
    ok $mi;
    is $err, undef;

    is $mi->value('IOIID'),        'abc';
    is $mi->value('IOITransType'), 'CANCEL';
    is $mi->value('IOIQty'),       'LARGE';
    is $mi->value('Side'),         'BORROW';
    is $mi->value('OrderQtyData')->value('OrderQty'), '499';
    is $mi->value('Instrument')->value('Symbol'),     'EURUSD';

    my $g = $mi->value('Instrument')->value('EvntGrp')->value('NoEvents');
    ok $g;
    is $g->[0]->value('EventType'), 'PUT';
    is $g->[1]->value('EventType'), 'CALL';
    is $g->[2]->value('EventType'), 'OTHER';
};

subtest "Logon message (from 3rd-party app)" => sub {
    my $buff = dehumanize(
        '8=FIX.4.4 | 9=97 | 35=A | 49=CLIENT1 | 52=20170310-09:36:44.000 | 56=FixServer | 34=1 | 98=0 | 108=30 | 553=fake-panda | 554=secret | 10=145 | '
    );
    my ($mi, $err) = $proto->parse_message(\$buff);
    ok $mi;
    is $err, undef;
};

done_testing;
