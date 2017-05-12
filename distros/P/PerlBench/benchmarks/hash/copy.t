#!perl

# Name: Assign hashes
# Require: 4
# Desc:
#

%hash = ('jan', 1, 'feb', 2, 'mar', 3, 'apr', 4, 'may', 5, 'jun', 6, );


require 'benchlib.pl';


&runtest(8, <<'ENDTEST');

  %hash2 = %hash;
  %hash2 = ();

ENDTEST
