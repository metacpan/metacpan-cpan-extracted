use Test2::V0;

use Syntax::Keyword::Assert;

subtest 'Test `assert` keyword' => sub {
    like dies {
        assert( 0 );
    }, qr/\AAssertion failed/;

    ok lives {
        assert( 1 );
    };

    my $hello = sub {
        my ($message) = @_;
        assert( defined $message );
        return "Hello, $message!";
    };

    ok lives { $hello->('world') };
    ok dies { $hello->(undef) };

    like dies { assert( undef ) }, qr/\AAssertion failed \(undef\)/;
    like dies { assert( 0 ) }, qr/\AAssertion failed \(0\)/;
    like dies { assert( '0' ) }, qr/\AAssertion failed \("0"\)/;
    like dies { assert( '' ) }, qr/\AAssertion failed \(""\)/;

    my $false = $] >= 5.036 ? 'false' : '""';
    like dies { assert( !1 ) }, qr/\AAssertion failed \($false\)/;
};

subtest 'Test `assert(binary)` keyword' => sub {

    subtest 'NUM_EQ' => sub {
        my $x = 1;
        my $y = 2;
        ok lives { assert( $x + $y == 3 ) };

        like dies { assert( $x + $y == 100 ) },   qr/\AAssertion failed \(3 == 100\)/;
        like dies { assert( $x == 100 ) },        qr/\AAssertion failed \(1 == 100\)/;

        my $true = $] >= 5.036 ? 'true' : '"1"';
        my $false = $] >= 5.036 ? 'false' : '""';
        like dies { assert( !!$x == 100 ) },        qr/\AAssertion failed \($true == 100\)/;
        like dies { assert( !$x == 100 ) },        qr/\AAssertion failed \($false == 100\)/;

        my $message = 'hello';
        my $undef = undef;

        my $warnings = warnings {
            like dies { assert( $message == 100 ) },  qr/\AAssertion failed \("hello" == 100\)/;
            like dies { assert( $undef == 100 ) },    qr/\AAssertion failed \(undef == 100\)/;
        };
        # suppressed warnings
        is scalar @$warnings, 2;
    };

    subtest 'NUM_NE' => sub {
        my $x = 2;
        ok lives { assert( $x != 1 ) };
        like dies { assert( $x != 2 ) }, qr/\AAssertion failed \(2 != 2\)/;
    };

    subtest 'STR_EQ' => sub {
        my $message = 'hello';

        ok lives { assert( $message eq 'hello' ) };
        like dies { assert( $message eq 'world' ) }, qr/\AAssertion failed \("hello" eq "world"\)/;

        my $x = 1;
        my $undef = undef;

        my $got = $] >= 5.036 ? '1' : '"1"';
        like dies { assert( $x eq 'world' ) }, qr/\AAssertion failed \($got eq "world"\)/;

        my $warnings = warnings {
            like dies { assert( $undef eq 'world' ) },   qr/\AAssertion failed \(undef eq "world"\)/;
        };
        # suppressed warnings
        is scalar @$warnings, 1;
    };

    subtest 'STR_NE' => sub {
        my $message = 'hello';
        ok lives { assert( $message ne 'world' ) };
        like dies { assert( $message ne 'hello' ) }, qr/\AAssertion failed \("hello" ne "hello"\)/;
    };
};

done_testing;
