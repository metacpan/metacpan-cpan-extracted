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

ok( defined $irc, 'defined $irc' );

write_irc( ':irc.example.com 005 MyNick NAMESX PREFIX=(ohv)@%+ CHANMODES=beI,k,l,imnpst :are supported by this server' . $CRLF );

undef @messages;

write_irc( ':Someone!theiruser@their.host MODE #chan +i' . $CRLF );

my ( $command, $msg, $hints );
my $modes;

( $command, $msg, $hints ) = @{ shift @messages };

is( $msg->command, "MODE",                         '$msg->command for +i' );
is( $msg->prefix,  'Someone!theiruser@their.host', '$msg->prefix for +i' );
is_deeply( [ $msg->args ], [ "#chan", "+i" ],      '$msg->args for +i' );

is_deeply( $hints,
           { prefix_nick        => "Someone",
             prefix_nick_folded => "someone",
             prefix_user        => "theiruser",
             prefix_host        => "their.host",
             prefix_name        => "Someone",
             prefix_name_folded => "someone",
             prefix_is_me       => '',
             target_name        => "#chan",
             target_name_folded => "#chan",
             target_is_me       => '',
             target_type        => "channel",
             modechars          => "+i",
             modeargs           => [ ],
             modes              => [
                { type          => 'bool',
                  sense         => 1,
                  mode          => "i" } ],
             handled            => 1 }, '$hints for +i' );

write_irc( ':Someone!theiruser@their.host MODE #chan -i' . $CRLF );

( $command, $msg, $hints ) = @{ shift @messages };
$modes = $hints->{modes};

is_deeply( $modes,
           [ { type => 'bool', sense => -1, mode => "i" } ],
           '$modes for -i' );

write_irc( ':Someone!theiruser@their.host MODE #chan +b *!bad@bad.host' . $CRLF );

( $command, $msg, $hints ) = @{ shift @messages };
$modes = $hints->{modes};

is_deeply( $modes,
           [ { type => 'list', sense => 1, mode => "b", value => "*!bad\@bad.host" } ],
           '$modes for +b ...' );

write_irc( ':Someone!theiruser@their.host MODE #chan -b *!less@bad.host' . $CRLF );

( $command, $msg, $hints ) = @{ shift @messages };
$modes = $hints->{modes};

is_deeply( $modes,
           [ { type => 'list', sense => -1, mode => "b", value => "*!less\@bad.host" }, ],
           '$hints for -b ...' );

write_irc( ':Someone!theiruser@their.host MODE #chan +o OpUser' . $CRLF );

( $command, $msg, $hints ) = @{ shift @messages };
$modes = $hints->{modes};

is_deeply( $modes, 
           [ { type => 'occupant', sense => 1, mode => "o", flag => '@', nick => "OpUser", nick_folded => "opuser" } ],
           '$modes[chanmode] for +o OpUser' );

write_irc( ':Someone!theiruser@their.host MODE #chan -o OpUser' . $CRLF );

( $command, $msg, $hints ) = @{ shift @messages };
$modes = $hints->{modes};

is_deeply( $modes, 
           [ { type => 'occupant', sense => -1, mode => "o", flag => '@', nick => "OpUser", nick_folded => "opuser" } ],
           '$modes[chanmode] for -o OpUser' );

write_irc( ':Someone!theiruser@their.host MODE #chan +k joinkey' . $CRLF );

( $command, $msg, $hints ) = @{ shift @messages };
$modes = $hints->{modes};

is_deeply( $modes, 
           [ { type => 'value', sense => 1, mode => "k", value => "joinkey" } ],
           '$modes[chanmode] for +k joinkey' );

write_irc( ':Someone!theiruser@their.host MODE #chan -k joinkey' . $CRLF );

( $command, $msg, $hints ) = @{ shift @messages };
$modes = $hints->{modes};

is_deeply( $modes, 
           [ { type => 'value', sense => -1, mode => "k", value => "joinkey" } ],
           '$modes[chanmode] for -k joinkey' );

write_irc( ':Someone!theiruser@their.host MODE #chan +l 30' . $CRLF );

( $command, $msg, $hints ) = @{ shift @messages };
$modes = $hints->{modes};

is_deeply( $modes, 
           [ { type => 'value', sense => 1, mode => "l", value => "30" } ],
           '$modes[chanmode] for +l 30' );

write_irc( ':Someone!theiruser@their.host MODE #chan -l' . $CRLF );

( $command, $msg, $hints ) = @{ shift @messages };
$modes = $hints->{modes};

is_deeply( $modes, 
           [ { type => 'value', sense => -1, mode => "l" } ],
           '$modes[chanmode] for -l' );

write_irc( ':Someone!theiruser@their.host MODE #chan +shl HalfOp 123' . $CRLF );

( $command, $msg, $hints ) = @{ shift @messages };
$modes = $hints->{modes};

is_deeply( $modes,
           [ { type => 'bool',     sense => 1, mode => "s" },
             { type => 'occupant', sense => 1, mode => "h", flag => '%', nick => "HalfOp", nick_folded => "halfop" },
             { type => 'value',    sense => 1, mode => "l", value => "123" } ],
           '$modes[chanmode] for +shl HalfOp 123' );

write_irc( ':Someone!theiruser@their.host MODE #chan -lh+o HalfOp FullOp' . $CRLF );

( $command, $msg, $hints ) = @{ shift @messages };
$modes = $hints->{modes};

is_deeply( $modes,
           [ { type => 'value',    sense => -1, mode => "l" },
             { type => 'occupant', sense => -1, mode => "h", flag => '%', nick => "HalfOp", nick_folded => "halfop", },
             { type => 'occupant', sense =>  1, mode => "o", flag => '@', nick => "FullOp", nick_folded => "fullop" } ],
           '$modes[chanmode] for -lh+o HalfOp FullOp' );

done_testing;

package TestIRC;
use base qw( Protocol::IRC::Client );

sub new { return bless {}, shift }

sub nick { return "MyNick" }

sub on_message
{
   my $self = shift;
   my ( $command, $message, $hints ) = @_;
   push @messages, [ $command, $message, $hints ];
}
