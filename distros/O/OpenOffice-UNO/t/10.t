#!/usr/bin/perl -w

use strict;
use warnings;
use lib qw(t/lib);
use Test::More tests => 1;

use UnoTest;

my ($pu, $smgr) = get_service_manager();

my $rc = $smgr->getPropertyValue("DefaultContext");

my $dt = $smgr->createInstanceWithContext("com.sun.star.frame.Desktop", $rc);

# create a blank writer document
my @args = ();
my $sdoc = $dt->loadComponentFromURL("private:factory/swriter", "_blank", 0, \@args);

# Close doc
$sdoc->dispose();

ok( 1, 'Got there' );
