use strict;
use Test::More 0.98;
use Test::Exception;

use_ok 'Sqids';

subtest 'simple' => sub {
    my $sqids = Sqids->new;

    my @numbers = (1, 2, 3);
    my $id = '86Rf07';

    is $sqids->encode(@numbers), $id;
    is_deeply [ $sqids->decode($id) ], \@numbers;
};

subtest 'different inputs' => sub {
    my $sqids = Sqids->new();

    my $numbers = [0, 0, 0, 1, 2, 3, 100, 1_000, 100_000, 1_000_000];
    is_deeply [ $sqids->decode($sqids->encode($numbers)) ], $numbers;
};

subtest 'incremental numbers' => sub {
    my $sqids = Sqids->new();

    my $ids = {
        bM => 0,
        Uk => 1,
        gb => 2,
        Ef => 3,
        Vq => 4,
        uw => 5,
        OI => 6,
        AX => 7,
        p6 => 8,
        nJ => 9
    };

    foreach (keys %$ids) {
        is $sqids->encode($ids->{$_}), $_;
        is $sqids->decode($_), $ids->{$_};
    }
};

subtest 'incremental numbers, same index 0' => sub {
    my $sqids = Sqids->new();

    my $ids = {
        SvIz => [0, 0],
        n3qa => [0, 1],
        tryF => [0, 2],
        eg6q => [0, 3],
        rSCF => [0, 4],
        sR8x => [0, 5],
        uY2M => [0, 6],
        '74dI' => [0, 7],
        '30WX' => [0, 8],
        moxr => [0, 9]
    };

    foreach (keys %$ids) {
        is $sqids->encode($ids->{$_}), $_;
        is_deeply [ $sqids->decode($_) ], $ids->{$_};
    }
};

subtest 'incremental numbers, same index 1' => sub {
    my $sqids = Sqids->new();

    my $ids = {
        SvIz => [0, 0],
        nWqP => [1, 0],
        tSyw => [2, 0],
        eX68 => [3, 0],
        rxCY => [4, 0],
        sV8a => [5, 0],
        uf2K => [6, 0],
        '7Cdk' => [7, 0],
        '3aWP' => [8, 0],
        m2xn => [9, 0]
    };

    foreach (keys %$ids) {
        is $sqids->encode($ids->{$_}), $_;
        is_deeply [ $sqids->decode($_) ], $ids->{$_};
    }
};

subtest 'multi input' => sub {
    my $sqids = Sqids->new();

    my $numbers = [
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
        26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
        50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73,
        74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97,
        98, 99
    ];
    my @output = $sqids->decode($sqids->encode($numbers));
    is_deeply $numbers, \@output;
};

subtest 'encoding no numbers' => sub {
    my $sqids = Sqids->new();
    is $sqids->encode(), '';
};

subtest 'decoding empty string' => sub {
    my $sqids = Sqids->new();
    is_deeply [ $sqids->decode('') ], [];
};

# Changed to double * as single star decodes okay with checking code commented out
subtest 'decoding an ID with an invalid character' => sub {
    my $sqids = Sqids->new();
    is_deeply [ $sqids->decode('**') ], [];
};

subtest 'encode out-of-range numbers' => sub {
    my $encoding_error = 'Encoding only supports non-negative numbers';

    my $sqids = Sqids->new();
    throws_ok {
        $sqids->encode(-1)
    } qr/$encoding_error/;
};

done_testing;

