#!/usr/bin/perl -w

use strict;

use Test::More ( tests => 14 );

BEGIN { use_ok( "POE::Component::Daemon" ) }

# diag( "POE is $INC{'POE.pm'} ($POE::VERSION)" );

#########################################################
my $daemon = POE::Component::Daemon->new( {
        start_children  => 10
    } );

$daemon->default_min_max;

is( $daemon->{min_spare}, 10, "min_spare = start_children" );
is( $daemon->{max_spare}, 20, "max_spare = 2*start_children" );
is( $daemon->{max_children}, 30, "max_children = start_children +max_spare" );

ok( $daemon->{alias}, "Set an alias" );

#########################################################
$daemon = POE::Component::Daemon->new(
        start_children  => 3,
        max_children => 10,
        alias        => 'Foo'
    );

$daemon->default_min_max;

ok( $daemon->{min_spare}, "min_spare is set" );
ok( $daemon->{max_spare}, "max_spare is set" );
ok( ( $daemon->{min_spare} < $daemon->{max_spare} ), 
            "max_spare is more then min_spare" );
is( $daemon->{alias}, 'Foo', "Set an alias" );
is( $daemon->is_prefork, 1, "Pre-forking server" );
is( $daemon->is_fork, !1, "Not a forking server" );

my $pid=$$;
$daemon->detach;
$daemon->detach;
is( $$, $pid, "Didn't detach, even when asked twice" );

#########################################################
$daemon = POE::Component::Daemon->new(
        max_children => 10,
    );

is( $daemon->is_prefork, !1, "Not a pre-forking server" );
is( $daemon->is_fork, 1, "Is a forking server" );
