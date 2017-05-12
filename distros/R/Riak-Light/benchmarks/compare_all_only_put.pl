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

use Time::Out qw(timeout);
use Time::HiRes;
use JSON;

use Net::Riak;
use Data::Riak;
use Data::Riak::Fast;
use Riak::Tiny;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Riak::Light;

die "please set the RIAK_PBC_HOST variable"  unless $ENV{RIAK_PBC_HOST};
die "please set the RIAK_REST_HOST variable" unless $ENV{RIAK_REST_HOST};

# variables

my ( $host_pbc, $port_pbc ) = split ':', $ENV{RIAK_PBC_HOST};
my $http_host = $ENV{RIAK_REST_HOST};
my $hash = { baz => 1024, boom => [ 1, 2, 3, 4, 5, 1000, rand(1024) ] };

#clients

my $riak_light_client1 = Riak::Light->new(
    host             => $host_pbc, port => $port_pbc,
    timeout_provider => undef
);

$riak_light_client1->put( foo_riak_light1 => key => $hash );

my $net_riak_client1 = Net::Riak->new(
    transport => 'PBC',
    host      => $host_pbc,
    port      => $port_pbc
);
my $net_riak_bucket1 = $net_riak_client1->bucket('foo_net_riak1');

$net_riak_bucket1->new_object( key => $hash )->store;

my $net_riak_client2 = Net::Riak->new(
    transport => 'REST',
    host      => $http_host,
);
my $net_riak_bucket2 = $net_riak_client2->bucket('foo_net_riak2');

$net_riak_bucket2->new_object( key => $hash )->store;

my $data_riak_client = Data::Riak->new(
    {   transport => Data::Riak::HTTP->new(
            {   host    => '127.0.0.1',
                port    => '8098',
                timeout => 5
            }
        )
    }
);

my $data_riak_bucket = Data::Riak::Bucket->new(
    {   name => 'foo_data_riak',
        riak => $data_riak_client
    }
);

$data_riak_bucket->add( key => encode_json($hash) );

my $data_riak_fast_client = Data::Riak::Fast->new(
    {   transport => Data::Riak::Fast::HTTP->new(
            {   host    => '127.0.0.1',
                port    => '8098',
                timeout => 5
            }
        )
    }
);

my $data_riak_fast_bucket = Data::Riak::Fast::Bucket->new(
    {   name => 'foo_data_riak_fast',
        riak => $data_riak_fast_client
    }
);

$data_riak_fast_bucket->add( key => encode_json($hash) );

my $riak_tiny_client = Riak::Tiny->new( host => 'http://127.0.0.1:8098' );

cmpthese(
    4_000,
    {   "Riak::Tiny (REST)" => sub {
            my $key = "key" . int( rand(1024) );
            $riak_tiny_client->new_object(
                foo_riak_tiny => $key => encode_json($hash) );
        },
        "Data::Riak (REST)" => sub {
            my $key = "key" . int( rand(1024) );
            $data_riak_bucket->add( $key => encode_json($hash) );
        },
        "Data::Riak::Fast (REST)" => sub {
            my $key = "key" . int( rand(1024) );
            $data_riak_fast_bucket->add( $key => encode_json($hash) );
        },
        "Riak::Light (PBC)" => sub {
            my $key = "key" . int( rand(1024) );
            $riak_light_client1->put( foo_riak_light1 => $key => $hash );
        },
        "Net::Riak (PBC)" => sub {
            my $key = "key" . int( rand(1024) );
            $net_riak_bucket1->new_object( $key => $hash )->store;
        },
        "Net::Riak (REST)" => sub {
            my $key = "key" . int( rand(1024) );
            $net_riak_bucket2->new_object( $key => $hash )->store;
        },
    }
);
