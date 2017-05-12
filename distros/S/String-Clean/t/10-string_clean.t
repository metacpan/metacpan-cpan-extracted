#!/usr/bin/perl;

use strict;
use warnings;

use Test::More qw{no_plan};
use String::Clean qw{replace strip};

#---------------------------------------------------------------------------
#  NEW
#---------------------------------------------------------------------------
my $obj  = String::Clean->new();
isa_ok(  $obj, 
         'String::Clean', 
         q{[String::Clean] new()},
);


#---------------------------------------------------------------------------
#  REPLACE
#---------------------------------------------------------------------------
is (
   $obj->replace( { a => 'A' }, 'a add'),
   'A Add',
   q{normal replace}
);

is (
   $obj->replace( { a => 'A' }, 'this is a test', {replace => 'word'}),
   'this is A test',
   q{word replace}
);

is (
   $obj->replace( { a => 'A', '*' => '*' }, 'this,is,a,test', { replace => 'word', word_boundary => ','}),
   'this,is,A,test',
   q{word replace}
);

is (
   $obj->replace_word( { a => 'A' }, 'a add' ),
   'A add',
   q{word replace via replace_word}
);

is (
   $obj->replace( { a => 'X' }, 'A add', {opt => 'i'} ),
   'X Xdd',
   q{case insensitive replace}
);

#---------------------------------------------------------------------------
#  STRIP
#---------------------------------------------------------------------------
is (
   $obj->strip( [qw{a d}] , 'a add'),
   ' ',
   q{normal strip}
);

is (
   $obj->strip( [qw{a *}], 'a add', {strip => 'word'}),
   ' add',
   q{word strip}
);

is (
   $obj->strip_word( [qw{a}], 'a add' ),
   ' add',
   q{word strip via strip_word}
);

is (
   $obj->strip( [qw{a}], 'A add', {opt => 'i'} ),
   ' dd',
   q{case insensitive strip}
);

#---------------------------------------------------------------------------
#  YAML
#---------------------------------------------------------------------------
is (
   $obj->clean_by_yaml(q{
---
this : that
is   : was
a    : an
---
- still
---
for : to explain
'  ': ' '
},
q{this is still just a example for the yaml stuff},
{ replace => 'word' } ), 
q{that was just an example to explain the yaml stuff},
q{clean by yaml example from the docs}
);


#---------------------------------------------------------------------------
#  Checking to see if passing $opt at new will scale down
#---------------------------------------------------------------------------
$obj  = String::Clean->new({replace => 'word', strip => 'word', opt => 'i'});

is (
   $obj->replace( {a => 'cat'}, 'this is still A test' ),
   'this is still A test',
   q{functions will inherit the options from self},
);

is (
   $obj->replace( {this => 'cat'}, 'this is still A test' ),
   'cat is still A test',
   q{checking to see if we can strip from the begining of the string},
);

is (
   $obj->strip( [qw{a}], 'A Attatude', {strip=> undef} ),
   ' tttude',
   q{if you pass an opt it will get merged with self},
); 
