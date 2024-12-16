use Test2::V0;

use Syntax::Keyword::Assert;

subtest 'Test `unimport`' => sub {
    ok lives {
        assert( 1 );
    };

    no Syntax::Keyword::Assert;

    ok dies {
        assert( 1 );
    }, 'unimported assert';
};

done_testing;
