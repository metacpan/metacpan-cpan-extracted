#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

# We don't care what order we get these messages in, and we know we'll only
# get one of each type at once. Hash them
my %messages;
my $serverstream;

my $irc = TestIRC->new;
sub write_irc
{
   my $line = $_[0];
   $irc->on_read( $line );
   length $line == 0 or die '$irc failed to read all of the line';
}

write_irc( ':Someone!theiruser@their.host PRIVMSG MyNick :Their message here' . $CRLF );

is_deeply( [ sort keys %messages ], [qw( PRIVMSG text )], 'keys %messages for PRIVMSG' );

my ( $msg, $hints );

( $msg, $hints ) = @{ $messages{PRIVMSG} };

is( $msg->command, "PRIVMSG",                      '$msg[PRIVMSG]->command for PRIVMSG' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg[PRIVMSG]->prefix for PRIVMSG' );

is_deeply( $hints,
           { prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             targets            => "MyNick",
             text               => "Their message here",
             handled            => 1 },
           '$hints[PRIVMSG] for PRIVMSG' );

( $msg, $hints ) = @{ $messages{text} };

is( $msg->command, "PRIVMSG",                      '$msg[text]->command for PRIVMSG' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg[text]->prefix for PRIVMSG' );

is_deeply( $hints,
           { synthesized        => 1,
             prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             target_name        => "MyNick",
             target_name_folded => "mynick",
             target_is_me       => 1,
             target_type        => "user",
             is_notice          => 0,
             text               => "Their message here",
             handled            => 1 },
           '$hints[text] for PRIVMSG' );

undef %messages;

write_irc( ':Someone!theiruser@their.host PRIVMSG #channel :Message to all' . $CRLF );

is_deeply( [ sort keys %messages ], [qw( PRIVMSG text )], 'keys %messages for PRIVMSG to channel' );

( $msg, $hints ) = @{ $messages{PRIVMSG} };

is( $msg->command, "PRIVMSG",                      '$msg[PRIVMSG]->command for PRIVMSG to channel' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg[PRIVMSG]->prefix for PRIVMSG to channel' );

is_deeply( $hints,
           { prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             targets            => "#channel",
             text               => "Message to all",
             handled            => 1 },
           '$hints[PRIVMSG] for PRIVMSG to channel' );

( $msg, $hints ) = @{ $messages{text} };

is( $msg->command, "PRIVMSG",                      '$msg[text]->command for PRIVMSG to channel' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg[text]->prefix for PRIVMSG to channel' );

is_deeply( $hints,
           { synthesized        => 1,
             prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             target_name        => "#channel",
             target_name_folded => "#channel",
             target_is_me       => '',
             target_type        => "channel",
             is_notice          => 0,
             restriction        => '',
             text               => "Message to all",
             handled            => 1 },
           '$hints[text] for PRIVMSG to channel' );

undef %messages;

write_irc( ':Someone!theiruser@their.host NOTICE #channel :Is anyone listening?' . $CRLF );

is_deeply( [ sort keys %messages ], [qw( NOTICE text )], 'keys %messages for NOTICE to channel' );

( $msg, $hints ) = @{ $messages{NOTICE} };

is( $msg->command, "NOTICE",                      '$msg[NOTICE]->command for NOTICE to channel' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg[NOTICE]->prefix for NOTICE to channel' );

is_deeply( $hints,
           { prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             targets            => "#channel",
             text               => "Is anyone listening?",
             handled            => 1 },
           '$hints[NOTICE] for NOTICE to channel' );

( $msg, $hints ) = @{ $messages{text} };

is( $msg->command, "NOTICE",                      '$msg[text]->command for NOTICE to channel' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg[text]->prefix for NOTICE to channel' );

is_deeply( $hints,
           { synthesized        => 1,
             prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             target_name        => "#channel",
             target_name_folded => "#channel",
             target_is_me       => '',
             target_type        => "channel",
             is_notice          => 1,
             restriction        => '',
             text               => "Is anyone listening?",
             handled            => 1 },
           '$hints[text] for NOTICE to channel' );

undef %messages;

write_irc( ':Someone!theiruser@their.host PRIVMSG @#channel :To only the important people' . $CRLF );

is_deeply( [ sort keys %messages ], [qw( PRIVMSG text )], 'keys %messages for PRIVMSG to channel ops' );

( $msg, $hints ) = @{ $messages{PRIVMSG} };

is( $msg->command, "PRIVMSG",                      '$msg[PRIVMSG]->command for PRIVMSG to channel ops' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg[PRIVMSG]->prefix for PRIVMSG to channel ops' );

is_deeply( $hints,
           { prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             targets            => "@#channel",
             text               => "To only the important people",
             handled            => 1 },
           '$hints[PRIVMSG] for PRIVMSG to channel ops' );

( $msg, $hints ) = @{ $messages{text} };

is( $msg->command, "PRIVMSG",                      '$msg[text]->command for PRIVMSG to channel ops' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg[text]->prefix for PRIVMSG to channel ops' );

is_deeply( $hints,
           { synthesized        => 1,
             prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             target_name        => "#channel",
             target_name_folded => "#channel",
             target_is_me       => '',
             target_type        => "channel",
             is_notice          => 0,
             restriction        => '@',
             text               => "To only the important people",
             handled            => 1 },
           '$hints[text] for PRIVMSG to channel ops' );

undef %messages;

write_irc( ":Someone!theiruser\@their.host PRIVMSG MyNick :\001ACTION does something\001" . $CRLF );

is_deeply( [ sort keys %messages ], ["PRIVMSG", "ctcp ACTION"], 'keys %messages for CTCP ACTION' );

( $msg, $hints ) = @{ $messages{PRIVMSG} };

is( $msg->command, "PRIVMSG",                      '$msg[PRIVMSG]->command for CTCP ACTION' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg[PRIVMSG]->prefix for CTCP ACTION' );

is_deeply( $hints,
           { prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             targets            => "MyNick",
             text               => "\001ACTION does something\001",
             handled            => 1 },
           '$hints[PRIVMSG] for CTCP ACTION' );

( $msg, $hints ) = @{ $messages{"ctcp ACTION"} };

is( $msg->command, "PRIVMSG",                      '$msg[ctcp]->command for CTCP ACTION' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg[ctcp]->prefix for CTCP ACTION' );

is_deeply( $hints,
           { synthesized        => 1,
             prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             target_name        => "MyNick",
             target_name_folded => "mynick",
             target_is_me       => 1,
             target_type        => "user",
             is_notice          => 0,
             text               => "\001ACTION does something\001",
             ctcp_verb          => "ACTION",
             ctcp_args          => "does something",
             handled            => 1 },
           '$hints[ctcp] for CTCP ACTION' );

undef %messages;

$serverstream = "";
$irc->send_ctcp( undef, "target", "ACTION", "replies" );

is( $serverstream, "PRIVMSG target :\001ACTION replies\001$CRLF", 'server stream after send_ctcp' );

write_irc( ":Someone!theiruser\@their.host NOTICE MyNick :\001VERSION foo/1.2.3\001" . $CRLF );

is_deeply( [ sort keys %messages ], ["NOTICE", "ctcpreply VERSION"], 'keys %messages for CTCPREPLY VERSION' );

( $msg, $hints ) = @{ $messages{NOTICE} };

is( $msg->command, "NOTICE",                      '$msg[NOTICE]->command for CTCPREPLY VERSION' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg[NOTICE]->prefix for CTCPREPLY VERSION' );

is_deeply( $hints,
           { prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             targets            => "MyNick",
             text               => "\001VERSION foo/1.2.3\001",
             handled            => 1 },
           '$hints[NOTICE] for CTCPREPLY VERSION' );

( $msg, $hints ) = @{ $messages{"ctcpreply VERSION"} };

is( $msg->command, "NOTICE",                      '$msg[ctcpreply]->command for CTCPREPLY VERSION' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg[ctcpreply]->prefix for CTCPREPLY VERSION' );

is_deeply( $hints,
           { synthesized        => 1,
             prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             target_name        => "MyNick",
             target_name_folded => "mynick",
             target_is_me       => 1,
             target_type        => "user",
             is_notice          => 1,
             text               => "\001VERSION foo/1.2.3\001",
             ctcp_verb          => "VERSION",
             ctcp_args          => "foo/1.2.3",
             handled            => 1 },
           '$hints[ctcpreply] for CTCPREPLY VERSION' );

undef %messages;

$serverstream = "";
$irc->send_ctcpreply( undef, "target", "ACTION", "replies" );

is( $serverstream, "NOTICE target :\001ACTION replies\001$CRLF", 'server stream after send_ctcp' );

done_testing;

package TestIRC;
use base qw( Protocol::IRC );

sub new { return bless [], shift }

sub write { $serverstream .= $_[1] }

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

sub on_message
{
   my $self = shift;
   my ( $command, $message, $hints ) = @_;
   $messages{$command} = [ $message, $hints ];
   return 1;
}
