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
    
    # Calls: $coderef->( 1, 2, 3 )
    $object->my_execute( 1, 2, 3 );
  };
  is( $e, undef, 'no exception thrown running execute example' );
};

## execute_list

can_ok( $CLASS, 'my_execute_list' );

subtest 'Testing my_execute_list' => sub {
  my $e = exception {
    my $context;
    my $coderef = sub { $context = wantarray(); 'code' };
    my $object  = $CLASS->new( attr => $coderef );
    
    # Calls: $coderef->( 1, 2, 3 )
    my $result = $object->my_execute_list( 1, 2, 3 );
    
    is_deeply( $result, [ 'code' ], q{$result deep match} );
    ok( $context, q{$context is true} );
  };
  is( $e, undef, 'no exception thrown running execute_list example' );
};

## execute_method

can_ok( $CLASS, 'my_execute_method' );

subtest 'Testing my_execute_method' => sub {
  my $e = exception {
    my $coderef = sub { 'code' };
    my $object  = $CLASS->new( attr => $coderef );
    
    # Calls: $coderef->( $object, 1, 2, 3 )
    $object->my_execute_method( 1, 2, 3 );
  };
  is( $e, undef, 'no exception thrown running execute_method example' );
};

## execute_method_list

can_ok( $CLASS, 'my_execute_method_list' );

subtest 'Testing my_execute_method_list' => sub {
  my $e = exception {
    my $context;
    my $coderef = sub { $context = wantarray(); 'code' };
    my $object  = $CLASS->new( attr => $coderef );
    
    # Calls: $coderef->( $object, 1, 2, 3 )
    my $result = $object->my_execute_method_list( 1, 2, 3 );
    
    is_deeply( $result, [ 'code' ], q{$result deep match} );
    ok( $context, q{$context is true} );
  };
  is( $e, undef, 'no exception thrown running execute_method_list example' );
};

## execute_method_scalar

can_ok( $CLASS, 'my_execute_method_scalar' );

subtest 'Testing my_execute_method_scalar' => sub {
  my $e = exception {
    my $context;
    my $coderef = sub { $context = wantarray(); 'code' };
    my $object  = $CLASS->new( attr => $coderef );
    
    # Calls: $coderef->( $object, 1, 2, 3 )
    my $result = $object->my_execute_method_scalar( 1, 2, 3 );
    
    is( $result, 'code', q{$result is 'code'} );
    ok( !($context), q{$context is false} );
  };
  is( $e, undef, 'no exception thrown running execute_method_scalar example' );
};

## execute_method_void

can_ok( $CLASS, 'my_execute_method_void' );

subtest 'Testing my_execute_method_void' => sub {
  my $e = exception {
    my $context;
    my $coderef = sub { $context = wantarray(); 'code' };
    my $object  = $CLASS->new( attr => $coderef );
    
    # Calls: $coderef->( $object, 1, 2, 3 )
    my $result = $object->my_execute_method_void( 1, 2, 3 );
    
    is( $result, undef, q{$result is undef} );
    is( $context, undef, q{$context is undef} );
  };
  is( $e, undef, 'no exception thrown running execute_method_void example' );
};

## execute_scalar

can_ok( $CLASS, 'my_execute_scalar' );

subtest 'Testing my_execute_scalar' => sub {
  my $e = exception {
    my $context;
    my $coderef = sub { $context = wantarray(); 'code' };
    my $object  = $CLASS->new( attr => $coderef );
    
    # Calls: $coderef->( 1, 2, 3 )
    my $result = $object->my_execute_scalar( 1, 2, 3 );
    
    is( $result, 'code', q{$result is 'code'} );
    ok( !($context), q{$context is false} );
  };
  is( $e, undef, 'no exception thrown running execute_scalar example' );
};

## execute_void

can_ok( $CLASS, 'my_execute_void' );

subtest 'Testing my_execute_void' => sub {
  my $e = exception {
    my $context;
    my $coderef = sub { $context = wantarray(); 'code' };
    my $object  = $CLASS->new( attr => $coderef );
    
    # Calls: $coderef->( 1, 2, 3 )
    my $result = $object->my_execute_void( 1, 2, 3 );
    
    is( $result, undef, q{$result is undef} );
    is( $context, undef, q{$context is undef} );
  };
  is( $e, undef, 'no exception thrown running execute_void example' );
};

done_testing;
