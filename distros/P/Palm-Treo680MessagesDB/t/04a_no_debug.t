#!/usr/bin/perl -w
# $Id: 04a_no_debug.t,v 1.3 2008/07/07 22:44:20 drhyde Exp $

use strict;

use Test::More tests => 2;

use Palm::PDB;
use Palm::Treo680MessagesDB;

my $pdb = Palm::PDB->new();
$pdb->Load('t/regression/database.pdb');

my @records = @{$pdb->{records}};

my $record = $records[0];
ok($record->{offset} == 9693, "got right record");
ok(!exists($record->{debug}), "and no hex dump");
