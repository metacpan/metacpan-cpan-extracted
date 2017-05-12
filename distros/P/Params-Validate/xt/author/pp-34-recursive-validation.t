BEGIN {
    $ENV{PV_TEST_PERL} = 1;
}

use strict;
use warnings;

use Test::Fatal;
use Test::More;

{
    package Foo;

    use Params::Validate qw( validate SCALAR );

    Params::Validate::validation_options( allow_extra => 1 );

    sub test_foo {
        my %p = validate( @_, { arg1 => { type => SCALAR } } );
        print "test foo\n";
    }
}

{
    package Bar;

    use Params::Validate qw( validate SCALAR );
    Params::Validate::validation_options( allow_extra => 0 );

    sub test_bar {

        # catch die signal
        local $SIG{__DIE__} = sub {

            # we died from within Params::Validate (because of wrong_Arg) we
            # call Foo::test_foo with OK args, but it'll die, because
            # Params::Validate::PP::options is still set to the options of the
            # Bar package, and so it won't retreive the one from Foo.
            Foo::test_foo( arg1 => 1, extra_arg => 2 );
        };

        # this will die because the arg received is 'wrong_arg'
        my %p = validate( @_, { arg1 => { type => SCALAR } } );
    }
}

{
    # This bug only manifests with the pure Perl code because of its use of local
    # to remember the per-package options.
    local $TODO = 'Not sure how to fix this one';
    unlike(
        exception { Bar::test_bar( bad_arg => 2 ) },
        qr/was passed in the call to Foo::test_foo/,
        'no exception from Foo::test_foo when when calling validate() from within a __DIE__ handler'
    );
}

done_testing();

