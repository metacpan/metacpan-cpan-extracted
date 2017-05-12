#!perl

# Name: A simple while loop
# Require: 5
# Desc:
#


require 'benchlib.pl';

&runtest(0.007, <<'ENDTEST');

    my $foo;
    my $count = 30000;
    while ($count--) {
	$foo = $count;
    }

ENDTEST
