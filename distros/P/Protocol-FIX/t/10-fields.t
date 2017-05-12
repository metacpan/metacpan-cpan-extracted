use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Warnings;

use Protocol::FIX::Field;

subtest "STRING" => sub {
    subtest "string filed w/o enumerations" => sub {
        my $f = Protocol::FIX::Field->new(1, 'Account', 'STRING');
        my $s = $f->serialize('abc');
        is $s, '1=abc';

        ok $f->check('abc');
        ok !$f->check(undef);

        ok !$f->check('='), "delimiter is not allowed";
        like exception { $f->serialize('=') }, qr/not acceptable/;
        ok !$f->has_mapping;
    };

    subtest "string filed with enumerations" => sub {
        my $f = Protocol::FIX::Field->new(
            5,
            'AdvTransType',
            'STRING',
            {
                N => 'NEW',
                C => 'CANCEL',
                R => 'REPLACE',
            });
        ok $f->has_mapping;
        is $f->serialize('NEW'), '5=N';

        ok $f->check('NEW');
        ok $f->check('CANCEL');
        ok $f->check('REPLACE');

        ok $f->check_raw('N');
        ok $f->check_raw('C');
        ok $f->check_raw('R');

        ok !$f->check(undef);
        ok !$f->check('NEw');
        ok !$f->check('something else');
        ok !$f->check_raw('X');

    };
};

subtest "INT" => sub {
    subtest "w/o enumerations" => sub {
        my $f = Protocol::FIX::Field->new(68, 'TotNoOrders', 'INT');
        is $f->serialize(5), '68=5';
        ok $f->check(5);
        ok $f->check(-5);

        ok !$f->check("+5");
        ok !$f->check("abc");
        ok !$f->check("");
        ok !$f->check(undef);
    };

    subtest "with enumerations" => sub {
        my $f = Protocol::FIX::Field->new(
            87,
            'AllocStatus',
            'INT',
            {
                0 => 'ACCEPTED',
                1 => 'BLOCK_LEVEL_REJECT',
            });
        is $f->serialize('ACCEPTED'),           '87=0';
        is $f->serialize('BLOCK_LEVEL_REJECT'), '87=1';
        ok $f->check('ACCEPTED');

        ok !$f->check(0);
        ok !$f->check(1);
        ok !$f->check("");
        ok !$f->check(undef);
    };
};

subtest "LENGTH" => sub {
    my $f = Protocol::FIX::Field->new(90, 'SecureDataLen', 'LENGTH');
    is $f->serialize(3), '90=3';
    ok $f->check(5);
    ok $f->check(55);

    ok !$f->check(0);
    ok !$f->check(-5);
    ok !$f->check("abc");
    ok !$f->check("");
    ok !$f->check(undef);
};

subtest "DATA" => sub {
    my $f = Protocol::FIX::Field->new(91, 'SecureData', 'DATA');
    is $f->serialize('abc==='), '91=abc===';
    ok $f->check('a');
    ok $f->check("\x01");
    ok $f->check(0);

    ok !$f->check("");
    ok !$f->check(undef);
};

subtest "FLOAT" => sub {
    my $f = Protocol::FIX::Field->new(520, 'ContAmtValue', 'FLOAT');

    ok $f->check(0);
    ok $f->check(3.14);
    ok $f->check(-5);
    ok $f->check("00023.23");
    ok $f->check("23.0000");
    ok $f->check("-23.0");
    ok $f->check("23.0");

    ok !$f->check("22.2.2");
    ok !$f->check("+1");
    ok !$f->check("abc");
    ok !$f->check("");
    ok !$f->check(undef);

    is $f->serialize('10.00001'), '520=10.00001';

};

subtest "CHAR" => sub {
    my $f = Protocol::FIX::Field->new(13, 'CommType', 'CHAR');

    ok $f->check(0);
    ok $f->check(5);
    ok $f->check('A');
    ok $f->check('a');

    ok !$f->check("ab");
    ok !$f->check('=');
    ok !$f->check("");
    ok !$f->check(undef);

    is $f->serialize('z'), '13=z';
};

subtest "CURRENCY" => sub {
    my $f = Protocol::FIX::Field->new(521, 'ContAmtCurr', 'CURRENCY');

    ok $f->check('USD');
    ok $f->check('JPY');
    ok $f->check('BYN');
    ok $f->check('RUB');

    ok !$f->check("USDJPY");
    ok !$f->check("");
    ok !$f->check(undef);

    is $f->serialize('BYN'), '521=BYN';
};

subtest "UTCTIMESTAMP" => sub {
    my $f = Protocol::FIX::Field->new(5, 'f', 'UTCTIMESTAMP');

    ok $f->check('19981231-23:59:59');
    ok $f->check('19981231-23:59:59.123');

    ok !$f->check('19981231-23:59:59.1234');
    ok !$f->check('1998123-23:59:59.123');
    ok !$f->check('19981231-25:59:59');
    ok !$f->check('19981231-24:79:59');
    ok !$f->check('19981232-22:59:59');
    ok !$f->check('19981331-21:59:59');
    ok !$f->check(undef);
};

subtest "BOOLEAN" => sub {
    my $f = Protocol::FIX::Field->new(5, 'f', 'BOOLEAN');
    ok $f->check('Y');
    ok $f->check('N');

    ok !$f->check('y');
    ok !$f->check('no');
    ok !$f->check(1);
};

subtest "LOCALMKTDATE" => sub {
    my $f = Protocol::FIX::Field->new(5, 'f', 'LOCALMKTDATE');
    ok $f->check('19981231');
    ok !$f->check('199812311');
    ok !$f->check('19981331');
};

subtest "LOCALMKTDATE" => sub {
    my $f = Protocol::FIX::Field->new(5, 'f', 'MONTHYEAR');
    ok $f->check('199812');
    ok $f->check('19981210');
    ok $f->check('199812w1');
    ok $f->check('199812w6');

    ok !$f->check('19981232');
    ok !$f->check('199812w7');
};

subtest "UTCTIMEONLY" => sub {
    my $f = Protocol::FIX::Field->new(5, 'f', 'UTCTIMEONLY');
    ok $f->check('11:12:55');
    ok $f->check('11:12:55.123');

    ok !$f->check('25:12:55.123');
    ok !$f->check('11:61:55.123');
    ok !$f->check('11:12:62.123');
    ok !$f->check('11:12:55.1234');
    ok !$f->check(undef);
    ok !$f->check("");
};

subtest "COUNTRY" => sub {
    my $f = Protocol::FIX::Field->new(5, 'f', 'COUNTRY');
    ok $f->check('RU');
    ok $f->check('BY');
    ok $f->check('US');

    ok !$f->check(undef);
    ok !$f->check("");
    ok !$f->check("abc");
    ok !$f->check("12");
};

done_testing;
