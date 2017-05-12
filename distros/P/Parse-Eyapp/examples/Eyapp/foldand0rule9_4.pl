#!/usr/bin/env perl 
=head1 SYNOPSIS

   foldand0rule9_4.pl
   
Try inputs: 

   a = 2*3+4   # Reducido a: a = 6
   a = 2*[3+b] # syntax error
   a = 2*3*b   # Reducido a: a = 6*b

Compile it with 

         eyapp -m 'Calc' Rule9.yp 
         treereg -o T.pm -p 'R::' -m T Transform4

=cut

use warnings;
use strict;
use Calc;
use T;

sub R::TERMINAL::info { $_[0]{attr} }

my $parser = new Calc(yyprefix => "R::");
                   # stdin, prompt              , read one line at time

$parser->YYPrompt("Arithmetic expression: ");
$parser->slurp_file('', "\n");

my $t = $parser->YYParse;

unless ($parser->YYNberr) {
  print "\n***** Tree before the transformations ******\n";
  print $t->str."\n";

  $t->s(@T::all);
  print "\n***** Tree after the transformations were applied ******\n";
  print $t->str."\n";
}
