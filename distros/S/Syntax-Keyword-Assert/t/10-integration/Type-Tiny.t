use Test2::V0;
use Test2::Require::Module 'Type::Tiny', '2.000000';

use Syntax::Keyword::Assert;
use Types::Standard -types;

subtest 'Test `assert` with Type::Tiny' => sub {
    ok lives {
        assert ( Str->check('hello') );
    };

    ok dies {
        assert ( Str->check({}) );
    };
};

done_testing;
