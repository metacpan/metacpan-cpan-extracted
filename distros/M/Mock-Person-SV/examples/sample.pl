#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use File::Basename;

use lib File::Basename::dirname( Cwd::abs_path(__FILE__)) . '/../lib';
use Mock::Person;

for(0 .. 4) {
  print Mock::Person::name(
    sex     => 'female',
    country => 'sv',
  ), "\n";
}
