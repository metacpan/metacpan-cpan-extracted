#!/usr/bin/perl

# $Id: cache_file.t,v 1.3 2002/10/12 04:00:21 andreychek Exp $

use strict;
use Test::More  tests => 3;
use lib "./t";

use OpenPlugin();
use OpenPluginTests( "get_config" );

my $data = get_config( "exception", "cache_file", "log_log4perl" );

my $OP = OpenPlugin->new( config => { data => $data });

my $cache = {
    test    => "123",
    test2   => "Chinese Chicken Salad",
};

my $cache_id = $OP->cache->save( $cache );
ok( $cache_id, "Save Cache Data" );

my $fetched_cache = $OP->cache->fetch( $cache_id );

is_deeply( $cache, $fetched_cache, "Retrieve Cache Data" );

ok( $OP->cache->delete( $cache_id ), "Delete Cache Data" );
