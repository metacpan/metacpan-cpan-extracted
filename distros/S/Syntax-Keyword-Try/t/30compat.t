#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Try;

# forbidding finally
{
   use Syntax::Keyword::Try '-no_finally';

   ok( !defined eval <<'EOPERL',
      try { 123 }
      finally { 456 }
EOPERL
      'try/finally is forbidden' );
   like( $@, qr/^finally \{\} is not permitted here / );
}

# require var
{
   use Syntax::Keyword::Try '-require_var';

   ok( !defined eval <<'EOPERL',
      try { 123 }
      catch { 456 }
EOPERL
      'try/catch requires var' );
   like( $@, qr/^Expected \(VAR\) for catch / );
}

done_testing;
