package PVTests::Regex_Array;

use strict;
use warnings;

use Params::Validate::Array qw(:all);

use PVTests;
use Test::More;

sub run_tests {
    plan tests => 7;

    eval {
        my @a = ( foo => 'bar' );
        validate( @a, [ foo => { regex => '^bar$' } ] );
    };
    is( $@, q{} );

    eval {
        my @a = ( foo => 'bar' );
        validate( @a, [ foo => { regex => qr/^bar$/ } ] );
    };
    is( $@, q{} );

    eval {
        my @a = ( foo => 'baz' );
        validate( @a, [ foo => { regex => '^bar$' } ] );
    };

    if ( $ENV{PERL_NO_VALIDATION} ) {
        is( $@, q{} );
    }
    else {
        like( $@, qr/'foo'.+did not pass regex check/ );
    }

    eval {
        my @a = ( foo => 'baz' );
        validate( @a, [ foo => { regex => qr/^bar$/ } ] );
    };

    if ( $ENV{PERL_NO_VALIDATION} ) {
        is( $@, q{} );
    }
    else {
        like( $@, qr/'foo'.+did not pass regex check/ );
    }

    eval {
        my @a = ( foo => 'baz', bar => 'quux' );
        validate(
            @a, [
                foo => { regex => qr/^baz$/ },
                bar => { regex => 'uqqx' },
            ]
        );
    };

    if ( $ENV{PERL_NO_VALIDATION} ) {
        is( $@, q{} );
    }
    else {
        like( $@, qr/'bar'.+did not pass regex check/ );
    }

    eval {
        my @a = ( foo => 'baz', bar => 'quux' );
        validate(
            @a, [
                foo => { regex => qr/^baz$/ },
                bar => { regex => qr/^(?:not this|quux)$/ },
            ]
        );
    };
    is( $@, q{} );

    eval {
        my @a = ( foo => undef );
        validate( @a, [ foo => { regex => qr/^$|^bubba$/ } ] );
    };
    is( $@, q{} );
}

1;
##### SUBROUTINE INDEX #####
#                          #
#   gen by index_subs.pl   #
#   on 24 Feb 2014 21:03   #
#                          #
############################


####### Packages ###########

# PVTests::Regex_Array ............ 1
#   run_tests ..................... 1

