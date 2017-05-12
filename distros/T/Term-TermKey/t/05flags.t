#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use Term::TermKey qw( FLAG_UTF8 FLAG_RAW );

{
   my $tk = Term::TermKey->new_abstract( "vt100", FLAG_UTF8 );

   is( $tk->get_flags & (FLAG_UTF8|FLAG_RAW), FLAG_UTF8, 'Explicit UTF-8 flag preserved' );
}

{
   my $tk = Term::TermKey->new_abstract( "vt100", FLAG_RAW );

   is( $tk->get_flags & (FLAG_UTF8|FLAG_RAW), FLAG_RAW, 'Explicit RAW flag preserved' );
}

# Force UTF-8 on
{
   local @ENV{qw( LANG LC_MESSAGES LC_ALL )} = ( "en_GB.UTF-8" ) x 3;

   my $tk = Term::TermKey->new( \*STDIN, 0 );

   is( $tk->get_flags & (FLAG_UTF8|FLAG_RAW), FLAG_UTF8, 'Autodetected UTF-8' );
}

# Force UTF-8 off
{
   local @ENV{qw( LANG LC_MESSAGES LC_ALL )} = ( "en_GB.ISO-8859-1" ) x 3;

   my $tk = Term::TermKey->new( \*STDIN, 0 );

   is( $tk->get_flags & (FLAG_UTF8|FLAG_RAW), FLAG_RAW, 'Autodetected RAW' );
}
