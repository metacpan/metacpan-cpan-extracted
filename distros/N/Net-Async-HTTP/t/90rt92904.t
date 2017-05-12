#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::HTTP;

my $loop = IO::Async::Loop->new;
testing_loop( $loop );

my $http = Net::Async::HTTP->new(
    max_connections_per_host => 2,
);

$loop->add( $http );

my @conn_f;
no warnings 'redefine';
local *IO::Async::Loop::connect = sub {
   shift;
   my %args = @_;
   $args{host} eq "localhost" or die "Cannot fake connect - expected host 'localhost'";
   $args{service} eq "5000"   or die "Cannot fake connect - expected service '5000'";

   push @conn_f, my $f = $loop->new_future;
   return $f;
};

my @f = map { $http->do_request(uri=>'http://localhost:5000/') } 0 .. 1;

is( scalar @conn_f, 2, 'Two pending connect() attempts after two concurrent ->do_request' );

# Fail them both
( shift @conn_f )->fail( "Connection refused", connect => ) for 0 .. 1;

ok( $f[$_]->is_ready && $f[$_]->failure, "Request [$_] Future fails after connect failure" ) for 0 .. 1;

ok( !@conn_f, 'No more pending connect() attempts' );

done_testing;
