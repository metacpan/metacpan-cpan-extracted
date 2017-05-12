#!/usr/bin/perl

## no critic qw( Bangs::ProhibitVagueNames )

use 5.006;

use strict;
use warnings;

use Test::Most tests => 4;
use Test::NoWarnings;

BEGIN { use_ok( 'OpenVZ', ':all' ) }

my @expect_execute = (
    q{OpenVZ
OpenVZ.pm},
    q{},
    0,
    ignore(),
);

cmp_deeply( [ execute( { command => 'ls', params => ['lib'] } ) ], \@expect_execute, 'execute worked' );

throws_ok { OpenVZ->new } qr/OpenVZ is designed to be an abstract class/,
    'no object from OpenVZ'; ## no critic qw( Modules::RequireExplicitInclusion )
