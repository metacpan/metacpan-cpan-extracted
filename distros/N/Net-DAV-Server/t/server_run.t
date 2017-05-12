#!/usr/bin/perl

use Test::More tests => 7;
use Carp;

use strict;
use warnings;

use Net::DAV::Server ();

use FindBin;
use lib "$FindBin::Bin/lib";
use Mock::Filesys;

{
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new() );
    my $res = $dav->run( HTTP::Request->new( OPTIONS => '/' ) );
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
    my $res = eval { $dav->run( HTTP::Request->new( OPTIONS => '/' ) ); };
    ok( !defined $res, 'Run exceptions if no filesys.' );
}

{
    my $dav = Net::DAV::Server->new( -filesys => Mock::Filesys->new() );
    my $res = $dav->run( HTTP::Request->new( XYZZY => '/' ) );
    isa_ok( $res, 'HTTP::Response' );
    is( $res->code, 501, 'Bad method => "not implemented"' );
}
