#!/usr/bin/perl
# $RedRiver: example2.pl,v 1.3 2007/01/31 04:17:15 andrew Exp $
use strict;
use warnings;

use Palm::PDB;
use Palm::Keyring;

my $pdb = new Palm::PDB;

$pdb->Load("Keys-Gtkr-example.PDB"); 
$pdb->Password('12345');

foreach (0..$#{ $pdb->{'records'} }) {
    next if $_ == 0;
    my $rec = $pdb->{'records'}->[$_];
    my $acct = $pdb->Decrypt($rec);

    print join ":", $rec->{'name'} , $acct->{'account'},
        $acct->{'password'}, $acct->{'notes'};
    print "\n";
}
