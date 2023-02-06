#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN { $^O = "MSWin32"; }
my ( $Attr, @Log );
{
   BEGIN { $INC{"Win32/Console.pm"} = __FILE__; }
   package Win32::Console;
   use constant {
      STD_OUTPUT_HANDLE => 1,
      STD_ERROR_HANDLE  => 2,
   };
   sub new { return bless [], shift }
   sub Attr { shift; my $old = $Attr; push @Log, [ Attr => $Attr = $_[0] ] if @_; return $old }
   sub Write { shift; push @Log, [ Write => $_[0] ] }
}

use String::Tagged::Terminal;

$Attr = 7; # default white-on-black, no underline

{
   my $st = String::Tagged::Terminal->new
      ->append_tagged( "some " )
      ->append_tagged( "underlined", under => 1 )
      ->append_tagged( " text" );

   undef @Log;
   $st->print_to_terminal;

   is( \@Log,
      [
         [ Attr => 7 ],
         [ Write => "some " ],
         [ Attr => 0x8007 ],
         [ Write => "underlined" ],
         [ Attr => 7 ],
         [ Write => " text" ],
         [ Attr => 7 ],
      ], 'log of console methods for coloured output' );
}

{
   my $st = String::Tagged::Terminal->new
      ->append_tagged( "output " )
      ->append_tagged( "coloured", fgindex => 1 )
      ->append_tagged( " text" );

   undef @Log;
   $st->print_to_terminal;

   is( \@Log,
      [
         [ Attr => 7 ],
         [ Write => "output " ],
         [ Attr => 4 ],
         [ Write => "coloured" ],
         [ Attr => 7 ],
         [ Write => " text" ],
         [ Attr => 7 ],
      ], 'log of console methods for coloured output' );
}

{
   my $st = String::Tagged::Terminal->new
      ->append_tagged( "with " )
      ->append_tagged( "bold", bold => 1 )
      ->append_tagged( " text" );

   undef @Log;
   $st->print_to_terminal;

   is( \@Log, [
         [ Attr => 7 ],
         [ Write => "with " ],
         [ Attr => 15 ],
         [ Write => "bold" ],
         [ Attr => 7 ],
         [ Write => " text" ],
         [ Attr => 7 ],
      ], 'log of console methods for bold output' );
}

done_testing;
