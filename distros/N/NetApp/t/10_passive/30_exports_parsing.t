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

my @lines = split /\n+/, <<'__lines__';
/vol/volume1	-sec=sys,rw
/vol/otherpath	-actual=/vol/volume2,rw=a:b:c:d,root=e:f:g:h
/vol/volume3	-sec=sec:krb5,ro,nosuid
/vol/volume4	-sec=sys,ro=a:b:c:d
__lines__

my $export = NetApp::Filer::Export->_parse_export( $lines[0] );

ok( $export->{path} eq '/vol/volume1',
    "1st entry has correct path: '$export->{path}'" );
ok( ref $export->{sec} eq 'ARRAY' &&
        scalar @{ $export->{sec} } == 1 &&
            $export->{sec}->[0] eq 'sys',
    "1st entry has correct sec value: '$export->{sec}'" );
ok( $export->{rw_all} == 1,
    "1st entry has correct rw_all value: '$export->{rw_all}'" );
if ( exists $export->{rw} ) {
    ok( 0, "1st entry has bogus rw value: '$export->{rw}'" );
} else {
    ok( 1, "1st entry does NOT have rw value at all" );
}

$export = NetApp::Filer::Export->_parse_export( $lines[1] );

ok( $export->{path} eq '/vol/otherpath',
    "2nd entry has correct path: '$export->{path}'" );
ok( $export->{actual} eq '/vol/volume2',
    "2nd entry has correcy actual: '$export->{actual}'" );
ok( ref $export->{rw} eq 'ARRAY' &&
        scalar @{ $export->{rw} } == 4 &&
            $export->{rw}->[0] eq 'a' &&
                $export->{rw}->[1] eq 'b' &&
                    $export->{rw}->[2] eq 'c' &&
                        $export->{rw}->[3] eq 'd',
    "2nd entry has correct rw value: '$export->{rw}'" );
ok( ref $export->{root} eq 'ARRAY' &&
        scalar @{ $export->{root} } == 4 &&
            $export->{root}->[0] eq 'e' &&
                $export->{root}->[1] eq 'f' &&
                    $export->{root}->[2] eq 'g' &&
                        $export->{root}->[3] eq 'h',
    "2nd entry has correct rw value: '$export->{root}'" );

$export = NetApp::Filer::Export->_parse_export( $lines[2] );

ok( $export->{path} eq '/vol/volume3',
    "3rd entry has correct path: '$export->{path}'" );
ok( ref $export->{sec} eq 'ARRAY' &&
        scalar @{ $export->{sec} } == 2 &&
            $export->{sec}->[0] eq 'sec' &&
                $export->{sec}->[1] eq 'krb5',
    "3rd entry has correct sec value: '$export->{sec}'" );
ok( $export->{ro_all} == 1,
    "3rd entry has correct ro_all value: '$export->{ro_all}'" );
if ( exists $export->{ro} ) {
    ok( 0, "3rd entry has bogus ro value: '$export->{ro}'" );
} else {
    ok( 1, "3rd entry does NOT have ro value at all" );
}
ok( $export->{nosuid} == 1,
    "3rd entry has correct nosuid value: '$export->{nosuid}'" );

$export = NetApp::Filer::Export->_parse_export( $lines[3] );

ok( $export->{path} eq '/vol/volume4',
    "4th entry has correct path: '$export->{path}'" );
ok( ref $export->{ro} eq 'ARRAY' &&
        scalar @{ $export->{ro} } == 4 &&
            $export->{ro}->[0] eq 'a' &&
                $export->{ro}->[1] eq 'b' &&
                    $export->{ro}->[2] eq 'c' &&
                        $export->{ro}->[3] eq 'd',
    "2nd entry has correct ro value: '$export->{ro}'" );
