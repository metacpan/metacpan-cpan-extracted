#!/usr/bin/env perl

use Test::More;

use strict;
use Rubyish::Syntax::class;

# declare a new package when current namespace is 'main'
class Baz {
    # Test::More::diag "Hello from ",__PACKAGE__,"\n";

    def baz { "Baz class is declared in main package" }
};

# declare a new package when current namepsace is not 'main'
package Foo;
use Rubyish::Syntax::class;

class Bar {
    # Test::More::diag "Hello from ",__PACKAGE__,"\n";

    def bar { "Bar class is declared after 'package Foo';" }
};

package main;

plan tests => 4;

ok( Bar->can("new") );
ok( Baz->can("new") );

ok( Bar->can("bar") );
ok( Baz->can("baz") );


# use Devel::Symdump;
# print "$_\n" for Devel::Symdump->new('main', 'Foo')->functions;
