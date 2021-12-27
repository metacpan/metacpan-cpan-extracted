#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;
use IO::Async::Stream;

use Net::Async::IRC;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

# CAP SASL login
{
   my $irc = Net::Async::IRC->new(
      handle => $S1,
      use_caps => [qw( sasl )],
   );
   $loop->add( $irc );

   my $login_f = $irc->login(
      nick => "MyNick",
      user => "me",
      pass => "s3kr1t",
      realname => "My real name",
   );

   $login_f->on_fail( sub { die "Test failed early: @_" } );

   my $serverstream = "";
   wait_for_stream { $serverstream =~ m/(?:.*$CRLF){2}/ } $S2 => $serverstream;

   is( $serverstream, "CAP LS$CRLF" .
                      "NICK MyNick$CRLF",
                      'Server stream negotiates CAP' );
   $serverstream = "";

   $S2->syswrite( ':irc.example.com CAP * LS :multi-prefix sasl' . $CRLF );

   wait_for_stream { $serverstream =~ m/.*$CRLF/ } $S2 => $serverstream;

   is( $serverstream, "CAP REQ sasl$CRLF", 'Client requests caps' );
   $serverstream = "";

   is_deeply( $irc->caps_supported,
              { 'multi-prefix' => 1,
                'sasl'         => 1 },
              '$irc->caps_supported' );
   ok( $irc->cap_supported( "sasl" ), '$irc->cap_supported' );

   $S2->syswrite( ':irc.example.com CAP * ACK :sasl' . $CRLF );

   wait_for_stream { $serverstream =~ m/(?:.*$CRLF){2}/ } $S2 => $serverstream;

   is( $serverstream, "USER me 0 * :My real name$CRLF" .
                      "AUTHENTICATE PLAIN$CRLF", 'Client starts SASL' );
   $serverstream = "";

   is_deeply( $irc->caps_enabled,
              { 'sasl' => 1 },
              '$irc->caps_enabled' );
   ok( $irc->cap_enabled( "sasl" ), '$irc->cap_enabled' );

   $S2->syswrite( ':irc.example.com AUTHENTICATE +' . $CRLF );

   wait_for_stream { $serverstream =~ m/(?:.*$CRLF){1}/ } $S2 => $serverstream;

   # base64 encoded "MyNick\0MyNick\0s3kr1t"
   is( $serverstream, "AUTHENTICATE TXlOaWNrAE15TmljawBzM2tyMXQ=$CRLF", 'Client completes SASL' );
   $serverstream = "";

   $S2->syswrite( ':irc.example.com 903 MyNick :SASL authentication successful' . $CRLF );

   wait_for_stream { $serverstream =~ m/(?:.*$CRLF){1}/ } $S2 => $serverstream;

   is( $serverstream, "CAP END$CRLF", 'Client ends CAP' );
   $serverstream = "";

   $S2->syswrite( ':irc.example.com 001 MyNick :Welcome to IRC MyNick!me@your.host' . $CRLF );

   wait_for { $login_f->is_ready };
   $login_f->get;

   $loop->remove( $irc );
}

# SASL unsupported by server
{
   my $irc = Net::Async::IRC->new(
      handle => $S1,
      use_caps => [qw( sasl )],
   );
   $loop->add( $irc );

   my $login_f = $irc->login(
      nick => "MyNick",
      user => "me",
      pass => "s3kr1t",
      realname => "My real name",
   );

   $login_f->on_fail( sub { die "Test failed early: @_" } );

   my $serverstream = "";
   wait_for_stream { $serverstream =~ m/(?:.*$CRLF){2}/ } $S2 => $serverstream;

   is( $serverstream, "CAP LS$CRLF" .
                      "NICK MyNick$CRLF",
                      'Server stream negotiates CAP' );
   $serverstream = "";

   $S2->syswrite( ':irc.example.com CAP * LS :multi-prefix' . $CRLF );

   wait_for_stream { $serverstream =~ m/.*$CRLF/ } $S2 => $serverstream;

   is( $serverstream, "CAP END$CRLF" .
                      "PASS s3kr1t$CRLF" .
                      "USER me 0 * :My real name$CRLF", 'Client ends CAP and authenticates normally' );
   $serverstream = "";

   ok( !$irc->cap_supported( "sasl" ), '$irc->cap_supported SASL no' );

   $S2->syswrite( ':irc.example.com 001 MyNick :Welcome to IRC MyNick!me@your.host' . $CRLF );

   wait_for { $login_f->is_ready };
   $login_f->get;

   $loop->remove( $irc );
}

done_testing;
