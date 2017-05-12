#!/usr/bin/perl -w
# $Id: 03a_dont_incl_raw.t,v 1.3 2008/07/07 22:44:20 drhyde Exp $

use strict;

use Test::More tests => 1;

use Palm::PDB;
use Palm::Treo680MessagesDB;

my $pdb = Palm::PDB->new();
$pdb->Load('t/regression/database.pdb');

my @records = @{$pdb->{records}};

my $record = $records[0];
ok(!exists($record->{rawdata}), "Didn't get raw data");
