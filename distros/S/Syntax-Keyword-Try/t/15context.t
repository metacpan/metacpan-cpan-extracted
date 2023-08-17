#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Try;

# wantarray inside try
{
   my $context;
   sub whatcontext
   {
      try {
         $context = wantarray ? "list" :
            defined wantarray ? "scalar" : "void";
      }
      catch ($e) { }
   }

   whatcontext();
   is($context, "void", 'sub {try} in void');

   my $scalar = whatcontext();
   is($context, "scalar", 'sub {try} in scalar');

   my @array = whatcontext();
   is($context, "list", 'sub {try} in list');
}

done_testing;
