#!/usr/local/bin/perl -w

require 5.004; 
use strict;
BEGIN {  unshift @INC, "../lib"; } 

use Parse::Template;

my %template = 
  (
   'TOP' =>  q!Text before %%DATA(1)%%Text after!,
   'DATA' => q!Inserted data: %%"@_$N"%%! .
   q!1. List: %%"@list$N"%%! .
   q!2. Hash: %%"$hash{'key_value'}$N"%%! .
   q!3. Sub: %%&SUB(1,2,3,'soleil')%%!
  );

{
  my $tmplt = new Parse::Template (%template);
  $tmplt->env('var' => '(value!)');
  $tmplt->env('list' => [1, 2, 10], 
	    'N' => "\n",
	    'SUB' => sub { "arguments: @_\n" },
	    'hash' => { 'key_value' => q!It\'s an hash value! });
  print $tmplt->eval('TOP'), "\n";
  print "END OF BLOCK\n";
}

print "after the BLOCK\n";
