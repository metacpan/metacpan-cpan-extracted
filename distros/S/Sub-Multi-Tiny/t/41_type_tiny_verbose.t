use 5.006;
use strict;
use warnings;
use Test::More;

# For the sake of coverage
use Sub::Multi::Tiny::Util '*VERBOSE';
BEGIN { $VERBOSE = 99; }

#---------------------------------------------------------------
# Type constraints

{
    package main::my_multi;
    use Sub::Multi::Tiny qw(D:TypeParams $foo);
        # D:TypeParams -> use that dispatcher, which pulls in Type::Tiny
    use Types::Standard qw(Str Int);

    sub second :M(Int $foo) {
        return $foo + 42;
    }

    sub first :M(Str $foo) {
        return "Hello, $foo!";
    }

}

ok do { no strict 'refs'; defined *{"main::my_multi"}{CODE} }, 'my_multi() exists';

is my_multi("world"), 'Hello, world!', 'Str multi';
cmp_ok my_multi(0), '==', 42, 'Int multi';
cmp_ok my_multi(42), '==', 84, 'Int multi';

done_testing;
