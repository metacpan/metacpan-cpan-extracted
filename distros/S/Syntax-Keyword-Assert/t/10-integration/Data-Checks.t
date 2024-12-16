use Test2::V0;
use Test2::Require::Module 'Data::Checks', '0.09';

use Syntax::Keyword::Assert;
use Data::Checks qw( Str );

subtest 'Test `assert` with Data::Checks' => sub {
    ok lives {
        assert ( Str->check('hello') );
    };

    ok dies {
        assert ( Str->check({}) );
    };
};

done_testing;
