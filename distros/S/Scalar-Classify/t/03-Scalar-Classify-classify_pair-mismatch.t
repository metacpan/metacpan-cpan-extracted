# 03-Scalar-Classify-classify_pair-mismatch.t
#         jbrenner@ffn.com     2014/09/15

use warnings;
use strict;
$|=1;
my $DEBUG = 1;              # TODO set to 0 before ship
use Data::Dumper;
# use File::Path      qw( mkpath );
# use File::Basename  qw( fileparse basename dirname );
# use File::Copy      qw( copy move );
# use Fatal           qw( open close mkpath copy move );
# use Cwd             qw( cwd abs_path );
# use Env             qw( HOME );
# use List::MoreUtils qw( any );

use Test::More;
use Test::Deep qw( cmp_deeply ); #
use Test::Exception;


use FindBin qw($Bin);
use FindBin qw( $Bin );
use lib "$Bin/../lib";
use_ok( 'Scalar::Classify', qw( classify classify_pair ) );

{
  my $test_name = "Testing classify_pair";
  my $case = "mismatched blessed href and blessed aref";

  my $hobj1 =  bless( {}, 'Beast'  ) ;
  my $aobj2 =  bless( [], 'Beast'  ) ;

  throws_ok {
    classify_pair( $hobj1, $aobj2, { mismatch_policy => 'error' } );
  }  qr{mismatched types}, "$test_name: $case";

}

{
  my $test_name = "Testing classify_pair";
  my $case = "mismatched classes of blessed href";

  my $hobj1 =  bless( {}, 'Beast'  ) ;
  my $hobj2 =  bless( {}, 'Beauty'  ) ;

  throws_ok {
    classify_pair( $hobj1, $hobj2, { mismatch_policy => 'error' } );
  }  qr{mismatched classes}, "$test_name: $case";
}

{
  my $test_name = "Testing classify_pair";
  my $case = "Numeric scalar";
  my $subcase = "(second was undef)";

  my $scaley_one = 666;
  my $scaley     = $scaley_one;

  my ($arg1, $arg2) = ( $scaley, undef );

  my ( $default, $type, $class ) =
    classify_pair( $arg1, $arg2 );

  my ($exp_def, $exp_type, $exp_class) =
    ( 0 ,
      ':NUMBER:',
      undef
    );

  cmp_deeply( $default, $exp_def, "$test_name: $case $subcase: default" );
  is( $type, $exp_type,           "$test_name: $case $subcase: type" );
  cmp_deeply( $class, $exp_class, "$test_name: $case $subcase: class" );
}

{
  my $test_name = "Testing classify_pair";
  my $case = "Numeric scalar";
  my $subcase = "(first was undef)";

  my $scaley_one = 666;
  my $scaley     = $scaley_one;

  my ($arg1, $arg2) = ( undef, $scaley );

  my ( $default, $type, $class ) =
    classify_pair( $arg1, $arg2 );

  my ($exp_def, $exp_type, $exp_class) =
    ( 0 ,
      ':NUMBER:',
      undef
    );

  cmp_deeply( $default, $exp_def, "$test_name: $case $subcase: default" );
  is( $type, $exp_type,           "$test_name: $case $subcase: type" );
  cmp_deeply( $class, $exp_class, "$test_name: $case $subcase: class" );
}


{
  my $test_name = "Testing classify_pair";
  my $case = "Mismatched numeric and string"; ### TODO this is a hard one
  my $subcase = "(first was string)";

  my $scaley_one = 666;
  my $scaley     = $scaley_one;

  my $tail = "fins";

  my ($arg1, $arg2) = ( $tail, $scaley );

  throws_ok {
    classify_pair( $arg1, $arg2, { mismatch_policy => 'error' } );
  }  qr{mismatched types}, "$test_name: $case $subcase";
}

{
  my $test_name = "Testing classify_pair";
  my $case = "Mismatched numeric and string"; ### TODO this is a hard one
  my $subcase = "(second was string)";

  my $scaley_one = 666;
  my $scaley     = $scaley_one;

  my $tail = "fins";

  my ($arg1, $arg2) = ( $scaley, $tail );


  throws_ok {
    classify_pair( $arg1, $arg2, { mismatch_policy => 'error' } );
  }  qr{mismatched types}, "$test_name: $case $subcase";
}

### TODO what other cases are worth testing?
###   o  mechanically make a list of "classify" types, generate cross-comparisons.
###   o  test default 'warn' behavior?
###   o  try other numerics besides an integer.

### TODO
### the habit here of keeping a copy of the integer in another variable
### is interesting... was the idea to test whether the numeric value
### changed, or became stringified, or something?

### END
done_testing();
exit;
