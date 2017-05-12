#!/usr/bin/env perl -w

use strict;
use warnings;

use lib 'blib/lib';
use lib 't/lib';
use NetApp::Test;

use Test::More qw( no_plan );
use Test::Exception;
use Data::Dumper;

use NetApp::Filer;
use NetApp::Aggregate;

my $header = "           Aggr State      Status            Options";

throws_ok {
    ( my $bogus = $header ) =~ s/Aggr//;
    NetApp::Aggregate->_parse_aggr_status_headers( $bogus );
} qr{Unable to match 'Aggr' column header},
    qq{Missing Aggr in header};

throws_ok {
    ( my $bogus = $header ) =~ s/State//;
    NetApp::Aggregate->_parse_aggr_status_headers( $bogus );
} qr{Unable to match 'State' column header},
    qq{Missing State in header};

throws_ok {
    ( my $bogus = $header ) =~ s/Status//;
    NetApp::Aggregate->_parse_aggr_status_headers( $bogus );
} qr{Unable to match 'Status' column header},
    qq{Missing Status in header};

my $indices = NetApp::Aggregate->_parse_aggr_status_headers( $header );
ok( scalar keys %$indices == 4, "Correct hash key count for indices" );

ok( $indices->{aggr}->[0] == 0 && $indices->{aggr}->[1] == 16,
    "Indices for aggr correct" );
ok( $indices->{state}->[0] == 16 && $indices->{state}->[1] == 11,
    "Indices for state correct" );
ok( $indices->{status}->[0] == 27 && $indices->{status}->[1] == 18,
    "Indices for status correct" );
ok( $indices->{options}->[0] == 45,
    "Indices for options correct" );

my $line1  = "really_long_aggr01 online     raid_dp, aggr     root, raidsize=14";
my $line2  = "                           morestatus        moreoptions";

my $aggregate	= {};

NetApp::Aggregate->_parse_aggr_status_aggregate(
    indices	=> $indices,
    aggregate	=> $aggregate,
    line	=> $line1,
);

ok( $aggregate->{name} eq 'really_long_aggr01',
    "Parsed name correctly" );
ok( $aggregate->{state}->{online} == 1,
    "Parsed state correctly" );

foreach my $status ( qw( raid_dp aggr ) ) {
    ok( $aggregate->{status}->{$status} == 1,
        "Parsed $status status correctly" );
}

ok( $aggregate->{options}->{root} == 1,
    "Parsed root options correctly" );
ok( $aggregate->{options}->{raidsize} == 14,
    "Parsed raidsize options correctly" );

NetApp::Aggregate->_parse_aggr_status_aggregate(
    indices	=> $indices,
    aggregate	=> $aggregate,
    line	=> $line2,
);

foreach my $status ( qw( raid_dp aggr ) ) {
    ok( $aggregate->{status}->{$status} == 1,
        "Previously parsed $status status preserved" );
}

ok( $aggregate->{status}->{morestatus} == 1,
    "Parsed 2nd line status correctly" );
ok( $aggregate->{options}->{moreoptions} == 1,
    "Parsed 2nd line options correctly" );

my $line3	= "       Volumes: vol1, vol2, vol3,";
my $line4	= "                vol4, vol5,";
my $line5	= "                vol6";

my $volumes	= {};

NetApp::Aggregate->_parse_aggr_status_volumes(
    volumes	=> $volumes,
    line	=> $line3,
);

ok( scalar keys %$volumes == 3,
    "Parsed first volume line correctly" );

NetApp::Aggregate->_parse_aggr_status_volumes(
    volumes	=> $volumes,
    line	=> $line4,
);

ok( scalar keys %$volumes == 5,
    "Parsed second volume line correctly" );

NetApp::Aggregate->_parse_aggr_status_volumes(
    volumes	=> $volumes,
    line	=> $line5,
);

ok( scalar keys %$volumes == 6,
    "Parsed third volume line correctly" );

foreach my $index ( 1 .. 6 ) {
    ok( $volumes->{"vol$index"} == 1, "Volume $index found correctly" );
}

my $line6	= "     Plex /really_long_aggr01/plex0: online, normal, active";

my $plex	= NetApp::Aggregate->_parse_aggr_status_plex( $line6 );

ok( $plex->{name} eq '/really_long_aggr01/plex0',
    "Parsed plex name correctly" );
ok( ref $plex->{state} eq 'HASH',
    "Plex state data type correct" );
ok( scalar keys %{ $plex->{state} } == 3,
    "Correct number of states" );
foreach my $state ( qw( online normal active ) ) {
    ok( $plex->{state}->{$state},
        "State values are correct" );
}

my $line7	= "      RAID group /really_long_aggr01/plex0/rg0: normal";

my $raidgroup	= NetApp::Aggregate->_parse_aggr_status_raidgroup( $line7 );

ok( $raidgroup->{name} eq '/really_long_aggr01/plex0/rg0',
    "Parsed RAIDGroup name correctly" );
ok( ref $raidgroup->{state} eq 'HASH',
    "Raidgroup state data type correct" );
ok( scalar keys %{ $raidgroup->{state} } == 1,
    "Correct number of states" );
ok( $raidgroup->{state}->{normal},
    "State value is correct" );

