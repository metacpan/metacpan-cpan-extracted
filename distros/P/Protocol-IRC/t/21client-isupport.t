#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $irc = TestIRC->new;
sub write_irc
{
   my $line = $_[0];
   $irc->on_read( $line );
   length $line == 0 or die '$irc failed to read all of the line';
}

write_irc( ":server 004 YourNick irc.example.com TestIRC iow lvhopsmntikr$CRLF" );
write_irc( ':server 005 YourNick MAXCHANNELS=10 NICKLEN=30 PREFIX=(ohv)@%+ CASEMAPPING=rfc1459 CHANMODES=beI,k,l,imnpsta CHANTYPES=#& :are supported by this server' . $CRLF );

is( $irc->server_info( "channelmodes" ), "lvhopsmntikr", 'server_info channelmodes' );

is( $irc->isupport( "MAXCHANNELS" ), "10", 'ISUPPORT MAXCHANNELS is 10' );

is( $irc->isupport( "PREFIX" ), "(ohv)\@\%+", 'ISUPPORT PREFIX is (ohv)@%+' );

is( $irc->isupport( "CHANMODES" ), "beI,k,l,imnpsta", 'ISUPPORT CHANMODES is beI,k,l,imnpsta' );

is( $irc->isupport( "CHANTYPES" ), "#&", 'ISUPPORT CHANTYPES is #&' );

# Now the generated ones from PREFIX
is( $irc->isupport( "prefix_modes" ), "ohv", 'ISUPPORT PREFIX_MODES is ohv' );
is( $irc->isupport( "prefix_flags" ), "\@\%+", 'ISUPPORT PREFIX_FLAGS is @%+' );

is( $irc->prefix_mode2flag( "o" ), "\@", 'prefix_mode2flag o -> @' );
is( $irc->prefix_flag2mode( "\@" ), "o", 'prefix_flag2mode @ -> o' );

# Now the generated ones from CHANMODES
is_deeply( $irc->isupport( "chanmodes_list" ), [qw( beI k l imnpsta )], 'ISUPPORT chanmodes_list is [qw( beI k l imnpsta )]' );

done_testing;

package TestIRC;
use base qw( Protocol::IRC::Client );

sub new { return bless {}, shift }
