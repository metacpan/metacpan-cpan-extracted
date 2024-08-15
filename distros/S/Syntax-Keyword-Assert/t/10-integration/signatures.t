use Test2::V0;
use Test2::Require::Perl 'v5.36';

use feature qw(signatures);

BEGIN {
    $ENV{PERL_STRICT} = 1;
}

use Syntax::Keyword::Assert;

subtest 'Test `assert` with signatures' => sub {

    my sub hello($name) {
        assert { defined $name };
        return "Hello, $name!";
    }

    ok lives {
        hello('world');
    };

    ok dies {
        hello();
    };
};

done_testing;
