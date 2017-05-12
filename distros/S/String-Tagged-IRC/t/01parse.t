#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use String::Tagged::IRC;

# unformatted
{
   my $st = String::Tagged::IRC->parse_irc( "Hello, world!" );

   ok( defined $st, 'defined $st' );

   is( "$st", "Hello, world!", '"$st"' );
   is( scalar $st->tagnames, 0, '$st has no tags' );
}

# mIRC-style boolean tags
{
   my $st = String::Tagged::IRC->parse_irc( "A word in \cBbold\cB or \c]italic\c]" );

   is( "$st", "A word in bold or italic", '"$st" with mIRC-style bold and italic' );
   is_deeply( [ sort $st->tagnames ], [qw( bold italic )], '$st has b and i tags' );

   is_deeply( $st->get_tags_at( index $st, "bold"   ), { bold   => 1 }, '$st has bold at "bold"' );
   is_deeply( $st->get_tags_at( index $st, "italic" ), { italic => 1 }, '$st has italic at "italic"' );
}

# mIRC-style colour tags
{
   my $st = String::Tagged::IRC->parse_irc( "Something \cC04red\cC and \cC15,#209020green\cC" );

   is( "$st", "Something red and green", '"$st" with mIRC-style fg and bg' );
   is_deeply( [ sort $st->tagnames ], [qw( bg fg )], '$st has fg and bg tags' );

   is( $st->get_tags_at( index $st, "red"   )->{fg}->index, 4, '$st has fg at "red"' );
   is( $st->get_tags_at( index $st, "green" )->{bg}->hex, "209020", '$st has bg at "green"' );
}

# irssi-style boolean tags
{
   my $st = String::Tagged::IRC->parse_irc( "A word in \cDcbold\cDc or \cDditalic\cDd" );

   is( "$st", "A word in bold or italic", '"$st" with irssi-style bold and italic' );
   is_deeply( [ sort $st->tagnames ], [qw( bold italic )], '$st has b and i tags' );

   is_deeply( $st->get_tags_at( index $st, "bold"   ), { bold   => 1 }, '$st has bold at "bold"' );
   is_deeply( $st->get_tags_at( index $st, "italic" ), { italic => 1 }, '$st has italic at "italic"' );
}

# irssi-style colour tags
{
   my $st = String::Tagged::IRC->parse_irc( "Something \cD90red\cDg and \cD72green\cDg" );

   is( "$st", "Something red and green", '"$st" with mIRC-style fg and bg' );
   is_deeply( [ sort $st->tagnames ], [qw( bg fg )], '$st has fg and bg tags' );

   is( $st->get_tags_at( index $st, "red"   )->{fg}->hex, "ff6666", '$st has bg at "green"' );
   is( $st->get_tags_at( index $st, "green" )->{bg}->hex, "00aa00", '$st has bg at "green"' );
}

done_testing;
