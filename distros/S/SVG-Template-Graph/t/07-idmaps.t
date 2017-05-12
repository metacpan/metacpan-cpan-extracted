# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Template-Graph-SVG.t'

#########################

use Test::Simple tests => 3;
use strict;
use SVG::Template::Graph;
use Config::General;
#########################

my $data = [];
my $tt;
my $svg;
my $out;
my $file = 't/template1.svg';
ok(-r $file,'test template file exists'); 
ok($tt = SVG::Template::Graph->new($file),'load SVG::Template::Graph object');
ok($out = $tt->burn(),'serialise');
