use Test2::V0;
use Syntax::Keyword::Assert;

use lib 't/lib';
use TestUtil;

subtest 'NUM_EQ' => sub {
    my $x = 1;
    my $y = 2;
    ok lives { assert($x + $y == 3) };

    is dies { assert($x + $y == 100) }, expected_assert_bin(3, '==', 100);
    is dies { assert($x == 100) },      expected_assert_bin(1, '==', 100);

    is dies { assert(!!$x == 100) }, expected_assert_bin('true',  '==', 100);
    is dies { assert(!$x == 100) },  expected_assert_bin('false', '==', 100);

    my $message = 'hello';
    my $undef   = undef;

    my $warnings = warnings {
        is dies { assert($message == 100) }, expected_assert_bin('"hello"', '==', 100);
        is dies { assert($undef == 100) },   expected_assert_bin('undef',   '==', 100);
    };

    # suppressed warnings
    is scalar @$warnings, 2;
};

subtest 'NUM_NE' => sub {
    my $x = 2;
    ok lives { assert($x != 1) };
    is dies { assert($x != 2) }, expected_assert_bin(2, '!=', 2);
};

subtest 'NUM_LT' => sub {
    my $x = 2;
    is dies { assert($x < 1) }, expected_assert_bin(2, '<', 1);
    is dies { assert($x < 2) }, expected_assert_bin(2, '<', 2);
    ok lives { assert($x < 3) };

    my $x2 = 2.01;
    is dies { assert($x2 < 2) },    expected_assert_bin(2.01, '<', 2);
    is dies { assert($x2 < 2.01) }, expected_assert_bin(2.01, '<', 2.01);
    ok lives { assert($x2 < 3) };

    my $x3 = -1;
    ok lives { assert($x3 < 0) };
    is dies { assert($x3 < -1) }, expected_assert_bin(-1, '<', -1);
    is dies { assert($x3 < -2) }, expected_assert_bin(-1, '<', -2);

    my $x4 = -1.01;
    ok lives { assert($x4 < 0) };
    is dies { assert($x4 < -1.01) }, expected_assert_bin(-1.01, '<', -1.01);
    is dies { assert($x4 < -2) },    expected_assert_bin(-1.01, '<', -2);
};

subtest 'NUM_GT' => sub {
    my $x = 2;
    ok lives { assert($x > 1) };
    is dies { assert($x > 2) }, expected_assert_bin(2, '>', 2);
    is dies { assert($x > 3) }, expected_assert_bin(2, '>', 3);

    my $x2 = 2.01;
    ok lives { assert($x2 > 2) };
    is dies { assert($x2 > 2.01) }, expected_assert_bin(2.01, '>', 2.01);
    is dies { assert($x2 > 3) },    expected_assert_bin(2.01, '>', 3);

    my $x3 = -1;
    is dies { assert($x3 > 0) },  expected_assert_bin(-1, '>',  0);
    is dies { assert($x3 > -1) }, expected_assert_bin(-1, '>', -1);
    ok lives { assert($x3 > -2) };

    my $x4 = -1.01;
    is dies { assert($x4 > 0) },     expected_assert_bin(-1.01, '>',  0);
    is dies { assert($x4 > -1.01) }, expected_assert_bin(-1.01, '>', -1.01);
    ok lives { assert($x4 > -2) };
};

subtest 'NUM_LE' => sub {
    my $x = 2;
    is dies { assert($x <= 1) }, expected_assert_bin(2, '<=', 1);
    ok lives { assert($x <= 2) };
    ok lives { assert($x <= 3) };
};

subtest 'NUM_GE' => sub {
    my $x = 2;
    ok lives { assert($x >= 1) };
    ok lives { assert($x >= 2) };
    is dies { assert($x >= 3) }, expected_assert_bin(2, '>=', 3);
};

done_testing;
