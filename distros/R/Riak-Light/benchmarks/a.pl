#
# This file is part of Riak-Light
#
# This software is copyright (c) 2013 by Weborama.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
use Test::More tests => 2;

use Net::Riak;
use Riak::Light;

die "please set the RIAK_PBC_HOST variable" unless $ENV{RIAK_PBC_HOST};

my $hash = { baz => 1024, boom => [ 1, 2, 3, 4, 5, 1000 ] };

my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

#
# prepare Riak::Light client
#
my $riak_light_client = Riak::Light->new( host => $host, port => $port );
$riak_light_client->put( foo_riak_light => key => $hash );
is_deeply( $riak_light_client->get( foo_riak_light => 'key' ), $hash );

#
# prepare Net::Riak client
#
my $net_riak_client = Net::Riak->new(
    transport => 'PBC',
    host      => $host,
    port      => $port
);

my $net_riak_bucket = $net_riak_client->bucket('foo_net_riak');
$net_riak_client->bucket('foo_net_riak')->new_object( key => $hash )->store;
is_deeply( $net_riak_bucket->get('key')->data, $hash );
