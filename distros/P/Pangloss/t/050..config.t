#!/usr/bin/perl

##
## Tests for Pangloss::Config
##

use blib;
use strict;
#use warnings;

use Test::More 'no_plan';

BEGIN { use_ok("Pangloss::Config") }

Pangloss::Config->set_default_for( 'PG_HOME', sub { 't' } );
my $C = Pangloss::Config->new( {PG_PIXIE_DSN => 'foo'} );

ok( exists $C->{$_}, "$_=$C->{$_}" ) for $C->config_vars;
is( $C->{PG_PIXIE_DSN}, 'foo', 'expected PG_PIXIE_DSN' );
is( $C->{PG_HOME},      't',   'expected PG_HOME' );

