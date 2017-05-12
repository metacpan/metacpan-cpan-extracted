#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/networks/src/debian/packages/libr/libmodule-multiconf-perl/trunk/t/20-load.t $
# $LastChangedRevision: 1348 $
# $LastChangedDate: 2007-07-12 15:23:07 +0100 (Thu, 12 Jul 2007) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

package ConfTest;
use Module::MultiConf;
package main;

my $m;
eval {$m = ConfTest->new(1,2,3) };
like( $@, qr/Failed to parse contents of filename/ );

eval {$m = ConfTest->new() };
isa_ok( $m, 'ConfTest' );
