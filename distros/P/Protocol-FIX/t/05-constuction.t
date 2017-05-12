use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Protocol::FIX;

my $proto = Protocol::FIX->new('FIX44');
ok $proto;

is $proto->id, 'FIX.4.4';

subtest "check simple field" => sub {
    my $f_account = $proto->field_by_name('Account');
    ok $f_account;
    my $f_account_2 = $proto->field_by_number(1);
    ok $f_account_2;
    is $f_account, $f_account_2;
};

subtest "check field with enum(AdvSide)" => sub {
    my $f = $proto->field_by_name('AdvSide');
    ok $f;
    my $f_2 = $proto->field_by_number(4);
    ok $f_2;
    is $f, $f_2;
};

subtest "check simple component (CommissionData)" => sub {
    my $c = $proto->component_by_name('CommissionData');
    ok $c;

    # check internals
    my $composites = $c->{composites};
    ok $composites;
    ok scalar(@$composites);

    is $composites->[0]->{name}, "Commission";
    ok !$composites->[1], "not required";

    is $composites->[2]->{name}, "CommType";
    ok !$composites->[3], "not required";

    is $composites->[4]->{name}, "CommCurrency";
    ok !$composites->[5], "not required";

    is $composites->[6]->{name}, "FundRenewWaiv";
    ok !$composites->[7], "not required";
};

subtest "check component, consisted from single group(Stipulations)" => sub {
    my $c = $proto->component_by_name('Stipulations');
    ok $c;

    # check internals
    my $composites = $c->{composites};
    ok $composites;

    is $composites->[0]->{name}, "NoStipulations";
    ok !$composites->[1], "not required";

    $composites = $c->{composites}->[0]->{composites};
    is $composites->[0]->{name}, "StipulationType";
    ok !$composites->[1], "not required";

    is $composites->[2]->{name}, "StipulationValue";
    ok !$composites->[3], "not required";
};

subtest "check group with sub-component(NoNestedPartyIDs) and it's container(NestedParties)" => sub {
    my $c = $proto->component_by_name('NestedParties');
    ok $c;
    ok $c->{composite_by_name}->{'NoNestedPartyIDs'}->[0];

    my $g = $c->{composite_by_name}->{'NoNestedPartyIDs'}->[0];
    ok $g;

    my $composite_for = $g->{composite_by_name};
    ok $composite_for;

    ok $composite_for->{NstdPtysSubGrp};
    ok $composite_for->{NestedPartyID};
    ok $composite_for->{NestedPartyIDSource};
    ok $composite_for->{NestedPartyRole};

    my $g_2 = $composite_for->{NstdPtysSubGrp}->[0]->{composite_by_name}->{NoNestedPartySubIDs}->[0];
    ok $g_2;
    ok $g_2->{composite_by_name}->{NestedPartySubID};
    ok $g_2->{composite_by_name}->{NestedPartySubIDType};

};

subtest "check group(NoCapacities) & component(CpctyConfGrp) with mandatory composites" => sub {
    my $c = $proto->component_by_name('CpctyConfGrp');
    ok $c;

    is $c->{composites}->[0]->{name}, 'NoCapacities';
    ok $c->{composites}->[1], 'mandatory';

    my $g          = $c->{composites}->[0];
    my $composites = $g->{composites};

    is $composites->[0]->{name}, "OrderCapacity";
    ok $composites->[1], "mandatory";

    is $composites->[2]->{name}, "OrderRestrictions";
    ok !$composites->[3], "not required";

    is $composites->[4]->{name}, "OrderCapacityQty";
    ok $composites->[5], "mandatory";
};

subtest "check header & trailer" => sub {
    subtest "trailer" => sub {
        my $t = $proto->trailer;
        ok $t;
        my $composite_for = $t->{composite_by_name};
        ok $composite_for->{SignatureLength};
        ok $composite_for->{Signature};
        ok $composite_for->{CheckSum};
    };

    subtest "header" => sub {
        my $h = $proto->header;
        ok $h;
        my $composite_for = $h->{composite_by_name};
        ok $composite_for->{BeginString};
        ok $composite_for->{SenderLocationID};
        ok $composite_for->{XmlDataLen};
        ok $composite_for->{Hop};
    };

};

subtest "check that groups with the same name(NoQuoteEntries) aren't equal" => sub {
    my $c1 = $proto->component_by_name('QuotCxlEntriesGrp');
    ok $c1;
    my $c2 = $proto->component_by_name('QuotEntryAckGrp');
    ok $c2;

    my $g1 = $c1->{composite_by_name}->{'NoQuoteEntries'}->[0];
    ok $g1;
    my $g2 = $c2->{composite_by_name}->{'NoQuoteEntries'}->[0];
    ok $g2;

    isnt $g1, $g2, "they are different objects (by memory layout)";

    subtest "QuotCxlEntriesGrp::NoQuoteEntries" => sub {
        ok $g1->{composite_by_name}->{Instrument};
        ok $g1->{composite_by_name}->{FinancingDetails};
        ok $g1->{composite_by_name}->{UndInstrmtGrp};
        ok $g1->{composite_by_name}->{InstrmtLegGrp};
        ok !$g1->{composite_by_name}->{QuoteEntryID};
    };

    subtest "QuotEntryAckGrp::NoQuoteEntries" => sub {
        ok $g2->{composite_by_name}->{QuoteEntryID};
        ok $g2->{composite_by_name}->{Instrument};
        ok $g2->{composite_by_name}->{InstrmtLegGrp};
        ok $g2->{composite_by_name}->{BidPx};
        ok !$g2->{composite_by_name}->{UndInstrmtGrp};
    };
};

sub check_header_tail {
    my $m = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok !$m->{composite_by_name}->{BeginString}, "no managed field from header";
    ok $m->{composite_by_name}->{LastMsgSeqNumProcessed}, "field from header";
    ok $m->{composite_by_name}->{Hop},                    "component from header";
    ok $m->{composite_by_name}->{Signature},              "field from trailer";
    ok !$m->{composite_by_name}->{CheckSum}, "not managed field from trailer";
}

subtest "message with single field(Heartbeat)" => sub {
    my $m = $proto->message_by_name('Heartbeat');
    ok $m;
    check_header_tail($m);
    ok $m->{composite_by_name}->{TestReqID}, "own field is presented";
    is $m->{category}, 'admin';
};

subtest "message with many fields & components (News)" => sub {
    my $m = $proto->message_by_name('News');
    ok $m;
    check_header_tail($m);

    ok $m->{composite_by_name}->{OrigTime},   "own field is presented";
    ok $m->{composite_by_name}->{Urgency},    "own field is presented";
    ok $m->{composite_by_name}->{RoutingGrp}, "own component is presented";
    ok $m->{composite_by_name}->{InstrmtGrp}, "own component is presented";
    is $m->{category}, 'app';
};

subtest "message with group (Logon)" => sub {
    my $m = $proto->message_by_name('Logon');
    ok $m;
    check_header_tail($m);
    is $m->{category}, 'admin';

    ok $m->{composite_by_name}->{EncryptMethod}, "own field is presented";
    my $g = $m->{composite_by_name}->{NoMsgTypes}->[0];
    ok $g, "group NoMsgTypes is presented";
    $g->{composite_by_name}->{RefMsgType}, "needed field is available in group";
};

done_testing;
