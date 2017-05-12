#!/usr/bin/perl -w
use strict;
use Test::More;

plan skip_all => "Developer test" unless $ENV{DEVELOPER} ;

eval <<EOI;
  use Test::Pod;
EOI

plan skip_all => "Test::Pod 1.00 required for testing POD" if $@ ;

all_pod_files_ok( 
'lib/Parse/Eyapp.pod',
'lib/Parse/Eyapp/Base.pod',
'lib/Parse/Eyapp/debuggingtut.pod',
'lib/Parse/Eyapp/Driver.pod',
'lib/Parse/Eyapp/eyappintro.pod',
'lib/Parse/Eyapp/eyapplanguageref.pod',
'lib/Parse/Eyapp/languageintro.pod',
'lib/Parse/Eyapp/MatchingTrees.pod',
'lib/Parse/Eyapp/Node.pod',
'lib/Parse/Eyapp/Parse.pod',
'lib/Parse/Eyapp/Scope.pod',
'lib/Parse/Eyapp/translationschemestut.pod',
'lib/Parse/Eyapp/Treeregexp.pod',
'lib/Parse/Eyapp/YATW.pod',
);

