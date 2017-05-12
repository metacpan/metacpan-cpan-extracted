# 02-Scalar-Classify-classify_pair.t
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

use FindBin qw( $Bin );
use lib "$Bin/../lib";
use_ok( 'Scalar::Classify', qw( classify classify_pair ) );

{
  my $test_name = "Testing classify_pair";
  my $case = "blessed href";

  my $classy     = 'Beast';
  my $hobj =  bless( {}, $classy  ) ;

  my( $arg1, $arg2 ) = ( $hobj, undef );

   my $default =
     classify_pair( $arg1, $arg2 );

  my $exp = bless( {}, 'Beast' );

  cmp_deeply( $default, $exp, "$test_name: $case" );
}
{
  my $test_name = "Testing classify_pair";
  my $case = "Blessed arrayref";

  my $classy     = 'Beast';
  my $aobj =  bless( [], $classy  ) ;
  $aobj =  bless( [], $classy  ) ;

  my ($arg1, $arg2) = ( undef, $aobj );

  my ( $default, $type, $class ) =
    classify_pair( $arg1, $arg2 );

  my ($exp_def, $exp_type, $exp_class) =
    ( bless( [], $classy ),
      'ARRAY',
      $classy
    );

  cmp_deeply( $default, $exp_def, "$test_name: $case (was undef): default" );
  is( $type, $exp_type, "$test_name: $case (was undef): type" );
  is( $class, $exp_class, "$test_name: $case (was undef): class" );
}

{
  my $test_name = "Testing classify_pair";
  my $case = "Numeric scalar";

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

  cmp_deeply( $default, $exp_def, "$test_name: $case (was undef): default" );
  is( $type, $exp_type, "$test_name: $case (was undef): type" );
  cmp_deeply( $class, $exp_class, "$test_name: $case (was undef): class" );
}

{
  my $test_name = "Testing classify_pair";
  my $case = "String scalar";
  my $stringy    = 'Dali';
  my ($arg1, $arg2) = ( undef, $stringy );

  my ( $default, $type, $class ) =
    classify_pair( $arg1, $arg2 );

  my ($exp_def, $exp_type, $exp_class) =
    ( '' ,
      ':STRING:',
      undef
    );

  cmp_deeply( $default, $exp_def, "$test_name: $case (was undef): default" );
  is( $type, $exp_type, "$test_name: $case (was undef): type" );
  cmp_deeply( $class, $exp_class, "$test_name: $case (was undef): class" );
}

{
  my $test_name = "Testing classify_pair";
  my $case = "Simple href";
  my ($arg1, $arg2) = ( undef, {} );

  my ( $default, $type, $class ) =
    classify_pair( $arg1, $arg2 );

  my ($exp_def, $exp_type, $exp_class) =
    ( {} ,
      'HASH',
      undef
    );

  cmp_deeply( $default, $exp_def, "$test_name: $case (was undef): default" );
  is( $type, $exp_type, "$test_name: $case (was undef): type" );
  cmp_deeply( $class, $exp_class, "$test_name: $case (was undef): class" );
}

{
  my $test_name = "Testing classify_pair";
  my $case = "Simple aref";
  my ($arg1, $arg2) = ( undef, [] );

  my ( $default, $type, $class ) =
    classify_pair( $arg1, $arg2 );

  my ($exp_def, $exp_type, $exp_class) =
    ( [],
      'ARRAY',
      undef
    );

  cmp_deeply( $default, $exp_def, "$test_name: $case (was undef): default" );
  is( $type, $exp_type, "$test_name: $case (was undef): type" );
  cmp_deeply( $class, $exp_class, "$test_name: $case (was undef): class" );
}


done_testing();
