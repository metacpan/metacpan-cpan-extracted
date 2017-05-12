#!/usr/bin/perl -w
use strict;
use Rule6;
use Parse::Eyapp::Treeregexp;

Parse::Eyapp::Treeregexp->new( STRING => q{
  fold: /TIMES|PLUS|DIV|MINUS/(NUM, NUM) 
  zxw: TIMES(NUM($x), .) and { $x->{attr} == 0 } 
  wxz: TIMES(., NUM($x)) and { $x->{attr} == 0 }
})->generate();

# Syntax analysis
my $parser = new Rule6();
my $input = "0*0*0";
$parser->input(\$input);
my $t = $parser->YYParse();

exit(1) if $parser->YYNberr > 0;

print "Tree:",$t->str,"\n";

# Search
my $m = $t->m(our ($fold, $zxw, $wxz));
print "Match Node:\n",$m->str,"\n";
