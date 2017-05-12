# Perl test file, can be run like so:
#   perl 01-Scalar-Classify-classify.t
#         jbrenner@ffn.com     2014/09/15

use warnings;
use strict;
$|=1;
my $DEBUG = 0;              # TODO set to 0 before ship
use Data::Dumper;
# use File::Path      qw( mkpath );
# use File::Basename  qw( fileparse basename dirname );
# use File::Copy      qw( copy move );
# use Fatal           qw( open close mkpath copy move );
# use Cwd             qw( cwd abs_path );
# use Env             qw( HOME );
# use List::MoreUtils qw( any );

use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/../lib";
use_ok( 'Scalar::Classify', qw( classify ) );

($DEBUG) && print STDERR $ENV{ PERL5LIB }, "\n";
($DEBUG) && print STDERR Dumper( \@INC ),  "\n";

{
  my $test_name = "Testing classify";

  my $scaley_one = 666;
  my $scaley = $scaley_one;
  my $classy = 'Beast';
  my $stringy = 'Dali';

  my $code_ref = sub{ my $self = shift; $self->whatever; };

  my $hobj =  bless( {}, $classy  ) ;
  my $aobj =  bless( [], $classy  ) ;
  my $sobj =  bless( \$scaley, $classy ) ;

  my $alt_code_ref = sub{ my $self = shift; $self->nevermore; };
  my $cobj =  bless( $alt_code_ref, $classy );

#                 CODE


  my @cases =
    (
     [ 'basic hashref',      {},                     [ 'HASH',   undef ] ],
     [ 'basic arrayref',     [],                     [ 'ARRAY',  undef ] ],
     [ 'basic scalar ref',   \$scaley_one,           [ 'SCALAR', undef ] ],
     [ 'blessed hashref',    $hobj,                  [ 'HASH',   $classy ] ],
     [ 'blessed arrayref',   $aobj,                  [ 'ARRAY',  $classy ] ],
     [ 'blessed scalarref',  $sobj,                  [ 'SCALAR', $classy ] ],
     [ 'numeric scalar',     $scaley,                [ ':NUMBER:', undef ] ],
     [ 'string scalar',      $stringy,               [ ':STRING:', undef ] ],

     [ 'basic code ref',     $code_ref,              [ 'CODE', undef ]  ],
     [ 'blessed code ref',   $cobj,                  [ 'CODE', $classy ]  ],

    );

  foreach my $case ( @cases ) {
    my( $case, $arg, $exp ) = @{ $case };

    my $meta = classify( $arg );
#    print "got: ", Dumper( $meta ), "\n";
#    print "exp: ", Dumper( $exp ), "\n";
    is_deeply( $meta, $exp, "$test_name on $case" );
  }
}


{
  my $test_name = "Testing classify on useless cases";

#     ref
#                 LVALUE       You get this from taking the reference of function calls like "pos()" or "substr()".
#                 GLOB
#                 REF           wtf?
#                 FORMAT
#                 IO
#                 VSTRING
#                 Regexp

  my $stringy = "Foal shoals, and fouler bottoms beneath, our daddies, floundered nameless pygmy trees.";
  my $substr_ref = \substr( $stringy, 32, 7 );
  # ${ $substr_ref } = 'ABOVE'; # replace 'beneath' with "ABOVE'
  # print $stringy, "\n";

  my $fl_substr_ref = \substr( $stringy, 32+23, 10 );

  # (using "our" here to get table slots I can glob without warning)
  our $classy = 'Society';
  bless( $fl_substr_ref, $classy );

  our @cases =
     (
      [ 'lvalue (a substr ref)',  $substr_ref,         [ 'LVALUE',   undef ] ],
      [ 'lvalue (a substr ref)',  $fl_substr_ref,      [ 'LVALUE',   'Society' ] ],
      );

  my $one_glob_ref = \*cases;
  my $glob_ref     = \*classy;

  bless( $one_glob_ref, $classy );

  my @more_cases =
    (
      [ 'symbol table glob',  $glob_ref,      [ 'GLOB',   undef ] ],
      [ 'symbol table glob',  $one_glob_ref,  [ 'GLOB',   $classy ] ],
     );

  push @cases, @more_cases;

# I don't understand how these work, and it's useless beyond useless,
# no one uses perlform formats.
#
#    my $formatref     = *more_cases{FORMAT};
#    my $formatref_obj = *more_cases{FORMAT};
#    bless( $formatref_obj, $classy );
#    my @and_yes_more_cases =
#      (
#        [ 'formatref',          $formatref,      [ 'FORMAT',   undef ]  ],
#        [ 'blessed formatref',  $formatref_obj,  [ 'FORMAT',   $classy ] ],
#      );
#   push @cases, @and_yes_more_cases;


  foreach my $case ( @cases ) {
    my( $case, $arg, $exp ) = @{ $case };

    my $meta = classify( $arg );

    if( $DEBUG ) {
      print "case: ", $case, "\n";
      print "got: ", Dumper( $meta ), "\n";
      print "exp: ", Dumper( $exp ), "\n";
    }
    is_deeply( $meta, $exp, "$test_name like a $case" );
  }
}

{  my $test_name = "Testing classify on more useless cases";

   # an easy way to get IO refs
   my $ioref         = *STDIN{IO};
   my $ioref_obj     = *STDERR{IO};

   # # (using "our" here to get table slots I can glob without warning)
   # our $classy = 'Society';
   my $classy = 'Style';
   bless( $ioref_obj,     $classy );


   my( $case, $arg, $exp ) =
     # even unblessed IO has class
     ( 'ioref',          $ioref,      [ 'IO',   'IO::Handle' ]  );

   my $meta = classify( $arg );
   my $first  = $meta->[0];
   my $second = $meta->[1];

   is( $first, $exp->[0], # 'IO'
       "$test_name like a $case: 1st element" );

   my $exp_re = qr{ ^ IO:: (?: File | Handle ) $ }x;

   like( $second, $exp_re,
       "$test_name like a $case: 2nd element" );

   ( $case, $arg, $exp ) =
     # even unblessed IO has class
     ( 'blessed ioref',  $ioref_obj,  [ 'IO',   $classy ] );
   $meta = classify( $arg );
   is_deeply( $meta, $exp, "$test_name like a $case" );
}

done_testing();
