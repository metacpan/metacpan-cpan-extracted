#!/usr/bin/perl

use v5.14;
use warnings;

use Future::AsyncAwait 0.47; # toplevel await

use Data::Dump 'pp';
use Getopt::Long;

use IO::Async::Loop;
use Net::Async::IRC;

GetOptions(
   'server|s=s' => \my $SERVER,
   'nick|n=s'   => \my $NICK,
   'pass=s'     => \my $PASS,
   'sasl'       => \my $USE_SASL,
   'port|p=i'   => \my $PORT,
   'SSL|S'      => \my $SSL,
) or exit 1;

require IO::Async::SSL if $SSL;

my $loop = IO::Async::Loop->new;

my $irc = Net::Async::IRC->new(
   on_message => sub {
      my ( $self, $command, $message, $hints ) = @_;
      return if $hints->{handled};

      printf "<<%s>>: %s\n", $command, join( " ", $message->args );
      print "| $_\n" for split m/\n/, pp( $hints );

      return 1;
   },
   use_caps => [
      ( $USE_SASL ? "sasl" : () ),
   ],
);
$loop->add( $irc );

$PORT //= ( $SSL ? 6697 : 6667 );

await $irc->connect(
   host    => $SERVER,
   service => $PORT,
   ( $SSL ?
      ( extensions => ['SSL'],
        SSL_verify_mode => 0 ) :
      () ),
);

print "Connected...\n";

await $irc->login(
   nick => $NICK,
   pass => $PASS,
);

print "Now logged in...\n";

my $stdin = IO::Async::Stream->new_for_stdin( on_read => sub {} );
$loop->add( $stdin );

while(1) {
   my ( $line, $eof ) = await $stdin->read_until( "\n" );
   last if $eof;

   chomp $line;
   next if !length $line;

   my $message = Protocol::IRC::Message->new_from_line( $line );
   $irc->send_message( $message );
}
