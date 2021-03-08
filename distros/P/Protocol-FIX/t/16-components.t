use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Warnings;

use Protocol::FIX qw/humanize/;
use Protocol::FIX::Field;
use Protocol::FIX::Group;
use Protocol::FIX::Component;

subtest "simple component 'CommissionData'" => sub {
    my $f_1 = Protocol::FIX::Field->new(12, 'Commission', 'AMT');
    my $f_2 = Protocol::FIX::Field->new(
        13,
        'CommType',
        'CHAR',
        {
            1 => 'PER_UNIT',
            2 => 'PERCENTAGE',
            3 => 'ABSOLUTE',
            4 => 4,
            5 => 5,
            6 => 'POINTS_PER_BOND_OR_CONTRACT_SUPPLY_CONTRACTMULTIPLIER',
        });
    my $f_3 = Protocol::FIX::Field->new(479, 'CommCurrency', 'CURRENCY');
    my $f_4 = Protocol::FIX::Field->new(
        12,
        'FundRenewWaiv',
        'CHAR',
        {
            Y => 'YES',
            N => 'NO',
        });

    my $c = Protocol::FIX::Component->new(
        'CommissionData',
        [
            $f_1 => 0,
            $f_2 => 0,
            $f_3 => 0,
            $f_4 => 0
        ]);
    ok $c;

    is $c->{field_to_component}->{'Commission'},    'CommissionData';
    is $c->{field_to_component}->{'CommType'},      'CommissionData';
    is $c->{field_to_component}->{'CommCurrency'},  'CommissionData';
    is $c->{field_to_component}->{'FundRenewWaiv'}, 'CommissionData';

    is humanize(
        $c->serialize([
                Commission => 5.2,
                CommType   => 'PER_UNIT'
            ])
        ),
        '12=5.2 | 13=1';
};

subtest "component (AttrbGrp) with group(NoInstrAttrib)" => sub {
    my $f_0 = Protocol::FIX::Field->new(870, 'NoInstrAttrib', 'NUMINGROUP');
    my $f_1 = Protocol::FIX::Field->new(
        871,
        'InstrAttribType',
        'INT',
        {
            1 => 'FLAT',
            2 => 'ZERO_COUPON',
        });
    my $f_2 = Protocol::FIX::Field->new(872, 'InstrAttribValue', 'STRING');
    my $g   = Protocol::FIX::Group->new(
        $f_0,
        [
            $f_1 => 0,
            $f_2 => 0
        ]);
    my $c = Protocol::FIX::Component->new('AttrbGrp', [$g => 0]);
    ok $c;

    is $c->{field_to_component}->{'NoInstrAttrib'}, 'AttrbGrp';

    is humanize(
        $c->serialize([
                NoInstrAttrib => [[
                        InstrAttribType  => 'FLAT',
                        InstrAttribValue => 'abc'
                    ]]])
        ),
        '870=1 | 871=1 | 872=abc';
};

subtest "component (InstrumentExtension) with complex subcomponent (AttrbGrp)" => sub {
    my $f_0 = Protocol::FIX::Field->new(870, 'NoInstrAttrib', 'NUMINGROUP');
    my $f_1 = Protocol::FIX::Field->new(
        871,
        'InstrAttribType',
        'INT',
        {
            1 => 'FLAT',
            2 => 'ZERO_COUPON',
        });
    my $f_2 = Protocol::FIX::Field->new(872, 'InstrAttribValue', 'STRING');
    my $g   = Protocol::FIX::Group->new(
        $f_0,
        [
            $f_1 => 0,
            $f_2 => 0
        ]);
    my $c_inner = Protocol::FIX::Component->new('AttrbGrp', [$g => 0]);

    my $of_1 = Protocol::FIX::Field->new(
        668,
        'DeliveryForm',
        'INT',
        {
            1 => 'BOOKENTRY',
            2 => 'BEARER',
        });
    my $of_2    = Protocol::FIX::Field->new(869, 'PctAtRisk', 'PERCENTAGE');
    my $c_outer = Protocol::FIX::Component->new(
        'InstrumentExtension',
        [
            $of_1    => 0,
            $of_2    => 0,
            $c_inner => 0,
        ]);
    ok $c_outer;

    is $c_outer->{field_to_component}->{'DeliveryForm'},  'InstrumentExtension';
    is $c_outer->{field_to_component}->{'PctAtRisk'},     'InstrumentExtension';
    is $c_outer->{field_to_component}->{'NoInstrAttrib'}, 'AttrbGrp';

    is humanize(
        $c_outer->serialize([
                DeliveryForm => 'BOOKENTRY',
                PctAtRisk    => '0.06',
                AttrbGrp     => [
                    NoInstrAttrib => [[
                            InstrAttribType  => 'FLAT',
                            InstrAttribValue => 'abc'
                        ]]
                ],
            ])
        ),
        '668=1 | 869=0.06 | 870=1 | 871=1 | 872=abc';

};

done_testing;
