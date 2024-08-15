use Test2::V0;

BEGIN {
    # Disable STRICT mode. SEE ALSO: Devel::StrictMode
    $ENV{EXTENDED_TESTING} = 0;
    $ENV{AUTHOR_TESTING}   = 0;
    $ENV{RELEASE_TESTING}  = 0;
    $ENV{PERL_STRICT}      = 0;
}

use Syntax::Keyword::Assert;

subtest 'Test `assert` keyword with STRICT disabled' => sub {
    ok lives {
        assert { 0 };
    };

    ok lives {
        assert { 1 };
    };

    my $hello = sub {
        my ($message) = @_;
        assert { defined $message };
        return "Hello, $message!";
    };

    ok lives {
        $hello->('world');
    };

    like warning {
        $hello->(undef);
    }, qr/\AUse of uninitialized value \$message in concatenation/;
};

done_testing;
