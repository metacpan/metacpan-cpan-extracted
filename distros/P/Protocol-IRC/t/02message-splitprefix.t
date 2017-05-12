#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::IRC::Message;

sub test_prefix
{
   my $testname = shift;
   my $line = shift;
   my ( $expect ) = @_;

   my $msg = Protocol::IRC::Message->new_from_line( $line );

   is_deeply( [ $msg->prefix_split ], $expect, "prefix_split for $testname" );
}

test_prefix "simple",
   ':nick!user@host COMMAND',
   [ "nick", "user", "host" ];

test_prefix "fully qualified host",
   ':nick!user@fully.qualified.host COMMAND',
   [ "nick", "user", "fully.qualified.host" ];

test_prefix "servername",
   ':irc.example.com NOTICE YourNick :Hello',
   [ undef, undef, "irc.example.com" ];

done_testing;
