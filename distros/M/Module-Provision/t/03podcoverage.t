use strict;
use warnings;
use File::Spec::Functions qw( catdir updir );
use FindBin               qw( $Bin );
use lib               catdir( $Bin, updir, 'lib' );

use Test::More;

BEGIN {
   $ENV{AUTHOR_TESTING}
      or plan skip_all => 'POD coverage test only for developers';
}

use English qw( -no_match_vars );

eval "use Test::Pod::Coverage 1.04";

$EVAL_ERROR and plan skip_all => 'Test::Pod::Coverage 1.04 required';

use Test::Builder;

my $Test = Test::Builder->new;

sub _all_pod_coverage_ok {
   my $parms = (@_ && (ref $_[ 0 ] eq 'HASH')) ? shift : {}; my $msg = shift;

   my $ok = 1; my @modules = grep { not m{ \A auto }mx } all_modules();

   if (@modules) {
      $Test->plan( tests => scalar @modules );

      for my $module (@modules) {
         my $thismsg = defined $msg ? $msg : "Pod coverage on ${module}";
         my $thisok  = pod_coverage_ok( $module, $parms, $thismsg );

         $thisok or $ok = 0;
      }
   }
   else { $Test->plan( tests => 1 ); $Test->ok( 1, 'No modules found.' ) }

   return $ok;
}

_all_pod_coverage_ok();

# Local Variables:
# mode: perl
# tab-width: 3
# End:
