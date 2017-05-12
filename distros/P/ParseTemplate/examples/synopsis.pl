#!/usr/local/bin/perl -w

require 5.004; 
use strict;
BEGIN {  unshift @INC, "../lib"; } 

use Parse::Template;

my %template = 
  (
   'TOP' =>  q!Text before%%$N . SUB_PART(1)%%Text after!,
   'SUB_PART' => q!Inserted part from %%"$part(@_)"%%
   1. List: %%"@list"%%
   2. Hash: %%"$hash{'some_key'}"%%
   3. Sub: %%&SUB(1,2,3,'soleil')%%!
  );

my $tmplt = new Parse::Template (%template);

$tmplt->env('var' => 'scalar value!');
$tmplt->env('list' => [1, 2, 10], 
	    'N' => "\n",
	    'SUB' => sub { "arguments: @_\n" },
	    'hash' => { 'some_key' => q!It\'s an hash value! });
print $tmplt->eval('TOP'), "\n";
