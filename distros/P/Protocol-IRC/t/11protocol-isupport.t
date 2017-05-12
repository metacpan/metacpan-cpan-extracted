#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $irc = TestIRC->new;

my %isupport = (
   MAXCHANNELS => "10",
   NICKLEN     => "30",
   PREFIX      => "(ohv)@%+",
      prefix_modes => 'ohv',
      prefix_flags => '@%+',
      prefix_map_m2f => { 'o' => '@', 'h' => '%', 'v' => '+' },
      prefix_map_f2m => { '@' => 'o', '%' => 'h', '+' => 'v' },
   CASEMAPPING => "rfc1459",
   CHANMODES   => "beI,k,l,imnpsta",
      chanmodes_list => [qw( beI k l imnpsta )],
   CHANTYPES   => "#&",
      channame_re => qr/^[#&]/,
);

is( $irc->isupport( "MAXCHANNELS" ), "10", 'ISUPPORT MAXCHANNELS is 10' );

is( $irc->isupport( "PREFIX" ), "(ohv)\@\%+", 'ISUPPORT PREFIX is (ohv)@%+' );

is( $irc->isupport( "CHANMODES" ), "beI,k,l,imnpsta", 'ISUPPORT CHANMODES is beI,k,l,imnpsta' );

is( $irc->isupport( "CHANTYPES" ), "#&", 'ISUPPORT CHANTYPES is #&' );

# Now the generated ones from PREFIX
is( $irc->isupport( "prefix_modes" ), "ohv", 'ISUPPORT PREFIX_MODES is ohv' );
is( $irc->isupport( "prefix_flags" ), "\@\%+", 'ISUPPORT PREFIX_FLAGS is @%+' );

is( $irc->prefix_mode2flag( "o" ), "\@", 'prefix_mode2flag o -> @' );
is( $irc->prefix_flag2mode( "\@" ), "o", 'prefix_flag2mode @ -> o' );

is( $irc->cmp_prefix_flags( "\@", "\%" ),  1,    'cmp_prefix_flags @ % -> 1' );
is( $irc->cmp_prefix_flags( "\%", "\@" ), -1,    'cmp_prefix_flags % @ -> -1' );
is( $irc->cmp_prefix_flags( "\%", "\%" ),  0,    'cmp_prefix_flags % % -> 0' );
is( $irc->cmp_prefix_flags( "\%", "\$" ), undef, 'cmp_prefix_flags % $ -> undef' );

is( $irc->cmp_prefix_modes( "o", "h" ),  1,    'cmp_prefix_modes o h -> 1' );
is( $irc->cmp_prefix_modes( "h", "o" ), -1,    'cmp_prefix_modes h o -> -1' );
is( $irc->cmp_prefix_modes( "h", "h" ),  0,    'cmp_prefix_modes h h -> 0' );
is( $irc->cmp_prefix_modes( "h", "b" ), undef, 'cmp_prefix_modes h b -> undef' );

is( $irc->casefold_name( "NAME" ),      "name",      'casefold_name NAME' );
is( $irc->casefold_name( "FOO[AWAY]" ), "foo{away}", 'casefold_name FOO[AWAY]' );
is( $irc->casefold_name( "user^name" ), "user~name", 'casefold_name user^name' );

is( $irc->classify_name( "UserName"   ), "user",    'classify_name UserName' );
is( $irc->classify_name( "#somewhere" ), "channel", 'classify_name #somewhere' );

{
   local $isupport{CASEMAPPING} = "strict-rfc1459";

   is( $irc->casefold_name( "FOO[AWAY]" ), "foo{away}", 'casefold_name FOO[AWAY] under strict' );
   is( $irc->casefold_name( "user^name" ), "user^name", 'casefold_name user^name under strict' );

   local $isupport{CASEMAPPING} = "ascii";

   is( $irc->casefold_name( "FOO[AWAY]" ), "foo[away]", 'casefold_name FOO[AWAY] under ascii' );
}

# Now the generated ones from CHANMODES
is_deeply( $irc->isupport( "chanmodes_list" ), [qw( beI k l imnpsta )], 'ISUPPORT chanmodes_list is [qw( beI k l imnpsta )]' );

done_testing;

package TestIRC;
use base qw( Protocol::IRC );

sub new { return bless [], shift }

sub isupport { return $isupport{$_[1]} }
