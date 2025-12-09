use Test2::V0;
use Test2::Require::Perl 'v5.38'; # Syntax::Operator::Is requires Perl v5.38+ for custom infix operators
use Test2::Require::Module 'Syntax::Operator::Is', '0.02';
use Test2::Require::Module 'Data::Checks', '0.09';

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
