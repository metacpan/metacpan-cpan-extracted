#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

use_ok('MyApp');
use_ok('MyApp::Test');

my $obj = MyApp::Test->new( bla => 2 );

isa_ok($obj,"MyApp::Test");
is($obj->bla,2,"Constructor value");
is($obj->bla(3),3,"Setter return value");
is($obj->bla,3,"New value");
ok($obj->meta->is_immutable,"Class is made immutable");

use_ok('MyApp::OtherTest');

my $otherobj = MyApp::OtherTest->new( blub => 3 );

isa_ok($otherobj,"MyApp::OtherTest");
is($otherobj->blub,3,"Constructor value of OtherTest");
ok($otherobj->meta->is_immutable,"Class is made immutable");

my $test_obj = $otherobj->test;

isa_ok($test_obj,"MyApp::Test");
is($test_obj->bla,3,"Value of OtherTest blub");

done_testing;
