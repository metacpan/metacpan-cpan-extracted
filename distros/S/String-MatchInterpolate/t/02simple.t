#!/usr/bin/perl -w

use strict;
use Test::More tests => 28;
use Test::Exception;

use String::MatchInterpolate;

my $smi = String::MatchInterpolate->new( '/foo${FOO/\d+/}/bar${BAR/\d+/}' );

ok( defined $smi, 'defined $smi' );

is_deeply( [$smi->vars], [qw( FOO BAR )], 'vars list' );

my $vars;

$vars = $smi->match( "/foo12/bar150" );
is_deeply( $vars, { FOO => 12, BAR => 150 }, 'matched correct keys' );

is_deeply( [ $smi->match( "/foo34/bar567" ) ], [ 34, 567 ], 'match yields list of values in list context' );

$vars = $smi->match( "/fooLETTER/bar150" );
is( $vars, undef, 'subpattern fail produces undef' );

$vars = $smi->match( "/other" );
is( $vars, undef, 'literal mismatch produces undef' );

$vars = $smi->match( " some substring /foo8/bar19 with extra junk " );
is( $vars, undef, 'correct keys with junk' );

my $str;

$str = $smi->interpolate( { FOO => '85', BAR => '15' } );
is( $str, "/foo85/bar15", 'rebuilt string' );

$str = $smi->interpolate( 50, 300 );
is( $str, "/foo50/bar300", 'rebuilt string from list of values' );

$str = $smi->interpolate( { FOO => 'one', BAR => 'two' } );
is( $str, "/fooone/bartwo", 'rebuilt string with mismatch patterns' );

dies_ok( sub { String::MatchInterpolate->new( '${NUM/\d+/} + ${NUM/\d+/}' ) },
         'Duplicate variable name fails' );

$smi = String::MatchInterpolate->new( 'one ${/\d+/} two ${/\d+/}' );

ok( defined $smi, 'defined $smi (anonymous captures)' );

is_deeply( [$smi->vars], [qw( 1 2 )], 'vars list' );

is_deeply( [ $smi->match( "one 1 two 2" ) ], [ "1", "2" ], 'matched correct keys' );

is( $smi->interpolate( "3", "4" ), 'one 3 two 4', 'rebuilt string' );

$smi = String::MatchInterpolate->new( 'start ${BRACE/{foo}/} end' );

ok( defined $smi, 'defined $smi (nested braces in pattern)' );

is_deeply( [$smi->vars], [qw( BRACE )], 'vars list' );

$vars = $smi->match( "start {foo} end" );
is_deeply( $vars, { BRACE => '{foo}' }, 'matched correct keys' );

$smi = String::MatchInterpolate->new( 'literal {braces} with ${NAME/\w+/}' );

ok( defined $smi, 'defined $smi (literal braces)' );

is_deeply( [$smi->vars], [qw( NAME )], 'vars list' );

$vars = $smi->match( "literal {braces} with data" );
is_deeply( $vars, { NAME => 'data' }, 'matched correct keys' );

$smi = String::MatchInterpolate->new( 'literal $ ${SIGN/\w+/}' );

ok( defined $smi, 'defined $smi (literal dollar)' );

is_deeply( [$smi->vars], [qw( SIGN )], 'vars list' );

$vars = $smi->match( 'literal $ dollar' );
is_deeply( $vars, { SIGN => 'dollar' }, 'matched correct keys' );

$smi = String::MatchInterpolate->new( 'example \${NAME/pattern/}' );

ok( defined $smi, 'defined $smi (escaped dollar)' );

is_deeply( [$smi->vars], [], 'vars list' );

$vars = $smi->match( 'example ${NAME/pattern/}' );
is_deeply( $vars, { }, 'matched correct keys' );

$smi = String::MatchInterpolate->new( 'literal \\\\${NAME/\w+/}' );

is( $smi->interpolate( { NAME => "name" } ), "literal \\name", 'escaped backslash parsed OK' );
