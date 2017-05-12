#!/usr/bin/env perl
# Compile first pascalnestedeyapp3.eyp with options:
#   eyapp -TP -S range pascalnestedeyapp3.eyp 
use strict;
use warnings;
use range;

my $parser = range->new( yyerror => sub {});
$parser->YYPrompt(<<'EOM');
Try one of these inputs:

                (x) .. (y)
                (x) ..  y 
                (x+2)*3 ..  y/2 
                (x, y, z)
                (x)
                (x, y, z) .. (u+v)

EOM
$parser->slurp_file('', "\n");
my $t = $parser->Run;
if ($parser->YYNberr) {
  print "There were errors\n";
} else {
  print "***********\n",$t->str,"\n";
}

