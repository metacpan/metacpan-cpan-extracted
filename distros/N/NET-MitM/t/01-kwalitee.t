#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
eval { require Test::Kwalitee; };

plan( skip_all => "Test::Kwalitee not installed" )
  if $@;

Test::Kwalitee->import();
