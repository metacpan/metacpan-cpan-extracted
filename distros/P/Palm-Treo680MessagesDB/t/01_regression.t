#!/usr/bin/perl -w
# $Id: 01_regression.t,v 1.5 2008/07/10 14:07:26 drhyde Exp $

# regression data produced thus
# perl -Ilib -MData::Dumper -MPalm::PDB -MPalm::Treo680MessagesDB -e '$pdb=Palm::PDB->new();$pdb->Load("t/regression/database.pdb");foreach $r (@{$pdb->{records}}) { open(R, ">t/".$r->{offset}.".dd");print R Dumper($r);close(R)}'

use strict;
use vars qw($VAR1);

use Test::More tests => 1104;

use Palm::PDB;
use Palm::Treo680MessagesDB;

my $pdb = Palm::PDB->new();
$pdb->Load('t/regression/database.pdb');

my @records = @{$pdb->{records}};
my %records_by_offset = map { $_->{offset} => $_ } @records;
local $/ = undef;

foreach(keys %records_by_offset) {
    ok(-f "t/regression/$_.dd", "parsed data file exists for record at offset $_, type ".$records_by_offset{$_}->{type});
}

opendir(DIR, 't/regression') || die("Can't read t/regression/\n");
foreach my $file (
    grep { -f && /\.dd$/ }
    map { "t/regression/$_" }
    readdir(DIR)
) {
    (my $offset = $file) =~ s/^\D+(\d+)\D+$/$1/;
    open(FILE, $file) || die("Can't read $file\n");
    my $struct = eval <FILE>;
    close(FILE);
    is_deeply(
        $records_by_offset{$offset},
        $struct,
        "Record at offset $offset is good"
    );
}
