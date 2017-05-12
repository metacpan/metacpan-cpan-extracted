#!/usr/bin/perl -w
# $Id: 02b-weird-timezone.t,v 1.3 2008/07/07 22:44:20 drhyde Exp $

use strict;

use Test::More tests => 2;

use Palm::PDB;
use Palm::Treo680MessagesDB timezone => 'America/Chicago';

my $pdb = Palm::PDB->new();
$pdb->Load('t/regression/database.pdb');

my @records = @{$pdb->{records}};

my $record = $records[0];
ok($record->{date} eq '2007-06-05', "Date calculated correctly for a weird timezone");
ok($record->{time} eq '18:04',      "Time calculated correctly for a weird timezone");
