#!/usr/local/bin/perl

BEGIN { push(@INC, './t') }
use W;
print W->new()->test('test7', "examples/sexpcond.pl", *DATA);

__END__
result of (* 2 (+ 3 3)): 12
Trace is ON in class Parse::Lex
[Parse::SExpressions] Token read (LEFTP, [\(]): (
[Parse::SExpressions] Token read (OPERATOR, [-+\/*]): *
[Parse::SExpressions] Token read (NUMBER, \d+): 2
[Parse::SExpressions] Token read (LEFTP, [\(]): (
[Parse::SExpressions] Token read (OPERATOR, [-+\/*]): +
[Parse::SExpressions] Token read (NUMBER, \d+): 3
[Parse::SExpressions] Token read (NUMBER, \d+): 3
[Parse::SExpressions] Token read (RIGHTP, [\)]): )
[Parse::SExpressions] Token read (RIGHTP, [\)]): )
