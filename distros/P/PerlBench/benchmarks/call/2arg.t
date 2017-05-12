#!perl

# Name: Calling procedures
# Require: 4
# Desc:
#


require 'benchlib.pl';

sub foo
{
    my ($a, $b) = @_;
    $a * $b;
}

&runtest(10, <<'ENDTEST');

   foo(3, 4);
   foo(5, 6);
   foo(8, 9);

ENDTEST
