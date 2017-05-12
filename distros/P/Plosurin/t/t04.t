#===============================================================================
#
#  DESCRIPTION:  Test Expr Grammars
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$


package main;

use strict;
use warnings;

use Test::More tests=>2;                      # last test to print

use Plosurin::Grammar;
use Plosurin::SoyTree;
use Data::Dumper;
my $t2 = Soy::Expression->new(q!$w!)->parse({'w'=>'local_var'})->as_perl5;
ok  $t2 =~ /\$local_var/, 'check map';

my $o = new Soy::Expression(q![ '2', 23+1+(1+3), 'w', $w ]!)->parse({'w'=>'local_var'});
ok $o->as_perl5 =~ /\$local_var/, 'map vars';
#diag Dumper [ new Soy::expression(q![ '2', 23+1, 'w', $w ]!)->parse() ];

