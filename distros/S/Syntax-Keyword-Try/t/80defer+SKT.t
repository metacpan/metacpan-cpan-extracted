#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN {
   plan skip_all => "Syntax::Keyword::Defer >= 0.02 is not available"
      unless eval { require Syntax::Keyword::Defer;
                    Syntax::Keyword::Defer->VERSION( '0.02' ) };
   plan skip_all => "Syntax::Keyword::Try >= 0.18 is not available"
      unless eval { require Syntax::Keyword::Try;
                    Syntax::Keyword::Try->VERSION( '0.18' ) };

   Syntax::Keyword::Defer->import;
   Syntax::Keyword::Try->import;

   diag( "Syntax::Keyword::Defer $Syntax::Keyword::Defer::VERSION, " .
         "Syntax::Keyword::Try $Syntax::Keyword::Try::VERSION" );
}

# defer inside try
{
   my $ok;
   try {
      defer { $ok .= "2" }
      $ok .= "1";
   }
   catch ($e) { }

   is( $ok, "12", 'defer inside try' );
}

# defer inside catch
{
   my $ok;
   try {
      die "Oopsie\n";
   }
   catch ($e) {
      defer { $ok .= "4" }
      $ok .= "3";
   }

   is( $ok, "34", 'defer inside catch' );
}

# try/catch inside defer
{
   my $ok;

   {
      defer {
         try { $ok .= "6" }
         catch ($e) {}
      }
      $ok .= "5";
   }

   is( $ok, "56", 'try/catch inside defer' );
}

done_testing;
