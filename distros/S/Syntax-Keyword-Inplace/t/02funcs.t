#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Inplace;

use constant HAVE_FEATURE_FC => $^V ge v5.16;

# valid core ops
{
   BEGIN {
      require feature;
      feature->import( 'fc' ) if HAVE_FEATURE_FC;
   }

   # A subset from perlfunc(1)
   my @funcs = (qw(
      chr hex lc lcfirst length oct ord uc ucfirst
      quotemeta
      abs cos exp hex int log oct sin sqrt
   ));
   push @funcs, "fc" if HAVE_FEATURE_FC;
   # TODO: rand SEGVs

   foreach my $func ( @funcs ) {
      ok( defined( eval( "my \$var = 123; inplace $func \$var; 1" ) ),
         "inplace $func \$var is accepted" ) or
         diag( "Failure was: $@" );
   }
}

# invalid core ops
{
   # Don't go overboard, just find a few things that are obviously invalid
   my @codes = (
      'index "x", "y"',
      'print "hello"',
      'func()',
      'func(1,2)',
   );

   sub func {}

   foreach my $code ( @codes ) {
      ok( defined( my $err = defined eval( "inplace $code; 1" ) ? undef : $@ ),
         "inplace $code is not accepted" );
      like( $err, qr/^Cannot use .+ as an inplace operator at /,
         "exception from inplace $code" );
   }
}

done_testing;
