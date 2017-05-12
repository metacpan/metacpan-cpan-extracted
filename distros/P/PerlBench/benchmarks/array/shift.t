#!perl

# Name: shift/unshift arrays
# Require: 4
# Desc:
#


require 'benchlib.pl';

@a = ("a", "b", "c");

&runtest(10, <<'ENDTEST');

    @b = (1 .. 10);
    $a = shift(@b);
    $a = shift(@b);
    $a = shift(@b);
    unshift(@b, @a);

ENDTEST
