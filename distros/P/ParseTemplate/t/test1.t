#!/usr/local/bin/perl

BEGIN {  push(@INC, './t') }	# where is W.pm
use W;

print W->new()->test('test1', "examples/synopsis.pl", *DATA);

__END__
Text before
Inserted part from SUB_PART(1)
   1. List: 1 2 10
   2. Hash: It\'s an hash value
   3. Sub: arguments: 1 2 3 soleil 
Text after 
