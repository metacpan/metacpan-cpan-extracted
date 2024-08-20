use Test2::V0;

BEGIN {
    $ENV{PERL_STRICT} = 1;
}

use Syntax::Keyword::Assert;

subtest 'Test `assert` keyword with STRICT enabled' => sub {
    like dies {
        assert { 0 };
    }, qr/\AAssertion failed/;

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

    like dies {
        $hello->(undef);
    }, qr/\AAssertion failed/;

    like dies {
        assert {
            my $x = 1;
            my $y = 2;
            $x + $y == 100;
        };
    }, qr/\AAssertion failed/, 'assert block with multiple statements';

};

subtest 'Test `assert` with Carp::Verbose' => sub {
    subtest 'When Carp::Verbose is enabled' => sub {
        my $error = dies {
            assert {
                local $Carp::Verbose = 1;
                0;
            }
        };
        my @errors = split /\n/, $error;
        ok @errors > 1;
    };

    subtest 'When Carp::Verbose is disabled' => sub {
        my $error = dies {
            assert { 0 } # Default is Carp::Verbose = 0
        };
        my @errors = split /\n/, $error;
        is @errors, 1;
    };
};

done_testing;
