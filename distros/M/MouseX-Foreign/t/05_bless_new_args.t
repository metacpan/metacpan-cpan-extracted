#!perl -w
use strict;
use Test::More;

# A certain style of hand written constructor might bless its
# arguments.  Test we don't choke because the arguments are apparently
# not a hash.

{
    package Bless::Args;
    sub new {
        my($class, $args) = @_;
        $args ||= {};
        return bless $args, $class;
    }
}

{
    package Foo;
    use Mouse;
    use MouseX::Foreign;
    extends 'Bless::Args';
}

new_ok 'Foo', [{ foo => 23 }];

done_testing;
