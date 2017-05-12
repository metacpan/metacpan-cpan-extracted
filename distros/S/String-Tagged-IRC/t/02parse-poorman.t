#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use String::Tagged::IRC;

# enabled
{
   my $st = String::Tagged::IRC->parse_irc( "A word in *bold* or /italic/",
      parse_plain_formatting => 1,
   );

   is( "$st", "A word in *bold* or /italic/", '"$st" with mIRC-style bold and italic' );
   is_deeply( [ sort $st->tagnames ], [qw( bold italic )], '$st has b and i tags' );

   is_deeply( $st->get_tags_at( index $st, "bold"   ), { bold   => 1 }, '$st has bold at "bold"' );
   is_deeply( $st->get_tags_at( index $st, "italic" ), { italic => 1 }, '$st has italic at "italic"' );
}

# disabled
{
   my $st = String::Tagged::IRC->parse_irc( "A word in *bold* or /italic/",
      parse_plain_formatting => 0,
   );

   is( "$st", "A word in *bold* or /italic/", '"$st" with mIRC-style bold and italic' );
   is( scalar $st->tagnames, 0, '$st has no tags' );
}

done_testing;
