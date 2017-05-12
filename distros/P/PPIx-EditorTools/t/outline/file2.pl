#!/usr/bin/perl

use 5.008;
use strict;
use autodie;
use warnings FATAL => 'all';

use lib ('/opt/perl5/lib');

my $global = 42;

print "start";

sub abc {
   print 1;

   my $private = 42;

   sub def {
   }
   print 2;
}

print "ok";

sub xyz { }

print "end";

