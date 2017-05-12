#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::HTTP;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new(
   user_agent => "", # Don't put one in request headers
);

$loop->add( $http );

# connect errors
{
   my @on_connect_errors;

   no warnings 'redefine';
   local *IO::Async::Handle::connect = sub {
      my $self = shift;
      my %args = @_;

      my $f = $self->loop->new_future;

      push @on_connect_errors, sub { $f->fail( @_ ) };

      return $f;
   };

   my $f1 = $http->do_request(
      uri => URI->new( "http://hostname/first" ),
   );
   my $f2 = $http->do_request(
      uri => URI->new( "http://hostname/second" ),
   );

   is( scalar @on_connect_errors, 1, '1 on_connect_errors queued before first connect error' );
   ok( !$f1->is_ready, '$f1 still pending before connect error' );

   ( shift @on_connect_errors )->( connect => "No route to host" );

   wait_for { $f1->is_ready };
   is( scalar $f1->failure, "hostname:80 - connect failed [No route to host]", '$f1->failure' );

   is( scalar @on_connect_errors, 1, '1 on_connect_errors queued before second connect error' );
   ok( !$f2->is_ready, '$f2 still pending before connect error' );

   ( shift @on_connect_errors )->( connect => "No route to host" );

   wait_for { $f2->is_ready };
   is( scalar $f2->failure, "hostname:80 - connect failed [No route to host]", '$f2->failure' );
}

done_testing;
