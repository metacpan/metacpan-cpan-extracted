#!/usr/bin/perl -w

use strict;
use warnings;
use lib qw(t/lib);
use Test::More tests => 1;

use UnoTest;

my ($pu, $smgr) = get_service_manager();

my $rc = $smgr->getPropertyValue("DefaultContext");

my $dt = $smgr->createInstanceWithContext("com.sun.star.frame.Desktop", $rc);

# open an existing writer doc
my @args = ();
my $doc = $dt->loadComponentFromURL(get_file("test1.sxw"), "_blank", 0, \@args);

# Close doc
$doc->dispose();

ok( 1, 'Got there' );
