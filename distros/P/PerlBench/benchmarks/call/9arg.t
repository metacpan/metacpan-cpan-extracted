#!perl

# Name: Calling procedures
# Require: 5
# Desc:
#


require 'benchlib.pl';

sub foo
{
    my($a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9) = @_;
    $a1+$a2+$a3+$a4+$a5+$a6+$a7+length($a8)+$a9;
}

&runtest(4, <<'ENDTEST');

   $a = foo( 3,  4,  5, 6,  7,  8,  9,"a", 11);
   $b = foo( 5,  6, $a, 7,  8,  9, 10, 11, 12);
        foo($a, $b,  8, 9,  1,  2,  3,  4, $a);

ENDTEST
