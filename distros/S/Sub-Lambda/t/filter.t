#!perl -T

use strict;
use warnings;
use Test::Simple tests => 5;
use Sub::Lambda::Filter;

*flip = (\f -> \a -> \b -> f b a);
*subt = (\x -> \y -> { $x - $y });
*fsub = ((\f -> \a -> \b -> f b a) (\x -> \y -> { $x - $y }));
*sum  = (\h -t -> { @t ? $h+sum(@t) : ($h||0) });

ok(flip(\&subt)->(5)->(10)              == 5);
ok(flip(\x -> \y -> {$x-$y})->(1)->(2)  == 1);
ok(fsub(1)->(2)                         == 1);
ok(sum(1,2,3,4)                         == 10);
ok(((\f -> \a -> \b -> f b a)
    (\x -> \y -> {$x-$y}) 
    {1}
    {2}) == 1);
