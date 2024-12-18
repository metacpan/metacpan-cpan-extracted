use Test2::V0;

use Syntax::Keyword::Assert;

use lib 't/lib';
use TestUtil;

subtest 'Test `assert` keyword' => sub {
    ok lives { assert(1) };
    ok lives { assert("hello") };
    like dies { assert(undef) }, expected_assert('undef');
    like dies { assert(0) },     expected_assert('0');
    like dies { assert('0') },   expected_assert('"0"');
    like dies { assert('') },    expected_assert('""');
    like dies { assert(!!0) }, expected_assert('false');
};

done_testing;
