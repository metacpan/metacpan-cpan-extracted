#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my @messages;

my $irc = TestIRC->new;
sub write_irc
{
   my $line = $_[0];
   $irc->on_read( $line );
   length $line == 0 or die '$irc failed to read all of the line';
}

write_irc( ':irc.example.com CAP * LS :multi-prefix sasl' . $CRLF );

my ( $verb, $msg, $hints ) = @{ shift @messages };

is( $msg->command, "CAP", '$msg->command' );
is( $msg->arg(1),  "LS",  '$msg->arg' );

is( $verb,          "LS", '$verb' );
is( $hints->{verb}, "LS", '$hints->{verb}' );
is_deeply( $hints->{caps},
           { "multi-prefix" => 1,
             "sasl"         => 1 },
           '$hints->{caps}' );

done_testing;

package TestIRC;
use base qw( Protocol::IRC::Client );

sub new { return bless {}, shift }

sub on_message_cap
{
   my $self = shift;
   my ( $verb, $message, $hints ) = @_;
   push @messages, [ $verb, $message, $hints ];
}
