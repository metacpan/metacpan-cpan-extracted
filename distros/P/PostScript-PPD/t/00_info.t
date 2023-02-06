#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Test::More tests => 1;

pass;
# idea from Test::Harness, thanks!
diag(
  "Perl $], ",
  "$^X on $^O" 
);

diag( "We are $0" );
diag( "FindBind says $FindBin::Bin" );
