#!/usr/local/bin/perl -w

require 5.004;

use strict;
BEGIN {  unshift @INC, "../lib"; } 

use Parse::Template;
my %template = 
  (
   'TOP' => q!%%$self->method(@_)%%!
  );

my $t1 = new Parse::Template (%template);
$t1->env(
	 'method' => sub { 
	   print ref shift, " args: @_\n"; 
	 },
	);

$t1->eval('TOP', qw/a b c/); 
my $t2 = $t1->new(%template); # 't2' is a sub-class of 't1'
$t2->eval('TOP', qw'x y z');	


