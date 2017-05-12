#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;

use Encode qw( encode_utf8 );

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my @textmessages;
my @quitmessages;
my $serverstream;

my $irc = TestIRC->new;
sub write_irc
{
   my $line = $_[0];
   $irc->on_read( $line );
   length $line == 0 or die '$irc failed to read all of the line';
}

my $helloworld = "مرحبا العالم"; # Hello World in Arabic, according to Google translate
my $octets = encode_utf8( $helloworld );

write_irc( ':Someone!theiruser@their.host PRIVMSG #arabic :' . $octets . $CRLF );

my ( $msg, $hints ) = @{ shift @textmessages };

is( $msg->command, "PRIVMSG",                      '$msg->command for PRIVMSG with encoding' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg->prefix for PRIVMSG with encoding' );

is_deeply( $hints,
           { synthesized        => 1,
             prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             target_name        => "#arabic",
             target_name_folded => "#arabic",
             target_is_me       => '',
             target_type        => "channel",
             is_notice          => 0,
             restriction        => '',
             text               => "مرحبا العالم",
             handled            => 1 },
           '$hints for PRIVMSG with encoding' );

$serverstream = "";
$irc->send_message( "PRIVMSG", undef, "#arabic", "مرحبا العالم" );

is( $serverstream, "PRIVMSG #arabic :$octets$CRLF",
                   "Server stream after sending PRIVMSG with encoding" );

write_irc( ':Someone!theiruser@their.host QUIT :' . $octets . $CRLF );

( $msg, $hints ) = @{ shift @quitmessages };

is( $msg->command, "QUIT", '$msg->command for QUIT with encoding' );
is( $hints->{text}, "مرحبا العالم", '$hints->{text} for QUIT with encoding' );

done_testing;

package TestIRC;
use base qw( Protocol::IRC );

sub new { return bless [], shift }

sub write { $serverstream .= $_[1] }

use constant encoder => Encode::find_encoding("UTF-8");

my %isupport;
BEGIN {
   %isupport = (
      CHANTYPES   => "#&",
         channame_re => qr/^[#&]/,
      PREFIX      => "(ohv)@%+",
         prefix_modes => 'ohv',
         prefix_flags => '@%+',
         prefixflag_re => qr/^[@%+]/,
         prefix_map_m2f => { 'o' => '@', 'h' => '%', 'v' => '+' },
         prefix_map_f2m => { '@' => 'o', '%' => 'h', '+' => 'v' },
   );
}
sub isupport { return $isupport{$_[1]} }

sub nick { return "MyNick" }

sub on_message_text { push @textmessages, [ $_[1], $_[2] ] }
sub on_message_QUIT { push @quitmessages, [ $_[1], $_[2] ] }
