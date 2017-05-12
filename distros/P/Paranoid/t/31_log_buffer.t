#!/usr/bin/perl -T

use Test::More tests => 20;
use Paranoid;
use Paranoid::Log;
use Paranoid::Debug qw(:all);

use strict;
use warnings;

psecureEnv();

ok( startLogger( 'foo', 'Buffer', PL_WARN, PL_EQ ), 'startLogger 1' );
ok( plog( PL_WARN, 'this is a test' ), 'plog 1' );
is( scalar( Paranoid::Log::Buffer::dumpBuffer('foo') ), 1, 'dumpBuffer 1' );
my @msgs = Paranoid::Log::Buffer::dumpBuffer('foo');
is( $msgs[0][1], 'this is a test', 'check message 1' );
ok( plog( PL_CRIT, 'this is a test' ), 'plog 2' );
is( scalar( Paranoid::Log::Buffer::dumpBuffer('foo') ), 1, 'dumpBuffer 2' );
ok( startLogger( 'bar', 'Buffer', PL_WARN, PL_NE ), 'startLogger 2' );
ok( plog( PL_WARN, 'this is a test' ), 'plog 3' );
is( scalar( Paranoid::Log::Buffer::dumpBuffer('bar') ), 0, 'dumpBuffer 3' );
ok( plog( PL_CRIT, 'this is a test' ), 'plog 4' );
is( scalar( Paranoid::Log::Buffer::dumpBuffer('bar') ), 1, 'dumpBuffer 4' );
ok( plog( PL_DEBUG, 'this is a test' ), 'plog 5' );
is( scalar( Paranoid::Log::Buffer::dumpBuffer('bar') ), 2, 'dumpBuffer 5' );

for my $n ( 1 .. 50 ) {
    plog( PL_DEBUG, "test number $n" );
}
is( scalar( Paranoid::Log::Buffer::dumpBuffer('bar') ), 20, 'dumpBuffer 6' );
@msgs = Paranoid::Log::Buffer::dumpBuffer('bar');
is( $msgs[0][1],      'test number 31', 'check message 2' );
is( $msgs[$#msgs][1], 'test number 50', 'check message 3' );
ok( stopLogger('bar'), 'stopLogger 1' );
ok( startLogger( 'bar', 'Buffer', PL_WARN, PL_NE, { size => 30 } ),
    'startLogger 3' );
for my $n ( 1 .. 50 ) {
    plog( PL_DEBUG, "test number $n" );
}
@msgs = Paranoid::Log::Buffer::dumpBuffer('bar');
is( $msgs[0][1],      'test number 21', 'check message 4' );
is( $msgs[$#msgs][1], 'test number 50', 'check message 5' );

