#!/usr/local/bin/perl -w
# 
# matidump.pl -- 
# 
# Author          : Maxime Soule
# Created On      : Fri Jun  9 10:02:14 2006
# Last Modified By: Maxime Soule
# Last Modified On: Mon May  3 15:10:26 2010
# Update Count    : 15
# Status          : Unknown, Use with caution!
#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

use strict;

use Palm::MaTirelire::AccountsV2;
use Palm::MaTirelire::Modes;
use Palm::MaTirelire::Types;
use Palm::MaTirelire::Currencies;

use Data::Dumper;

die "usage: $0 MaTi-database.pdb\n" unless @ARGV == 1 and -r $ARGV[0];

my $pdb = new Palm::PDB;

$pdb->Load($ARGV[0]);

if ($pdb->{appinfo})
{
    print Data::Dumper->Dump([ $pdb->{appinfo} ], [ 'APPINFO_BLOCK' ]);
}

if ($pdb->{sort})
{
    print Data::Dumper->Dump([ $pdb->{sort} ], [ 'SORT_BLOCK' ]);
}

for (my $i = 0; $i < @{$pdb->{records}}; $i++)
{
    my $rec = $pdb->{records}[$i];
    print "\n";
    print Data::Dumper->Dump([ $pdb->{records}[$i] ], [ "RECORD_$i" ]);
}


if ($pdb->isa('Palm::MaTirelire::Types'))
{
    print scalar($pdb->dump), "\n";
}
