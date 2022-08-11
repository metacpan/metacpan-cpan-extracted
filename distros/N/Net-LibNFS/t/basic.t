#!/usr/bin/env perl

use strict;
use warnings;

use Net::LibNFS;

use Test::More;
use Test::FailWarnings -allow_deps => 1;
use Test::Fatal;

{
    my $obj = Net::LibNFS->new();
    isa_ok($obj, 'Net::LibNFS', 'return from new()');

    is(
        $obj->set( uid => 123 ),
        $obj,
        'set() returns the object',
    );

    my $err = exception {
        $obj->set(
            tcp_syncnt => 123,
            gid => 234,
            debug => 1,
            dircache => -77,
            autoreconnect => -9,
            timeout => -34,
        );
    };

    ok( !$err, 'set() integer values' ) or diag $err;

    #----------------------------------------------------------------------

    $err = exception { $obj->set( pagecache => -7 ) };
    like($err, qr<-7>, 'error if set()ting a negative to a u32 value' );

    $err = exception {
        $obj->set(
            pagecache => 123,
            pagecache_ttl => 0xffff_ffff,
            readahead => 0,
        );
    };

    ok( !$err, 'set() u32 values' ) or diag $err;

    #----------------------------------------------------------------------

    $err = exception { $obj->set( readmax => -7 ) };
    like($err, qr<-7>, 'error if set()ting a negative to a u64 value' );

    $err = exception {
        $obj->set(
            readmax => 123,
            writemax => 0xffff_ffff,
        );
    };

    ok( !$err, 'set() u64 values' ) or diag $err;

    #----------------------------------------------------------------------
    $err = exception { $obj->set( unix_authn => [123, 234] ) };
    is($err, undef, 'set(auxiliary_gids)');
}

done_testing;
