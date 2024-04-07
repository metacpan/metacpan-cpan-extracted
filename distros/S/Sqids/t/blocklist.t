use strict;
use Test::More 0.98;
use Test::Exception;

use_ok 'Sqids';

subtest 'if no custom blocklist param, use the default blocklist' => sub {
    my $sqids = Sqids->new;
    is $sqids->decode('aho1e'), 4572721;
    is $sqids->encode(4572721), 'JExTR';
};

subtest "if an empty blocklist param passed, don't use any blocklist" => sub {
    my $sqids = Sqids->new({ blocklist => [] });
    is $sqids->decode('aho1e'), 4572721;
    is $sqids->encode(4572721), 'aho1e';
};

subtest 'if a non-empty blocklist param passed, use only that' => sub {
    my $sqids = Sqids->new({ blocklist => ['ArUO'] });
    # make sure we don't use the default blocklist
    is $sqids->decode('aho1e'), 4572721;
    is $sqids->encode(4572721), 'aho1e';
    # make sure we are using the passed blocklist
    is $sqids->decode('ArUO'), 100000;
    is $sqids->encode(100000), 'QyG4';
    is $sqids->decode('QyG4'), 100000;
};

subtest 'blocklist' => sub {
    my $sqids = Sqids->new({
        blocklist => [
            'JSwXFaosAN', # normal result of 1st encoding, let's block that word on purpose
            'OCjV9JK64o', # result of 2nd encoding
            'rBHf', # result of 3rd encoding is `4rBHfOiqd3`, let's block a substring
            '79SM', # result of 4th encoding is `dyhgw479SM`, let's block the postfix
            '7tE6' # result of 4th encoding is `7tE6jdAHLe`, let's block the prefix
        ]
    });
    is $sqids->encode(1_000_000, 2_000_000), '1aYeB7bRUt';
    is_deeply [ $sqids->decode('1aYeB7bRUt') ], [1_000_000, 2_000_000];
};

subtest 'decoding blocklist words should still work' => sub {
    my $sqids = Sqids->new({
        blocklist => ['86Rf07', 'se8ojk', 'ARsz1p', 'Q8AI49', '5sQRZO']
    });

    is_deeply [ $sqids->decode('86Rf07') ], [1, 2, 3];
    is_deeply [ $sqids->decode('se8ojk') ], [1, 2, 3];
    is_deeply [ $sqids->decode('ARsz1p') ], [1, 2, 3];
    is_deeply [ $sqids->decode('Q8AI49') ], [1, 2, 3];
    is_deeply [ $sqids->decode('5sQRZO') ], [1, 2, 3];
};

subtest 'match against a short blocklist word' => sub {
    my $sqids = Sqids->new({
        blocklist => ['pnd']
    });

    is $sqids->decode($sqids->encode(1000)), 1000;
};

subtest 'blocklist filtering in constructor' => sub {
    my $sqids = Sqids->new({
        alphabet => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        blocklist => ['sxnzkl'] # lowercase blocklist in only-uppercase alphabet
    });

    my $id = $sqids->encode(1, 2, 3);
    my @numbers = $sqids->decode($id);

    is $id, 'IBSHOZ'; # without blocklist, would've been "SXNZKL"
    is_deeply \@numbers, [1, 2, 3];
};

subtest 'max encoding attempts' => sub {
    my $alphabet = 'abc';
    my $min_length = 3;
    my $blocklist = ['cab', 'abc', 'bca'];

    my $sqids = Sqids->new({
        alphabet => $alphabet,
        min_length => $min_length,
        blocklist => $blocklist,
    });

    is length $alphabet, $min_length;
    is @$blocklist, $min_length;

    throws_ok {
        $sqids->encode(0)
    } qr/Reached max attempts to re-generate the ID/;
};

done_testing;
