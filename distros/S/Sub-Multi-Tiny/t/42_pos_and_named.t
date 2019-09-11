use 5.006;
use strict;
use warnings;
use Test::More;

#use Sub::Multi::Tiny::Util '*VERBOSE';
#BEGIN { $VERBOSE = 99; }

#---------------------------------------------------------------
# Mixing positional and named parameters
#
# The Type::Params cookbook says to use a slurpy Dict for this.

{
    package main::my_multi;
    use Sub::Multi::Tiny qw(D:TypeParams $answer $dict);
        # D:TypeParams -> use that dispatcher, which pulls in Type::Tiny
    use Types::Standard qw(Int Dict Optional slurpy);

    sub just_int :M(Int $answer) {
        return $answer == 42 ? 'yes' : 'no';
    }

    sub with_dict :M(Int $answer,
                    { slurpy Dict[
                        foo => Int,
                        bar => Optional[Int],
                        baz => Optional[Int],
                      ]} $dict)
    {
        return ($answer + ($dict->{foo}||0)*2 - ($dict->{bar}||0)) *
                ($dict->{baz}||1);
    }

}

ok do { no strict 'refs'; defined *{"main::my_multi"}{CODE} }, 'my_multi() exists';

is my_multi(42), 'yes', 'int alone';
cmp_ok my_multi(42, foo => 21), '==', 84, 'int, foo';
cmp_ok my_multi(42, foo => 21, bar => 84), '==', 0, 'int, foo, bar';
cmp_ok my_multi(42, foo => 21, baz => 3), '==', 84*3, 'int, foo, bar';

done_testing;
