package MyTestBase;

use strict;
use warnings;

use Test::Class::Filter::Tags;

use base qw( Test::Class );

package Base;

use strict;
use warnings;

use Test::More;

use base qw( MyTestBase );

our @run;

sub setup : Test( setup ) {
}

sub foo : Tests Tags( foo ) {
}

sub wibble : Tests {
}

package SubClass;

use base qw( Base );

sub bar : Tests Tags( bar ) {
    push @run, "bar";
}

package SubSubClass;

use base qw( SubClass );

sub foo : Tests Tags( bar ) {
}

package main;

use Test::More tests => 5;

# no filter
{
    my $c = 'Test::Class::Filter::Tags';

    is( $c->method_has_tag( Base => foo => 'foo' ),
        1,
        "method has tag, when set on class's method"
    );

    is( $c->method_has_tag( Base => foo => 'bar' ),
        0,
        "method doesn't have tag, when tag set only in subclass"
    );

    is( $c->method_has_tag( SubSubClass => foo => 'bar' ),
        1,
        "method has tag, when tag set on subclass for subclass"
    );

    is( $c->method_has_tag( SubSubClass => foo => 'foo' ),
        1,
        "method has tag, when tag set on baseclass for subclass"
    );

    is( $c->method_has_tag( SubSubClass => wibble => 'foo' ),
        0,
        "method doesn't has tag, when no tags set for it anywhere in hierarchy"
    );
}
