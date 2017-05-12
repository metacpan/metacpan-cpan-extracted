use strict;
use warnings;
use Test::More;
use lib 't/fun/lib';

BEGIN {
    if (!eval { require Sub::Name }) {
        plan skip_all => "This test requires Sub::Name";
    }
}

use Carp;

my $file = __FILE__;
my $line = __LINE__;

{
    package Foo;
    use Fun;
    fun foo ($x, $y) {
        Carp::confess "$x $y";
    }

    eval {
        foo("abc", "123");
    };

    my $line_confess = $line + 6;
    my $line_foo = $line + 10;

    ::like($@, qr/^abc 123 at $file line $line_confess\.?\n\tFoo::foo\(['"]abc['"], 123\) called at $file line $line_foo/);
}

SKIP: { skip "Sub::Name required", 1 unless eval { require Sub::Name };

{
    package Bar;
    use Fun;
    *bar = Sub::Name::subname(bar => fun ($a, $b) { Carp::confess($a + $b) });

    eval {
        bar(4, 5);
    };

    my $line_confess = $line + 24;
    my $line_bar = $line + 27;

    ::like($@, qr/^9 at $file line $line_confess\.?\n\tBar::bar\(4, 5\) called at $file line $line_bar/);
}

}

done_testing;
