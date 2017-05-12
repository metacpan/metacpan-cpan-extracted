#!/usr/bin/perl

use strict;
use warnings;

use POE;
use POE::Pipe::TwoWay;
use POE::Filter::Reference;
use POE::Filter::Stream;

use Test::More ( tests => 17 );

BEGIN { use_ok('POE::Wheel::Sendfile') };

my $W = bless [], 'POE::Wheel::Sendfile';
ok( $W, "Built object" );

#####
my $S = $W->_sendfile_setup( $0 );
is( $S->{offset}, 0, "Default offset" );
ok( $S->{size}, "Default size" );
ok( $S->{fh}, "Opened the file" );

#####
$S = $W->_sendfile_setup( { file=>$0, size=>1024 } );
is( $S->{offset}, 0, "Default offset" );
is( $S->{size}, 1024, "Kept size" );
ok( $S->{fh}, "Opened the file" );

#####
$S = $W->_sendfile_setup( { file=>$0, size=>1024, offset=>1024 } );
is( $S->{offset}, 1024, "Kept offset" );
is( $S->{size}, 2048, "Kept size" );
ok( $S->{fh}, "Opened the file" );

#####
my $fh = IO::File->new;
$fh->open( 't/bigfile' );
$S = $W->_sendfile_setup( $fh );
is( $S->{offset}, 0, "Default offset" );
is( $S->{size}, 1024*1024, "Found size" );
is( $S->{fh}, $fh, "Didn't need to open the file" );

#####
my ($a_read, $a_write, $b_read, $b_write) = POE::Pipe::TwoWay->new("inet");
$W->[1] = $b_write;
$POE::Wheel::Sendfile::HAVE_SENDFILE = 0;

$S = $W->_sendfile_setup( $fh );
is( $S->{offset}, 0, "Default offset" );
is( $S->{size}, 1024*1024, "Found size" );
ok( $S->{blocksize}, "Got a default blocksize" );

## these are to fake out the DESTROY method
$W->[1] = undef;
$W->[16] = 1;
