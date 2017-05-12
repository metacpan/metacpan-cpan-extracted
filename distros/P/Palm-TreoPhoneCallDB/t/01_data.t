#!/usr/bin/perl -w

use strict;

use Test::More tests => 11;

use Palm::PDB;
BEGIN { use_ok('Palm::TreoPhoneCallDB') }

my $pdb = Palm::PDB->new();
$pdb->Load('t/PhoneCallDB.pdb');

my @records = @{$pdb->{records}};

my $record = $records[0];
ok($records[0]->{number}   eq '02089393940',    "Number set correctly");
ok($records[0]->{name}     eq 'Hyperformance (W)',"Name set correctly");
ok($records[0]->{duration} eq '51',           "Duration set correctly");
ok($records[0]->{date}     eq '2007-07-26',       "Date set correctly");
ok($records[0]->{time}     eq '20:08',            "Time set correctly");
ok($records[0]->{epoch}   eq '1185476880',"Epoch calculated correctly");

ok(!exists($records[0]->{rawdata}), "No raw data cos we didn't ask for it");

ok($records[0]->{direction} eq 'Outgoing', 'Direction set correctly for outgoing calls');
ok($records[2]->{direction} eq 'Incoming', 'Direction set correctly for ingoing calls');
ok($records[18]->{direction} eq 'Missed', 'Direction set correctly for missed calls');
