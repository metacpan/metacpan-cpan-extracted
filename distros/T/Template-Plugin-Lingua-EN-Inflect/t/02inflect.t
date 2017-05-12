#!/usr/bin/perl -w
use strict;

use Template::Plugin::Lingua::EN::Inflect;
use Test::More  tests => 43;

my $class = 'Template::Plugin::Lingua::EN::Inflect';

is($class->classical(1),undef);
$class->inflect( number => 2 );
is($class->NO('formulas'),'no formulas');
is($class->NO('formulae'),'no formulae');
is($class->PL_N('formula'),'formulae');         # classical 'ancient' active
 
$class->def_noun( "kin" => "kine" );
ok ( $class->NO("kin",0) eq "no kin", "kin -> kine (user defined)..." );
ok ( $class->NO("kin",1) eq "1 kin" );
ok ( $class->NO("kin",2) eq "2 kine" );
 
$class->def_adj(  'red' => 'red|gules' );
ok ( $class->PL("red",0) eq "red" , "red -> gules...");
ok ( $class->PL("red",1) eq "red" );
ok ( $class->PL("red",2) eq "gules" );

$class->def_verb( 
    'foobar'  => 'feebar',
    'foobar'  => 'feebar',
    'foobars' => 'feebar' );
ok ( $class->PL("foobar",2) eq "feebar", "foobar -> feebar (user defined)..." );
ok ( $class->PL("foobars",2) eq "feebar" );
 
ok ( $class->A('ant') eq "an ant" );
ok ( $class->A('bat') eq "a bat" );

ok ( $class->ORD(1) eq "1st" );
ok ( $class->ORD('one') eq "first" );

ok ( $class->PART_PRES("bats") eq "batting" );

is($class->NUMWORDS('21'),'twenty-one');
is($class->NUMWORDS('21',group => 1),'two, one');

is($class->PL_V('is',2),'are');
is($class->PL_ADJ('my',2),'our');

is($class->PL_eq("index","indices"),'s:p');
is($class->PL_N_eq('kin','kine'),'s:p');
is($class->PL_N_eq('kin','kin'),'eq');
is($class->PL_V_eq('is','are'),'s:p');
is($class->PL_V_eq('is','is'),'eq');
is($class->PL_ADJ_eq('my','our'),'s:p');
is($class->PL_ADJ_eq('my','yours'),''); # invalid

is($class->A('formula',1),'a formula');
is($class->AN('formula',1),'a formula');
is($class->A('alien',1),'an alien');
is($class->AN('alien',1),'an alien');

is($class->NUM(2),2);
is($class->PL_V('is'),'are');
is($class->PL_ADJ('my'),'our');
is($class->NUM(),'');


is($class->classical(0),undef);
is($class->NO('formulas'),'no formula');
is($class->NO('formulae'),'no formulaes');
is($class->PL_N('formula'),'formulas');         # classical 'ancient' not active

ok ( $class->PL("red",0) eq "red", "red -> red..." );
ok ( $class->PL("red",1) eq "red" );
ok ( $class->PL("red",2) eq "red" );





#is($class->def_a       { shift; return Lingua::EN::Inflect::def_a(@_);     }
#is($class->def_an      { shift; return Lingua::EN::Inflect::def_an(@_);    }

