#!/usr/bin/perl -T

use Test::More tests => 9;
use Paranoid;
use Paranoid::Debug;

use strict;
use warnings;

psecureEnv();

my $msg = 'This is a test';
my $out;

ok( $out = pdebug($msg), 'pdebug 1' );
ok( $out = pdebug( $msg, 1, qw(foo bar) ), 'pdebug 2' );
ok( $out =~ m#$msg$#sm, 'pdebug 3' );

$msg = 'This is a %s test of %s';
ok( $out = pdebug($msg), 'pdebug 4' );
ok( $out =~ m#This is a undef test of undef$#sm, 'pdebug 5' );
ok( $out = pdebug( $msg, 1, qw(foo bar) ), 'pdebug 6' );
ok( $out =~ m#This is a foo test of bar$#sm, 'pdebug 7' );
$msg = 'This is a %s test of %.3f';
ok( $out = pdebug( $msg, 1, qw(foo bar) ), 'pdebug 8' );
ok( $out =~ m#This is a foo test of 0.000$#sm, 'pdebug 9' );

