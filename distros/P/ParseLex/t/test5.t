#!/usr/local/bin/perl

BEGIN { push(@INC, './t') }
use W;
print W->new()->test('test5', "examples/evparser.pl", *DATA);

__END__
comment: /*
  A C comment 
*/
remainder: 

ccomment: // A C++ comment

remainder: var d = 
dquotes: "string in \"double\" quotes"
remainder: ;
var s = 
squotes: 'string in ''single'' quotes'
remainder: ;
var x = 1;
var y = 2;

Version X.XX
