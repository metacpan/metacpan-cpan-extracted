#!/usr/bin/perl

# 
# Set setting and modifying the inheritance
#

use strict;
use warnings;

use Test::More ( tests => 18 );

BEGIN {
    use_ok( 'Sphinx::Config' );
}

my $c = Sphinx::Config->new;
isa_ok( $c, 'Sphinx::Config' );

my $FILE = "t/sphinx3.conf";
$c->parse( $FILE );
pass( "Didn't explode on $FILE" );

my $q;

##### change
$c->set( source => S1 => undef() => 'pgsql' );
$c->set( source => S1 => sql_pass => 'dw-password' );
$q = $c->get( source => S1 => 'type' );
is( $q, 'pgsql', "Changed inheritance" );
$q = $c->get( source => S1 => 'sql_pass' );
is( $q, 'dw-password', " ... and then changed a variable" );

$c->set( source => S2 => sql_pass => 'dw-password' );
$c->set( source => S2 => undef() => 'pgsql' );
$q = $c->get( source => S2 => 'type' );
is( $q, 'pgsql', "Changed inheritance" );
$q = $c->get( source => S2 => 'sql_pass' );
is( $q, 'dw-password', " ... but changed a variable before" );

# test of a multi-line edge case
$c->set( source => S3 => { sql_pass => 'other pass' } => 'pgsql' );
$q = $c->get( source => S3 => 'type' );
is( $q, 'pgsql', "Changed inheritance" );
$q = $c->get( source => S3 => 'sql_pass' );
is( $q, 'other pass', " ... and changed a variable at the same time" );

##### change and save
my $s = $c->as_string;
# warn $s;
$c->parse_string( $s );

$q = $c->get( source => S1 => 'type' );
is( $q, 'pgsql', "Inheritance saved" );
$q = $c->get( source => S1 => 'sql_pass' );
is( $q, 'dw-password', " ... along with changed variable" );

$q = $c->get( source => S2 => 'type' );
is( $q, 'pgsql', "Inheritance saved" );
$q = $c->get( source => S2 => 'sql_pass' );
is( $q, 'dw-password', " ... along with changed variable" );

# test of a multiple-line edge case
$q = $c->get( source => S3 => 'type' );
is( $q, 'pgsql', "Inheritance saved" );
$q = $c->get( source => S3 => 'sql_pass' );
is( $q, 'other pass', " ... and changed a variable at the same time" );

my $base = $c->get( source => S1 => '_inherit' );
is( $base, 'pgsql', "Inheritance changed" );
$base = $c->get( source => S2 => '_inherit' );
is( $base, 'pgsql', "Inheritance changed" );
$base = $c->get( source => S3 => '_inherit' );
is( $base, 'pgsql', "Inheritance changed" );
