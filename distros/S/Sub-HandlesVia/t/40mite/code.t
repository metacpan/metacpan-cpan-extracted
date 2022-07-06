use strict;
use warnings;
## skip Test::Tabs
use Test::More;
use Test::Requires '5.010001';
use Test::Fatal;
use FindBin qw($Bin);
use lib "$Bin/lib";

use MyTest::TestClass::Code;
my $CLASS = q[MyTest::TestClass::Code];

## execute

can_ok( $CLASS, 'my_execute' );

subtest 'Testing my_execute' => sub {
  my $e = exception {
    my $coderef = sub { 'code' };
    my $object  = $CLASS->new( attr => $coderef );
    
    # $coderef->( 1, 2, 3 )
    $object->my_execute( 1, 2, 3 );
  };
  is( $e, undef, 'no exception thrown running execute example' );
};

## execute_method

can_ok( $CLASS, 'my_execute_method' );

subtest 'Testing my_execute_method' => sub {
  my $e = exception {
    my $coderef = sub { 'code' };
    my $object  = $CLASS->new( attr => $coderef );
    
    # $coderef->( $object, 1, 2, 3 )
    $object->my_execute_method( 1, 2, 3 );
  };
  is( $e, undef, 'no exception thrown running execute_method example' );
};

done_testing;
