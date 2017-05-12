#!/usr/bin/perl

use Test::More tests => 3;
use Carp;

use strict;
use warnings;

use HTTP::Request;
use HTTP::Response;

use Net::DAV::Server ();

my $dav = Net::DAV::Server->new();

isa_ok( $dav, 'Net::DAV::Server' );
can_ok( $dav, qw/options put get head delete mkcol post propfind copy lock unlock move/ );
ok( !defined eval { $dav->can( 'trace' ); }, 'The trace method is not supported.' );
