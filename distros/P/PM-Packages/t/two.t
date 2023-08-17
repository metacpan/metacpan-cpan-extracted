#!/usr/bin/perl

use strict;
use warnings;

use Test::More ( tests => 1 );

use PM::Packages;

my $foo = [ pm_packages(__FILE__) ];
is_deeply( [ sort @$foo ], [ 'Package::Two', 'Show::Me'], "Two" ) or die join ', ', sort @$foo;


package Show::Me;

package Package::Two;
