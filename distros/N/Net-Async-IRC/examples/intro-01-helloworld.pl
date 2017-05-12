use strict;
use warnings;

use IO::Async::Loop;
use Net::Async::IRC;

my $loop = IO::Async::Loop->new;

my $irc = Net::Async::IRC->new;
$loop->add( $irc );

my $SERVER = "irc.example.net";
my $NICK = "MyNick";
my $TARGET = "TargetNick";

$irc->login(
   host => $SERVER,
   nick => $NICK,
)->then( sub {
   $irc->do_PRIVMSG(
      target => $TARGET,
      text   => "Hello, World"
   );
})->get;
