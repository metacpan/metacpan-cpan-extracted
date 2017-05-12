#!/usr/bin/perl -w

use strict;

use Test::More tests => 10;
use Test::Refcount;

use Net::LibAsyncNS;
use Net::LibAsyncNS::Constants qw( NI_NUMERICHOST NI_NUMERICSERV );

use Socket qw( pack_sockaddr_in INADDR_LOOPBACK );

sub notall { $_ or return 1 for @_; return 0 }

my $asyncns = Net::LibAsyncNS->new( 3 );

my @done;
my @queries = map {
   my $query = $asyncns->getnameinfo( pack_sockaddr_in( $_, INADDR_LOOPBACK ), NI_NUMERICHOST|NI_NUMERICSERV, 1, 1 );

   push @done, undef;
   $query->setuserdata( \$done[-1] );

   $query;
} 12345, 12346, 12347;

is_refcount( $queries[$_], 2, "\$queries[$_] has refcount 2 initially" ) for  0 .. $#queries;

while( notall @done ) {
   $asyncns->wait( 1 );
   while( my $query = $asyncns->getnext ) {
      is( ref $query, "Net::LibAsyncNS::Query", '$query isa Net::LibAsyncNS::Query' );

      my $doneref = $query->getuserdata;
      my ( $err, $host, $service ) = $asyncns->getnameinfo_done( $query );

      is( $err+0, 0, '$query gave no error' );

      $$doneref = [ $host, $service ];
   }
}

is_deeply( \@done,
           [ [ "127.0.0.1", 12345 ],
             [ "127.0.0.1", 12346 ],
             [ "127.0.0.1", 12347 ] ],
           'Queries gave the right answers' );
