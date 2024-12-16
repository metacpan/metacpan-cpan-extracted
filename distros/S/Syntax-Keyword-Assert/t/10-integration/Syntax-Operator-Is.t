use Test2::V0;
use Test2::Require::Module 'Syntax::Operator::Is', '0.02';
use Test2::Require::Module 'XS::Parse::Infix', '0.44';

use Syntax::Keyword::Assert;
use Syntax::Operator::Is is => { -as => "is_" };
use Data::Checks qw( Str );

subtest 'Test `assert` with Syntax::Operator::Is' => sub {
    ok lives {
        assert ( 'hello' is_ Str );
    };

    ok dies {
        assert ( {} is_ Str );
    };
};

done_testing;
