#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Test::Exception;

use String::MatchInterpolate;

my $smi = String::MatchInterpolate->new( 'nm${NAME/\w+/}', allow_suffix => 1 );

ok( defined $smi, 'defined $smi with suffix' );

my $vars;

$vars = $smi->match( "nmMyName" );
is_deeply( $vars, { NAME => 'MyName', _suffix => '' }, 'matched with empty suffix' );

$vars = $smi->match( "nmMyName with values" );
is_deeply( $vars, { NAME => 'MyName', _suffix => ' with values' }, 'matched with suffix' );

is_deeply( [ $smi->match( "nmMyName and more" ) ], [ 'MyName', ' and more' ], 'matched with suffix in list context' );
