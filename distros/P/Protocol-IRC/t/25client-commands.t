#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my @written;
my $irc = TestIRC->new;

# PRIVMSG
{
   $irc->do_PRIVMSG( target => "#channel", text => "message 1" );
   is( shift @written, "PRIVMSG #channel :message 1", 'do_PRIVMSG renames target' );

   $irc->do_PRIVMSG( targets => "#channel", text => "message 2" );
   is( shift @written, "PRIVMSG #channel :message 2", 'do_PRIVMSG preserves targets' );

   $irc->do_PRIVMSG( targets => [ "#a", "#b" ], text => "message 3" );
   is( shift @written, "PRIVMSG #a,#b :message 3", 'do_PRIVMSG joins targets ARRAY' );
}

# NOTICE
{
   $irc->do_NOTICE( target => "#channel", text => "message 1" );
   is( shift @written, "NOTICE #channel :message 1", 'do_NOTICE renames target' );

   $irc->do_NOTICE( targets => "#channel", text => "message 2" );
   is( shift @written, "NOTICE #channel :message 2", 'do_NOTICE preserves targets' );

   $irc->do_NOTICE( targets => [ "#a", "#b" ], text => "message 3" );
   is( shift @written, "NOTICE #a,#b :message 3", 'do_NOTICE joins targets ARRAY' );
}

done_testing;

package TestIRC;
use base qw( Protocol::IRC::Client );

sub new { return bless {}, shift }

sub write { $_[1] =~ s/\x0d\x0a$//; push @written, $_[1] }
