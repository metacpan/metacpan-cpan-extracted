#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::IRC::Message;

sub test_named
{
   my ( $command, $args, $line ) = @_;

   my $message = Protocol::IRC::Message->new_from_named_args( $command, %$args );

   is( $message->stream_to_line, $line, "\$message->line for $command" );
}

test_named PING =>
   { text => "123" },
   "PING 123";

test_named PRIVMSG =>
   { text => "the message", targets => "#channel" },
   "PRIVMSG #channel :the message";

test_named KICK =>
   { text => "go away", target_name => "#channel", kicked_nick => "BadUser" },
   "KICK #channel BadUser :go away";

done_testing;
