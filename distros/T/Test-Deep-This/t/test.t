use strict;

use Test::Tester;

use Test::More;
use Test::Deep;

use lib 'lib';
use Test::Deep::This;

check_test(
    sub {
        cmp_deeply([0, 1], [!this, this]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        cmp_deeply([5, 6], [abs (this - 4) < 2, 10 - sqrt(this) < this * 2]);
    },
    {
        ok => 1,
    }
);

check_test(
    sub {
        cmp_deeply({ a => 4 }, { a => 10 - sqrt(this) < this * 2 });
    },
    {
        ok => 0,
        diag => qq#Compared \$data->{"a"}\n   got : '4'\nexpect : ((10) - (sqrt (<<this>>))) < ((<<this>>) * (2))#, 
    }
);

check_test(
    sub {
        cmp_deeply(["123"], [re(qr/^\d+(\d)$/, [this < 4]) & (this > 100)]);
    },
    {
        ok => 1,
    }
);

done_testing();
