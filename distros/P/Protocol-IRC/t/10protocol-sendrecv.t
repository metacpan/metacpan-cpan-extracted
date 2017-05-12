#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal qw( lives_ok );

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $written = "";
my @messages;
my $foo_received;

my $irc = TestIRC->new;

$irc->send_message( "USER", undef, "me", "0", "*", "My real name" );
is( $written, "USER me 0 * :My real name$CRLF", 'Written stream after ->send_message' );

my $buffer = ':irc.example.com 001 YourNameHere :Welcome to IRC YourNameHere!me@your.host' . $CRLF;
$irc->on_read( $buffer );
is( length $buffer, 0, '->on_read consumes the entire line' );

is( scalar @messages, 1, 'Received 1 message after server reply' );
my $msg = shift @messages;

isa_ok( $msg, "Protocol::IRC::Message", '$msg isa Protocol::IRC::Message' );

is( $msg->command, "001",             '$msg->command' );
is( $msg->prefix,  "irc.example.com", '$msg->prefix' );
is_deeply( [ $msg->args ], [ "YourNameHere", "Welcome to IRC YourNameHere!me\@your.host" ], '$msg->args' );

$buffer = ":irc.example.com FOO$CRLF";
$irc->on_read( $buffer );
ok( $foo_received, '$foo_received after FOO message' );

$buffer = "$CRLF$CRLF";
lives_ok { $irc->on_read( $buffer ) } 'Blank lines does not die';
is( length $buffer, 0, 'Blank lines still eat all buffer' );

done_testing;

package TestIRC;
use base qw( Protocol::IRC );

sub new { return bless [], shift }

sub write { $written .= $_[1] }

sub on_message
{
   return if $_[3]->{handled};
   Test::More::is( $_[1], $_[2]->command_name, '$command is $message->command_name' );
   push @messages, $_[2];
   return 1;
}

sub on_message_FOO { $foo_received++ }

sub isupport
{
   return "ascii" if $_[1] eq "CASEMAPPING";
}
