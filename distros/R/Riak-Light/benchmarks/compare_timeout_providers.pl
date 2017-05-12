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
use Time::Out qw(timeout);
use Time::HiRes;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Riak::Light;

die "please set the RIAK_PBC_HOST variable" unless $ENV{RIAK_PBC_HOST};

my $hash = { baz => 1024, boom => [ 1, 2, 3, 4, 5, 1000 ] };

my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

my $riak_light_client1 =
  Riak::Light->new( host => $host, port => $port, timeout_provider => undef );
my $riak_light_client2 = Riak::Light->new(
    host             => $host, port => $port,
    timeout_provider => 'Riak::Light::Timeout::Alarm'
);
my $riak_light_client3 = Riak::Light->new(
    host             => $host, port => $port,
    timeout_provider => 'Riak::Light::Timeout::Select'
);
my $riak_light_client4 = Riak::Light->new(
    host             => $host, port => $port,
    timeout_provider => 'Riak::Light::Timeout::SelectOnRead'
);
my $riak_light_client5 = Riak::Light->new(
    host             => $host, port => $port,
    timeout_provider => 'Riak::Light::Timeout::SetSockOpt'
);
my $riak_light_client6 = Riak::Light->new(
    host             => $host, port => $port,
    timeout_provider => 'Riak::Light::Timeout::TimeOut'
);

$riak_light_client1->put( foo_riak_light1 => key => $hash );
$riak_light_client2->put( foo_riak_light2 => key => $hash );
$riak_light_client3->put( foo_riak_light3 => key => $hash );
$riak_light_client4->put( foo_riak_light4 => key => $hash );
$riak_light_client5->put( foo_riak_light5 => key => $hash );
$riak_light_client6->put( foo_riak_light6 => key => $hash );

my $net_riak_client = Net::Riak->new(
    transport => 'PBC',
    host      => $host,
    port      => $port
);
my $net_riak_bucket = $net_riak_client->bucket('foo_net_riak');

$net_riak_client->bucket('foo_net_riak')->new_object( key => $hash )->store;

cmpthese(
    3_000,
    {   "Riak::Light 1" => sub {
            $riak_light_client1->get( foo_riak_light1 => 'key' );
        },
        "Riak::Light 2" => sub {
            $riak_light_client2->get( foo_riak_light2 => 'key' );
        },
        "Riak::Light 3" => sub {
            $riak_light_client3->get( foo_riak_light3 => 'key' );
        },
        "Riak::Light 4" => sub {
            $riak_light_client4->get( foo_riak_light4 => 'key' );
        },
        "Riak::Light 5" => sub {
            $riak_light_client5->get( foo_riak_light5 => 'key' );
        },
        "Riak::Light 6" => sub {
            $riak_light_client6->get( foo_riak_light6 => 'key' );
        },

#  "Net::Riak 1" => sub  { $net_riak_bucket->get('key')->data; },
#  "Net::Riak 2" => sub  { timeout 0.5 => sub { $net_riak_bucket->get('key')->data; } },
    }
);
