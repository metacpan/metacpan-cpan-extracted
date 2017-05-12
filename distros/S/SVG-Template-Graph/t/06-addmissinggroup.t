# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Template-Graph-SVG.t'

#########################

use Test::More tests => 4;
use strict;
BEGIN { use_ok('SVG::Template::Graph') };
#########################

my $data = [];
my $tt;
my $svg;
my $out;
my $file = 't/template2.svg';
ok(-r $file,"test template file $file exists"); 
ok($tt  = SVG::Template::Graph->new($file),'load SVG::Template::Graph object');
ok($out = $tt->burn(),'serialise');
