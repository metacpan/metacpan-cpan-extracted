use Test::More;

BEGIN {
    eval  { require namespace::clean::xs::all; 1 }
    or eval { require namespace::clean; 1 }
    or do {
        plan skip_all => 'no namespace::clean - skip';
        done_testing;
    };
}

my $test = 1;

package Bar;
use Sub::Disable sub => ['foo'];
use namespace::clean;

sub foo {$test = 2}

package main;

eval{ Bar->foo };
TODO: {
    local $TODO = "unavoidable :(";
    is $test, 2;
}

done_testing;
