#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

use Palm::PDB;
use Palm::TreoPhoneCallDB timezone => 'America/Chicago';

my $pdb = Palm::PDB->new();
$pdb->Load('t/PhoneCallDB.pdb');

my @records = @{$pdb->{records}};

my $record = $records[0];
ok($record->{epoch}    eq '1185498480',   "Epoch calculated correctly with a freaky timezone");
