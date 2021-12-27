#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::Listener;

use Encode qw( encode_utf8 );

use Net::Async::IRC;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

SKIP: foreach my $SSL ( 0, 1 ) {
   if( $SSL ) {
      eval { require IO::Async::SSL } or skip "No IO::Async::SSL", 1;
   }

   my $client;
   my $listener = IO::Async::Listener->new(
      on_stream => sub {
         ( undef, $client ) = @_;
      },
   );
   $loop->add( $listener );

   $listener->listen(
      addr => { family => "inet" },
      ( $SSL ?
         ( extensions => [ 'SSL' ],
           SSL_key_file  => "t/privkey.pem",
           SSL_cert_file => "t/server.pem", ) :
         () ),
   )->get;

   # Some OSes don't like connect()ing to 0.0.0.0
   ( my $listenhost = $listener->read_handle->sockhost ) =~ s/^0\.0\.0\.0$/127.0.0.1/;
   my $listenport = $listener->read_handle->sockport;

   my $irc = Net::Async::IRC->new(
      user => "defaultuser",
      realname => "Default Real name",

      encoding => "UTF-8",

      on_message => sub { "IGNORE" },

      on_irc_error => sub {},
   );
   $loop->add( $irc );

   $irc->connect(
      addr => {
         family => "inet",
         ip     => $listenhost,
         port   => $listenport,
      },
      ( $SSL ?
         ( extensions => [ 'SSL' ],
           SSL_verify_mode => 0 ) :
         () ),
   )->get;

   wait_for { $client };
   $client->configure( on_read => sub { 0 } );  # using read futures
   $loop->add( $client );

   $irc->send_message( "PRIVMSG", undef, "target", "Ĉu vi ĉi tio vidas?" );

   my $read_f = $client->read_until( $CRLF );
   wait_for { $read_f->is_ready };

   is( scalar $read_f->get, encode_utf8( "PRIVMSG target :Ĉu vi ĉi tio vidas?$CRLF" ),
      'Stream is encoded over ' . ( $SSL ? "SSL" : "plaintext" ) );

   $loop->remove( $irc );
   $loop->remove( $client );
   $loop->remove( $listener );
}

done_testing;
