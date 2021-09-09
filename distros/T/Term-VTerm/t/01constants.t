#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

{
   use Term::VTerm qw( :types );

   ok( defined VALUETYPE_BOOL, 'defined VALUETYPE_BOOL' );
}

{
   use Term::VTerm qw( :attrs :types get_attr_type );

   ok( defined ATTR_BOLD, 'defined ATTR_BOLD' );
   is( get_attr_type( ATTR_BOLD ), VALUETYPE_BOOL,
      'get_attr_type of ATTR_BOLD' );
}

{
   use Term::VTerm qw( :props :types get_prop_type );

   ok( defined PROP_CURSORVISIBLE, 'defined PROP_CURSORVISIBLE' );
   is( get_prop_type( PROP_TITLE ), VALUETYPE_STRING,
      'get_prop_type of PROP_TITLE' );
}

done_testing;
