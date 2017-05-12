#!/usr/local/bin/perl

BEGIN { push(@INC, './t') }
use W;
print W->new()->test('test6', "examples/from_string.pl", *DATA);

__END__
INTEGER 1 ADDOP + INTEGER 2 EOI 
INTEGER	1
ADDOP	+
INTEGER	2
