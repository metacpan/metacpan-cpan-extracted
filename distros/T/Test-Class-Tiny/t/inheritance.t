#!/usr/bin/perl

package t::inheritance;

use Test2::V0;

use parent -norequire => ('t::Foo', 't::Bar');

if (!caller) {
    __PACKAGE__->runtests();
    done_testing();
}

#----------------------------------------------------------------------

package t::Foo;

use Test2::V0;

use parent qw( Test::Class::Tiny );

sub T1_test1 {
    ok 1;
}

#----------------------------------------------------------------------

package t::Bar;

use Test2::V0;

use parent qw( Test::Class::Tiny );

sub T1_test2 {
    ok 1;
}

1;
