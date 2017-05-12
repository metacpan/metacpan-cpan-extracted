#!/usr/bin/perl -w

use strict;

# set the lib to include 'mylib' in the same dir as this script
use File::Spec::Functions;
use FindBin;
use lib (catdir($FindBin::Bin,"mylib"));

# start the testing
use Test::More tests => 4;

is(tt('[% USE CaseVMethods; thingy = "zz"; thingy.uc %]'),
   'ZZ',
   'uc');

is(tt('[% USE CaseVMethods; thingy = "zz"; thingy.ucfirst %]'),
   'Zz',
   'ucfirst');

is(tt('[% USE CaseVMethods; thingy = "ZZ"; thingy.lc %]'),
   'zz',
   'lc');

is(tt('[% USE CaseVMethods; thingy = "ZZ"; thingy.lcfirst %]'),
   'zZ',
   'lcfirst');

####################################################################
# Standard TT processing thing

use Template;

# tt(
sub ttf
{
  my $file = shift;
  my $args = { @_ };
  my $output;

  my $tt = Template->new();
  $tt->process($file, $args, \$output)
    or die $tt->error;

  return $output;
}

sub tt
{
  my $string = shift;
  return ttf(\$string, @_)
}


