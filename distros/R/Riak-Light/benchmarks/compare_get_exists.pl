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

my ( $host, $port ) = split ':', $ENV{RIAK_PBC_HOST};

my $riak_light_client1 =
  Riak::Light->new( host => $host, port => $port, timeout_provider => undef );

$riak_light_client1->put_raw(
    foo_riak_light1 => "key_$_" => "Loooooooooong Stringgggggggg $_" )
  for ( 0 .. 1024 );

cmpthese(
    3_000,
    {   "Riak::Light get_raw" => sub {
            $riak_light_client1->get_raw(
                foo_riak_light1 => 'key_' . int( rand(1500) ) );
        },
        "Riak::Light exists" => sub {
            $riak_light_client1->exists(
                foo_riak_light1 => 'key_' . int( rand(1500) ) );
        },
    }
);
