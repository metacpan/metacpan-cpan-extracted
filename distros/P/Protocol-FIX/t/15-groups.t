use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Warnings;

use Protocol::FIX qw/humanize/;
use Protocol::FIX::Field;
use Protocol::FIX::Group;

subtest "simple case :: NoRoutingIDs" => sub {
    my $f_0 = Protocol::FIX::Field->new(215, 'NoRoutingIDs', 'NUMINGROUP');
    my $f_1 = Protocol::FIX::Field->new(
        216,
        'RoutingType',
        'INT',
        {
            1 => 'TARGET_FIRM',
            2 => 'TARGET_LIST',
            3 => 'BLOCK_FIRM',
            4 => 'BLOCK_LIST',
        });
    my $f_2 = Protocol::FIX::Field->new(217, 'RoutingID', 'STRING');
    my $g   = Protocol::FIX::Group->new(
        $f_0,
        [
            $f_1 => 0,
            $f_2 => 0
        ]);
    ok $g;

    is $g->{name}, 'NoRoutingIDs';

    is humanize(
        $g->serialize([[
                    RoutingType => 'TARGET_FIRM',
                    RoutingID   => 'binary.com'
                ]])
        ),
        '215=1 | 216=1 | 217=binary.com';

    is humanize(
        $g->serialize([[
                    RoutingType => 'TARGET_FIRM',
                    RoutingID   => 'binary.com'
                ],
                [
                    RoutingType => 'BLOCK_FIRM',
                    RoutingID   => 'champion-fx.com'
                ],
            ])
        ),
        '215=2 | 216=1 | 217=binary.com | 216=3 | 217=champion-fx.com';

    like exception { $g->serialize() }, qr/repetitions must be ARRAY/;
    like exception { $g->serialize([]) }, qr/repetitions must be non-empty/;
    like exception { $g->serialize([[RoutingType => 'WRONG_VALUE']]) }, qr/The value 'WRONG_VALUE' is not acceptable for field RoutingType/;
};

subtest "artificial :: DATA & LENGTH field combination" => sub {
    my $f_0 = Protocol::FIX::Field->new(1000, 'NoArtificialIDs', 'NUMINGROUP');
    my $f_1 = Protocol::FIX::Field->new(90,   'SecureDataLen',   'LENGTH');
    my $f_2 = Protocol::FIX::Field->new(91,   'SecureData',      'DATA');

    like exception { Protocol::FIX::Group->new($f_0, [$f_2 => 0]); }, qr/The field type 'LENGTH' must appear before field SecureData/;
    my $g = Protocol::FIX::Group->new(
        $f_0,
        [
            $f_1 => 0,
            $f_2 => 0
        ]);
    ok $g;

    is humanize(
        $g->serialize([[
                    SecureDataLen => 5,
                    SecureData    => '12345'
                ]])
        ),
        '1000=1 | 90=5 | 91=12345';

    like exception { $g->serialize([[SecureData => '12345']]) }, qr/The field 'SecureDataLen' must precede 'SecureData'/;

    like exception { $g->serialize([[SecureDataLen => 5, SecureData => 'abcd']]) },
        qr/\QThe length field 'SecureDataLen' (4) isn't equal previously declared (5)\E/;
};

subtest "mandatory & optional fields :: NoLinesOfText" => sub {
    my $f_0 = Protocol::FIX::Field->new(33,  'NoLinesOfText',  'NUMINGROUP');
    my $f_1 = Protocol::FIX::Field->new(58,  'Text',           'STRING');
    my $f_2 = Protocol::FIX::Field->new(354, 'EncodedTextLen', 'LENGTH');
    my $f_3 = Protocol::FIX::Field->new(355, 'EncodedText',    'DATA');

    my $g = Protocol::FIX::Group->new(
        $f_0,
        [
            $f_1 => 1,
            $f_2 => 0,
            $f_3 => 0
        ]);

    is humanize(
        $g->serialize([[
                    Text           => 'abc',
                    EncodedTextLen => 1,
                    EncodedText    => 'Z'
                ]])
        ),
        '33=1 | 58=abc | 354=1 | 355=Z';

    is humanize($g->serialize([[Text => 'abc']])), '33=1 | 58=abc';

    like exception { $g->serialize([[EncodedTextLen => 1, EncodedText => 'Z']]) }, qr/'Text' is mandatory for group 'NoLinesOfText'/;
};

done_testing;
