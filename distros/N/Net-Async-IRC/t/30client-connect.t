#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::Listener;

use Net::Async::IRC;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $client;
my $listener = IO::Async::Listener->new(
   on_stream => sub {
      ( undef, $client ) = @_;
   },
);
$loop->add( $listener );

$listener->listen(
   addr => { family => "inet" },
)->get;

my @errors;

my $irc = Net::Async::IRC->new(
   user => "defaultuser",
   realname => "Default Real name",

   on_message => sub { "IGNORE" },

   on_irc_error => sub {
      my $self = shift;
      my ( $err ) = @_;

      push @errors, $err;
   },
);

$loop->add( $irc );

ok( !$irc->is_connected, 'not $irc->is_connected' );

$irc->connect(
   addr => {
      family => "inet",
      ip     => $listener->read_handle->sockhost,
      port   => $listener->read_handle->sockport,
   },
)->get;

ok( $irc->is_connected, '$irc->is_connected' );
ok( !$irc->is_loggedin, 'not $irc->is_loggedin' );

wait_for { $client };
$client->configure( on_read => sub { 0 } );  # using read futures
$loop->add( $client );

# Now see if we can send a message
$irc->send_message( "HELLO", undef, "world" );

my $read_f;

$read_f = $client->read_until( $CRLF );
wait_for { $read_f->is_ready };

is( scalar $read_f->get, "HELLO world$CRLF", 'Server stream after initial client message' );

my $logged_in = 0;

my $login_f = $irc->login(
   nick => "MyNick",

   on_login => sub { $logged_in = 1 },
);

$read_f = $client->read_until( qr/$CRLF.*$CRLF/ );
wait_for { $read_f->is_ready };

is( scalar $read_f->get,
   "USER defaultuser 0 * :Default Real name$CRLF" .
      "NICK MyNick$CRLF",
   'Server stream after login' );

$client->write( ":irc.example.com 001 MyNick :Welcome to IRC MyNick!defaultuser\@your.host.here$CRLF" );

wait_for { $login_f->is_ready };

ok( !$login_f->failure, 'Client logs in without failure' );

ok( $logged_in, 'Client receives logged in event' );
ok( $irc->is_connected, '$irc->is_connected' );
ok( $irc->is_loggedin, '$irc->is_loggedin' );

$client->write( ":something invalid-here$CRLF" );

wait_for { scalar @errors };

ok( defined shift @errors, 'on_error invoked' );

done_testing;
