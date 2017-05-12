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
use NetApp::Volume;

my $header = <<"__header__";
         Volume State      Status            Options
__header__

throws_ok {
    ( my $bogus = $header ) =~ s/Volume//;
    NetApp::Volume->_parse_vol_status_headers( $bogus );
} qr{Unable to match 'Volume' column header},
    qq{Missing Volume in header};

throws_ok {
    ( my $bogus = $header ) =~ s/State//;
    NetApp::Volume->_parse_vol_status_headers( $bogus );
} qr{Unable to match 'State' column header},
    qq{Missing State in header};

throws_ok {
    ( my $bogus = $header ) =~ s/Status//;
    NetApp::Volume->_parse_vol_status_headers( $bogus );
} qr{Unable to match 'Status' column header},
    qq{Missing Status in header};

throws_ok {
    ( my $bogus = $header ) =~ s/Options//;
    NetApp::Volume->_parse_vol_status_headers( $bogus );
} qr{Unable to match 'Options' column header},
    qq{Missing Options in header};

my $indices = NetApp::Volume->_parse_vol_status_headers( $header );
ok( scalar keys %$indices == 5, "Correct hash key count for indices" );

ok( $indices->{volume}->[0] == 0 && $indices->{volume}->[1] == 16,
    "Indices for volume correct" );
ok( $indices->{state}->[0] == 16 && $indices->{state}->[1] == 11,
    "Indices for state correct" );
ok( $indices->{status}->[0] == 27 && $indices->{status}->[1] == 18,
    "Indices for status correct" );
ok( $indices->{options}->[0] == 45,
    "Indices for options correct" );

my @lines = split /\n/, <<__lines__;
really_long_volume01 online     raid_dp, flex     nosnap=off, nosnapdir=off,   
                                             minra=off, no_atime_update=off, 
__lines__

my $volume	= {};

NetApp::Volume->_parse_vol_status_volume(
    indices	=> $indices,
    volume	=> $volume,
    line	=> $lines[0],
);

ok( $volume->{name} eq 'really_long_volume01',
    "Parsed name correctly" );
ok( $volume->{state}->{online} == 1,
    "Parsed state correctly" );

foreach my $status ( qw( raid_dp flex ) ) {
    ok( $volume->{status}->{$status} == 1,
        "Parsed $status status correctly" );
}

ok( $volume->{options}->{nosnap} eq 'off',
    "Parsed nosnap options correctly" );
ok( $volume->{options}->{nosnapdir} eq 'off',
    "Parsed nosnapdir options correctly" );

NetApp::Volume->_parse_vol_status_volume(
    indices	=> $indices,
    volume	=> $volume,
    line	=> $lines[1],
);

foreach my $status ( qw( raid_dp flex ) ) {
    ok( $volume->{status}->{$status} == 1,
        "Previously parsed $status status preserved" );
}

ok( $volume->{options}->{minra} eq 'off' &&
        $volume->{options}->{no_atime_update} eq 'off',
    "Parsed 2nd line options correctly" );

my $header_source = <<"__header_source__";
         Volume State      Status            Options                      Source
__header_source__

$indices = NetApp::Volume->_parse_vol_status_headers( $header_source );
ok( scalar keys %$indices == 6, "Correct hash key count for indices" );

ok( $indices->{volume}->[0] == 0 && $indices->{volume}->[1] == 16,
    "Indices for volume correct" );
ok( $indices->{state}->[0] == 16 && $indices->{state}->[1] == 11,
    "Indices for state correct" );
ok( $indices->{status}->[0] == 27 && $indices->{status}->[1] == 18,
    "Indices for status correct" );
ok( $indices->{options}->[0] == 45 && $indices->{options}->[1] == 29,
    "Indices for options correct" );
ok( $indices->{source}->[0] == 74,
    "Indices for source correct" );

@lines = split /\n/, <<__lines__;
   cache_volume online     raid_dp, flex     nosnap=off, nosnapdir=off,   localhost:cache_source
                           flexcache         minra=off, no_atime_update=off, 
__lines__

$volume 	= {};

NetApp::Volume->_parse_vol_status_volume(
    indices	=> $indices,
    volume	=> $volume,
    line	=> $lines[0],
);

ok( $volume->{name} eq 'cache_volume',
    "Parsed name correctly" );
ok( $volume->{state}->{online} == 1,
    "Parsed state correctly" );

foreach my $status ( qw( raid_dp flex ) ) {
    ok( $volume->{status}->{$status} == 1,
        "Parsed $status status correctly" );
}

ok( $volume->{options}->{nosnap} eq 'off',
    "Parsed nosnap options correctly" );
ok( $volume->{options}->{nosnapdir} eq 'off',
    "Parsed nosnapdir options correctly" );

ok( $volume->{source}->{hostname} eq 'localhost',
    "Parsed source hostname correctly" );

ok( $volume->{source}->{volume} eq 'cache_source',
    "Parsed source volume correctly" );

NetApp::Volume->_parse_vol_status_volume(
    indices	=> $indices,
    volume	=> $volume,
    line	=> $lines[1],
);

ok( $volume->{status}->{flexcache} == 1,
    "Parsed flexcache status correctly" );

ok( $volume->{options}->{minra} eq 'off',
    "Parsed nosnap options correctly" );
ok( $volume->{options}->{no_atime_update} eq 'off',
    "Parsed nosnapdir options correctly" );

