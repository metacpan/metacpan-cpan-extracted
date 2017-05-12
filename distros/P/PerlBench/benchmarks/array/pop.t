#!perl

# Name: pop/push of arrays
# Require: 4
# Desc:
#


require 'benchlib.pl';

@a = ("a", "b", "c");

&runtest(10, <<'ENDTEST');

    @b = (1 .. 10);
    $a = pop(@b);
    $a = pop(@b);
    $a = pop(@b);
    push(@b, @a);

ENDTEST
