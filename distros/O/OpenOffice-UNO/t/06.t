#!/usr/bin/perl -w

use strict;
use warnings;
use lib qw(t/lib);
use Test::More tests => 1;

use UnoTest;
use OpenOffice::UNO;

my $pu = new OpenOffice::UNO();

my $cu = get_cu($pu);
my $sm = $cu->getServiceManager();

$sm->createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", $cu);

ok( 1, 'Got there' );
