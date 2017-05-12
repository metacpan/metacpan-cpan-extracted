#!/usr/bin/perl
# $RedRiver: example1.pl,v 1.9 2007/01/30 04:59:55 andrew Exp $
use strict;
use warnings;

use Palm::Keyring;

my $pdb = new Palm::Keyring('12345');

my $rec = $pdb->append_Record();

my $acct = {
	name      => 'Test3',
	account   => 'anothertestaccount',
	password  => 'adifferentmypass',
	notes     => 'now that really roxorZ!',
};

$pdb->Encrypt($rec, $acct);
 
$pdb->Write("Keys-Gtkr-example.PDB");
