#!/usr/bin/perl

use Test::More tests => 9;
use Carp;

use strict;
use warnings;

use HTTP::Request;
use HTTP::Response;

use FindBin;
use lib "$FindBin::Bin/lib";
use Mock::Filesys;

use Net::DAV::Server ();

{
    my $dav = Net::DAV::Server->new();
    my $res = $dav->options( HTTP::Request->new(), HTTP::Response->new( 200 ) );
    isa_ok( $res, 'HTTP::Response' );
    is( $res->header('MS-Author-Via'), 'DAV', 'No FS: Microsoft author header' );
    is( $res->header( 'DAV' ), '1,2,<http://apache.org/dav/propset/fs/1>', 'No FS: Capability header is correct.' );
    is_deeply(
        [ sort split /,\s*/, $res->header('Allow') ],
        [ qw/COPY DELETE GET HEAD LOCK MKCOL MOVE OPTIONS POST PROPFIND PUT UNLOCK/ ],
        'No FS: Expected methods are allowed.'
    );
}

{
    my $dav = Net::DAV::Server->new();
    $dav->filesys( Mock::Filesys->new() );
    my $res = $dav->options( HTTP::Request->new(), HTTP::Response->new( 200 ) );
    isa_ok( $res, 'HTTP::Response' );
    isa_ok( $dav->filesys, 'Mock::Filesys' );
    is( $res->header('MS-Author-Via'), 'DAV', 'FS: Microsoft author header' );
    is( $res->header( 'DAV' ), '1,2,<http://apache.org/dav/propset/fs/1>', 'FS: Capability header is correct.' );
    is_deeply(
        [ sort split /,\s*/, $res->header('Allow') ],
        [ qw/COPY DELETE GET HEAD LOCK MKCOL MOVE OPTIONS POST PROPFIND PUT UNLOCK/ ],
        'FS: Expected methods are allowed.'
    );
}
