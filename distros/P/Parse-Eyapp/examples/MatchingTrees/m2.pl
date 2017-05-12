#!/usr/bin/env perl 
use strict;
use Rule6;
use Parse::Eyapp::Treeregexp;

Parse::Eyapp::Treeregexp->new( STRING => q{
  fold: /TIMES|PLUS|DIV|MINUS/(NUM, NUM) 
  zxw: TIMES(NUM($x), .) and { $x->{attr} == 0 } 
  wxz: TIMES(., NUM($x)) and { $x->{attr} == 0 }
})->generate();

# Syntax analysis
my $parser = Rule6->new();
my $input = "0*0*0";
$parser->input(\$input);
my $t = $parser->YYParse();

print "Tree:",$t->str,"\n";

# Search
my $m = $t->m(our ($fold, $zxw, $wxz));
print "Match Node:\n",$m->str,"\n";

=head1 SYNOPSIS

This example illustrates the use of the C<m> method of
C<Parse::Eyapp::Node> objects.

Compile C<Rule6.yp> first:

             eyapp Rule6

Run it like this:

  $ ./m2.pl 
  Tree:TIMES(TIMES(NUM(TERMINAL),NUM(TERMINAL)),NUM(TERMINAL))
  Match Node:
  Match[[TIMES:0:wxz]](Match[[TIMES:1:fold,zxw,wxz]])

See C<perldoc> L<Parse::Eyapp::treematchingtut> for the details
