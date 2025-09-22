#!/usr/bin/env perl

use Perl::Types;
use strict;
use warnings;
our $VERSION = 0.001_000;

my nonsigned_integer $uifoo = 5;
my nonsigned_integer $uibar = ~($uifoo);
print '$uifoo   = ' . $uifoo . "\n";
print '$uibar   = ' . $uibar . "\n";

use integer;

my integer $ifoo = 5;
my integer $ibar = ~($ifoo);
print '$ifoo   = ' . $ifoo . "\n";
print '$ibar   = ' . $ibar . "\n";

