#!/usr/bin/perl -w

use strict;
use Perl::Visualize;

die "Usage: piet pietprogram.gif codel_size" unless $#ARGV == 1 ;
my($program, $codel) = @ARGV;
Perl::Visualize::paint($program,"v-$program", <<EOF );
use Piet::Interpreter;
my \$p = Piet::Interpreter->new(image => \$0, codel_size=>"$codel");
\$p->run;
EOF
