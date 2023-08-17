#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Try;

# finally does not disturb $@
{
   my $warnings = "";
   local $SIG{__WARN__} = sub { $warnings .= $_[0]; };

   ok( !eval {
      try {
         die "oopsie";
      }
      finally {
         die "double oops";
      }
      1;
   }, 'die in both try{} and finally{} is still fatal' );
   like( $@, qr/^oopsie at /, 'die in finally{} does not corrupt $@' );
   like( $warnings, qr/double oops at /, 'die in finally{} warns inner exception' );
}

done_testing;
