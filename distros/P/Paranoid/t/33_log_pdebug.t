#!/usr/bin/perl -T

use Test::More tests => 5;
use Paranoid;
use Paranoid::Log;
use Paranoid::Debug qw(:all);

use strict;
use warnings;

psecureEnv();

my @msgs;

ok( startLogger( 'pdebug', 'PDebug' ), 'startLogger 1' );
ok( startLogger( 'buffer', 'Buffer', PL_WARN, PL_NE, { size => 30 } ),
    'startLogger 2' );
for my $n ( 1 .. 10 ) {
    plog( PL_DEBUG, "test number $n" );
}
@msgs = Paranoid::Log::Buffer::dumpBuffer('buffer');
is( $msgs[9][1], 'test number 10', 'check message 1' );

for my $n ( 1 .. 10 ) {
    plog( PL_DEBUG, 'sprintf test number %s', $n );
}
@msgs = Paranoid::Log::Buffer::dumpBuffer('buffer');
is( $msgs[19][1], 'sprintf test number 10', 'check message 2' );

for my $n ( 1 .. 10 ) {
    plog( PL_DEBUG, 'no sprintf test number %s' );
}
@msgs = Paranoid::Log::Buffer::dumpBuffer('buffer');
is( $msgs[29][1], 'no sprintf test number %s', 'check message 3' );

