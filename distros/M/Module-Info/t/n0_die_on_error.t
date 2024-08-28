#!/usr/bin/perl -w

use strict;
use lib './t/lib';
use Test::More tests => 4;
use lib '.';
use Module::Info;

my $baz = Module::Info->new_from_module( 'Baz' );
my $bar = Module::Info->new_from_module( 'Foo' );

SKIP: {
    skip "Only works on 5.6.1 and up.", 4 unless $] >= 5.006001;

    # Bar.pm should compile correctly
    $bar->die_on_compilation_error(1);
    eval {
        $bar->packages_inside;
    };
    ok( !$@, "does not die if compilation is ok" );
    diag( $@ ) if $@;

    {
        # suppress warning message
        local $SIG{__WARN__} = sub { };

        eval {
            $baz->packages_inside;
        };
        ok( !$@, "does not die unless die_on_compilation_error is set" );
        diag( $@ ) if $@;
    }

    {
        my $did_warn;
        local $SIG{__WARN__} = sub { $did_warn = 1 };
        $baz->die_on_compilation_error(1);

        eval {
            $baz->packages_inside;
        };
        ok( $@, "dies if die_on_compilation_error is set" );
        ok( !$did_warn, "does not warn if die_on_compilation_error is set" );
    }
}
