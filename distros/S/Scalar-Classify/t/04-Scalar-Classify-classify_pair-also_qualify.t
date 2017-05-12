# Run this like so: `perl 04-Scalar-Classify-classify_pair-also_qualify.t'
#   doom@kzsu.stanford.edu     2015/12/03 02:53:27

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
  my $test_name = "Testing classify_pair without also_qualify";
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

  my ($arg1_basetype, $arg1_class) = classify( $arg1 );
  my ($arg2_basetype, $arg2_class) = classify( $arg2 );
  is( $arg1_basetype,  undef, "$test_name: first arg IS STILL undef" );
  is( $arg2_basetype, 'HASH', "$test_name: second arg still href" );
}

{
  my $test_name = "Testing classify_pair with also_qualify";
  my $case = "Simple href";
  my ($arg1, $arg2) = ( undef, {} );

  my ( $default, $type, $class ) =
   classify_pair( $arg1, $arg2, { also_qualify => 1 });

  my ($exp_def, $exp_type, $exp_class) =
    ( {} ,
      'HASH',
      undef
    );

  cmp_deeply( $default, $exp_def, "$test_name: $case (was undef): default" );
  is( $type, $exp_type, "$test_name: $case (was undef): type" );
  cmp_deeply( $class, $exp_class, "$test_name: $case (was undef): class" );

  my ($arg1_basetype, $arg1_class) = classify( $arg1 );
  my ($arg2_basetype, $arg2_class) = classify( $arg2 );
  is( $arg1_basetype,  'HASH', "$test_name: first arg HAS BECOME href" );
  is( $arg2_basetype, 'HASH', "$test_name: second arg still href" );
}

done_testing();
