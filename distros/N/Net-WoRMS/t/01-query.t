#!/usr/bin/env perl
# BASIC QUERIES ========================================================
# (C) 2026 by A. Weidauer
# Contact: alex.weidauer@huckfinn.de
# ======================================================================
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 13;
BEGIN { use_ok("Net::WoRMS"); }

my $SPEC  = 'Abra alba';
my $APHIA = 141433;
my $WORMS = Net::WoRMS->new();
ok(defined $WORMS, 'Tool accessible');
ok($WORMS->isa('Net::WoRMS'), 'Tool is Net::WoRMS');
$WORMS->init();
ok($WORMS->checkSoap(), 'Tool was initialized');

my $id = $WORMS->searchSpeciesID($SPEC,0);
ok($id eq $APHIA, "Find SPECIES: '$SPEC' ID: $APHIA");

my $rec = $WORMS->getRecordByID($APHIA);
ok($rec->{kingdom} eq 'Animalia',   "KINGDOM: 'Animalia'");
ok($rec->{phylum}  eq 'Mollusca',   "PHYLUM:  'Mollusca'");
ok($rec->{class}   eq 'Bivalvia',   "RANK:    'Bivalvia'");
ok($rec->{order}   eq 'Cardiida',   "ORDER:   'Cardiida'");
ok($rec->{family}  eq 'Semelidae',  "FAMILY:  'Semelidae'");
ok($rec->{genus}   eq 'Abra',       "GENUS:   'Abra'");
ok($rec->{rank}    eq 'Species',    "RANK:    'Species'");
ok($rec->{scientificname} eq $SPEC, "NAME:    '$SPEC'");
# diag("ID: ",Dumper($id));
# diag("REC,Dumper($rec));

done_testing();
# EOF ==================================================================
