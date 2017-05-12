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
   pipeline => 0, # Disable pipelining or we'll break the tests
);

$loop->add( $http );

my @peersocks;

no warnings 'redefine';
local *IO::Async::Handle::connect = sub {
   my $self = shift;

   my ( $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $self->set_handle( $selfsock );
   push @peersocks, $peersock;

   return Future->new->done( $self );
};

foreach my $max ( 1, 2, 0 ) {
   $http->configure( max_connections_per_host => $max );

   my @done;
   foreach my $idx ( 0 .. 2 ) {
      $http->do_request(
         request => HTTP::Request->new( GET => "/" ),
         host => "myhost",
         on_response => sub { $done[$idx]++ },
         on_error    => sub { },
      )
   }

   ## First batch of requests looks the same in all cases

   my $expect_conns = $max || 3;
   is( scalar @peersocks, $expect_conns, "Expected number of connections for max=$max" );

   # Wait for all the pending requests to be written
   my @buffers;
   wait_for_stream { ($buffers[$_]||"") =~ m/$CRLF$CRLF/ } $peersocks[$_] => $buffers[$_] for 0 .. $#peersocks;
   $_ = "" for @buffers;

   # Write responses for all
   $_->syswrite( "HTTP/1.1 200 OK$CRLF" .
                 "Content-Length: 0$CRLF" . $CRLF ) for @peersocks;

   wait_for { $done[$_] } for 0 .. $expect_conns-1;

   if( $max == 1 ) {
      # The other two requests come over the same initial socket
      wait_for_stream { ($buffers[0]||"") =~ m/$CRLF$CRLF/ } $peersocks[0] => $buffers[0];
      $_ = "" for @buffers;
      $peersocks[0]->syswrite( "HTTP/1.1 200 OK$CRLF" .
                               "Content-Length: 0$CRLF" . $CRLF );
      wait_for { $done[1] };

      wait_for_stream { ($buffers[0]||"") =~ m/$CRLF$CRLF/ } $peersocks[0] => $buffers[0];
      $_ = "" for @buffers;
      $peersocks[0]->syswrite( "HTTP/1.1 200 OK$CRLF" .
                               "Content-Length: 0$CRLF" . $CRLF );
   }
   elsif( $max == 2 ) {
      # The third request will come over one of these $peersocks again, but we don't know which
      my $peersock;
      {
         $loop->watch_io( handle => $peersocks[0], on_read_ready => sub { $peersock = $peersocks[0] } );
         $loop->watch_io( handle => $peersocks[1], on_read_ready => sub { $peersock = $peersocks[1] } );
         wait_for { defined $peersock };
         $loop->unwatch_io( handle => $_, on_read_ready => 1 ) for @peersocks;
      }

      wait_for_stream { ($buffers[0]||"") =~ m/$CRLF$CRLF/ } $peersock => $buffers[0];
      $_ = "" for @buffers;
      $peersock->syswrite( "HTTP/1.1 200 OK$CRLF" .
                           "Content-Length: 0$CRLF" . $CRLF );
   }

   wait_for { $done[0] && $done[1] && $done[2] };
   ok( 1, "All three requests are now done for max=$max" );

   undef @peersocks;

   # CHEATING
   $_->remove_from_parent for @{ delete $http->{connections}{"myhost:80"} };
}

done_testing;
