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
use Benchmark::Forking qw(timethis timethese cmpthese);

use Net::Riak;
use Riak::Light;

die "please set the RIAK_PBC_HOST variable" unless $ENV{RIAK_PBC_HOST};

my $hash = { baz => 1024, boom => [ 1, 2, 3, 4, 5, 1000 ] };

my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

#
# prepare Riak::Light client
#
my $riak_light_client0 =
  Riak::Light->new( host => $host, port => $port, autodie => 0 );

my $riak_light_client1 =
  Riak::Light->new( host => $host, port => $port, autodie => 1 );

$riak_light_client0->put( foo_riak_light0 => key => $hash );
$riak_light_client1->put( foo_riak_light1 => key => $hash );
$riak_light_client1->put( foo_riak_light2 => key => $hash );

cmpthese(
    5_000,
    {   "Riak::Light die=0" => sub {
            $riak_light_client0->get( foo_riak_light0 => 'key' );
        },
        "Riak::Light die=1" => sub {
            $riak_light_client1->get( foo_riak_light1 => 'key' );
        },
        "Riak::Light die=1 +eval" => sub {
            eval { $riak_light_client1->get( foo_riak_light2 => 'key' ) };
        },
    }
);
