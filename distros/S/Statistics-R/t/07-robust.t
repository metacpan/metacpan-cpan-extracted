#! perl

use strict;
use warnings;
use Test::More;
use Statistics::R;


my ($R, $input);

ok $R = Statistics::R->new();


# Test that we can recover from a R quit() command
is $R->run(q`quit()`), '', 'Handle quit()';
is $R->run(q`cat("foo")`), 'foo';


# Test that large arrays can be read
ok $R->set('y', [1 .. 100_000]), 'Large arrays';
is $R->get('y')->[-1], 100_000;


# Test that the IOs are well-oiled. In Statistics::R version 0.20, a slight
# imprecision in the regular expression to parse the output stream caused a
# problem that was apparent only once every few thousands times
ok $R->set('z', $input), 'Smooth IO';
for my $i (1 .. 10_000) {
   is $R->get('z'), undef;
}

ok $R->stop();


done_testing;
