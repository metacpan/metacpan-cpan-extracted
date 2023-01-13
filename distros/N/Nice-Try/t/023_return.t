#!perl
use strict;
use warnings;
use lib './lib';
use Test::More;
plan tests => 14;
our $t = 0;
our $f = 0;
use Nice::Try;
my $should_be_undef;
# try { $i++ } catch { }
my $rv = (sub{ 
    try { return "OK" }catch{$should_be_undef="catch: unreachable code";$t++} finally {$f++;} 
    $t++; # should not be called
})->();
is( $t, 0, 'try-catch return' );
ok( !defined( $should_be_undef ) );
is( $f, 1, 'finally called' );
is( $rv, 'OK', 'return value' );

$t = $f = 0;
# Void context
(sub{ 
    try { return "OK" }catch{$should_be_undef="catch: unreachable code";$t++} finally {$f++;}
    $t++; # should not be called
})->();
is( $t, 0, 'try-catch return' );
ok( !defined( $should_be_undef ) );
is( $f, 1, 'finally called' );

$t = $f = 0;
$_ = (sub{ 
    try { die "OK";$should_be_undef="try: unreachable code"; }catch{return "OK"; $t++;} finally {$f++;} 
    $t++; # should not be called
})->();
is( $t, 0, 'try-catch return' );
ok( !defined( $should_be_undef ) );
is( $f, 1, 'finally called' );
is( $rv, 'OK', 'return value' );

$t = $f = 0;
# Void context
(sub{ 
    try { die "OK";$should_be_undef="try: unreachable code"; }catch{return "OK";$t++;} finally {$f++;}
    $t++; # should not be called
})->();
is( $t, 0, 'try-catch return' );
ok( !defined( $should_be_undef ) );
is( $f, 1, 'finally called' );

