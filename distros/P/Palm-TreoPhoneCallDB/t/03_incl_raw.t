#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

use Palm::PDB;
use Palm::TreoPhoneCallDB incl_raw => 1;

my $pdb = Palm::PDB->new();
$pdb->Load('t/PhoneCallDB.pdb');

my @records = @{$pdb->{records}};

my $record = $records[0];
ok($record->{rawdata} =~ /Hyperformance/, "Got raw data cos we asked for it");
