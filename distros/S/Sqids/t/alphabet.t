use utf8;
use strict;
use Test::More 0.98;
use Test::Exception;

use_ok 'Sqids';

subtest simple => sub {
    my $sqids = Sqids->new(alphabet => '0123456789abcdef');
    my @numbers = (1, 2, 3);
    my $id = '489158';

    is $sqids->encode(@numbers), $id;
    is_deeply [ $sqids->decode($id) ], \@numbers;
};

subtest 'short alphabet' => sub {
    my $sqids = Sqids->new({ alphabet => 'abc' });
    my @numbers = (1, 2, 3);
    is_deeply [ $sqids->decode($sqids->encode(@numbers)) ], \@numbers;
};

subtest 'long alphabet' => sub {
    my $sqids = Sqids->new(
        alphabet => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+|{}[];:\'"/?.>,<`~'
    );
    my @numbers = (1, 2, 3);
    is_deeply [ $sqids->decode($sqids->encode(@numbers)) ], \@numbers;
};

subtest 'multibyte characters' => sub {
    throws_ok {
        Sqids->new({ alphabet => 'ë1092' });
    } qr/Alphabet cannot contain multibyte characters/;
};

subtest 'repeating alphabet characters' => sub {
    throws_ok {
        Sqids->new({ alphabet => 'aabcdefg' });
    } qr/Alphabet must contain unique characters/;
};

subtest 'too short of an alphabet' => sub {
    throws_ok {
        Sqids->new({ alphabet => 'ab' });
    } qr/Alphabet length must be at least 3/;
};

done_testing;
