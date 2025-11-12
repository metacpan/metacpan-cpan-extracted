use Test::Requires '5.038';
use 5.038;
use strict;
use warnings;
use feature 'class';
no warnings 'experimental::class';
use Test::More;
use Test::Fatal;
## skip Test::Tabs

class My::Class {
  use Types::Standard 'CodeRef';
  field $attr :param = sub {};
  method attr ()         { $attr }
  method _set_attr($new) { $attr = $new }
  use Sub::HandlesVia::Declare [ 'attr', '_set_attr', sub { sub {} } ],
    Code => (
      'my_execute' => 'execute',
      'my_execute_list' => 'execute_list',
      'my_execute_method' => 'execute_method',
      'my_execute_method_list' => 'execute_method_list',
      'my_execute_method_scalar' => 'execute_method_scalar',
      'my_execute_method_void' => 'execute_method_void',
      'my_execute_scalar' => 'execute_scalar',
      'my_execute_void' => 'execute_void',
    );
}

## execute

can_ok( 'My::Class', 'my_execute' );

subtest 'Testing my_execute' => sub {
  my $e = exception {
    my $coderef = sub { 'code' };
    my $object  = My::Class->new( attr => $coderef );
    
    # Calls: $coderef->( 1, 2, 3 )
    $object->my_execute( 1, 2, 3 );
  };
  is( $e, undef, 'no exception thrown running execute example' );
};

## execute_list

can_ok( 'My::Class', 'my_execute_list' );

subtest 'Testing my_execute_list' => sub {
  my $e = exception {
    my $context;
    my $coderef = sub { $context = wantarray(); 'code' };
    my $object  = My::Class->new( attr => $coderef );
    
    # Calls: $coderef->( 1, 2, 3 )
    my $result = $object->my_execute_list( 1, 2, 3 );
    
    is_deeply( $result, [ 'code' ], q{$result deep match} );
    ok( $context, q{$context is true} );
  };
  is( $e, undef, 'no exception thrown running execute_list example' );
};

## execute_method

can_ok( 'My::Class', 'my_execute_method' );

subtest 'Testing my_execute_method' => sub {
  my $e = exception {
    my $coderef = sub { 'code' };
    my $object  = My::Class->new( attr => $coderef );
    
    # Calls: $coderef->( $object, 1, 2, 3 )
    $object->my_execute_method( 1, 2, 3 );
  };
  is( $e, undef, 'no exception thrown running execute_method example' );
};

## execute_method_list

can_ok( 'My::Class', 'my_execute_method_list' );

subtest 'Testing my_execute_method_list' => sub {
  my $e = exception {
    my $context;
    my $coderef = sub { $context = wantarray(); 'code' };
    my $object  = My::Class->new( attr => $coderef );
    
    # Calls: $coderef->( $object, 1, 2, 3 )
    my $result = $object->my_execute_method_list( 1, 2, 3 );
    
    is_deeply( $result, [ 'code' ], q{$result deep match} );
    ok( $context, q{$context is true} );
  };
  is( $e, undef, 'no exception thrown running execute_method_list example' );
};

## execute_method_scalar

can_ok( 'My::Class', 'my_execute_method_scalar' );

subtest 'Testing my_execute_method_scalar' => sub {
  my $e = exception {
    my $context;
    my $coderef = sub { $context = wantarray(); 'code' };
    my $object  = My::Class->new( attr => $coderef );
    
    # Calls: $coderef->( $object, 1, 2, 3 )
    my $result = $object->my_execute_method_scalar( 1, 2, 3 );
    
    is( $result, 'code', q{$result is 'code'} );
    ok( !($context), q{$context is false} );
  };
  is( $e, undef, 'no exception thrown running execute_method_scalar example' );
};

## execute_method_void

can_ok( 'My::Class', 'my_execute_method_void' );

subtest 'Testing my_execute_method_void' => sub {
  my $e = exception {
    my $context;
    my $coderef = sub { $context = wantarray(); 'code' };
    my $object  = My::Class->new( attr => $coderef );
    
    # Calls: $coderef->( $object, 1, 2, 3 )
    my $result = $object->my_execute_method_void( 1, 2, 3 );
    
    is( $result, undef, q{$result is undef} );
    is( $context, undef, q{$context is undef} );
  };
  is( $e, undef, 'no exception thrown running execute_method_void example' );
};

## execute_scalar

can_ok( 'My::Class', 'my_execute_scalar' );

subtest 'Testing my_execute_scalar' => sub {
  my $e = exception {
    my $context;
    my $coderef = sub { $context = wantarray(); 'code' };
    my $object  = My::Class->new( attr => $coderef );
    
    # Calls: $coderef->( 1, 2, 3 )
    my $result = $object->my_execute_scalar( 1, 2, 3 );
    
    is( $result, 'code', q{$result is 'code'} );
    ok( !($context), q{$context is false} );
  };
  is( $e, undef, 'no exception thrown running execute_scalar example' );
};

## execute_void

can_ok( 'My::Class', 'my_execute_void' );

subtest 'Testing my_execute_void' => sub {
  my $e = exception {
    my $context;
    my $coderef = sub { $context = wantarray(); 'code' };
    my $object  = My::Class->new( attr => $coderef );
    
    # Calls: $coderef->( 1, 2, 3 )
    my $result = $object->my_execute_void( 1, 2, 3 );
    
    is( $result, undef, q{$result is undef} );
    is( $context, undef, q{$context is undef} );
  };
  is( $e, undef, 'no exception thrown running execute_void example' );
};

## Using execute_method

subtest q{Using execute_method (extended example)} => sub {
  my $e = exception {
    use strict;
    use warnings;
    use Data::Dumper;
    
    {
      package My::Processor;
      use Moo;
      use Sub::HandlesVia;
      use Types::Standard qw( Str CodeRef );
      
      has name => (
        is => 'ro',
        isa => Str,
        default => 'Main Process',
      );
      
      my $NULL_CODEREF = sub {};
      
      has _debug => (
        is => 'ro',
        isa => CodeRef,
        handles_via => 'Code',
        handles => { debug => 'execute_method' },
        default => sub { $NULL_CODEREF },
        init_arg => 'debug',
      );
      
      sub _do_stuff {
        my $self = shift;
        $self->debug( 'continuing process' );
        return;
      }
      
      sub run_process {
        my $self = shift;
        $self->debug( 'starting process' );
        $self->_do_stuff;
        $self->debug( 'ending process' );
      }
    }
    
    my $p1 = My::Processor->new( name => 'First Process' );
    $p1->run_process; # no output
    
    my @got;
    my $p2 = My::Processor->new(
      name => 'Second Process',
      debug => sub {
        my ( $processor, $message ) = @_;
        push @got, sprintf( '%s: %s', $processor->name, $message );
      },
    );
    $p2->run_process; # logged output
    
    my @expected = (
      'Second Process: starting process',
      'Second Process: continuing process',
      'Second Process: ending process',
    );
    is_deeply( \@got, \@expected, q{\@got deep match} );
  };

  is( $e, undef, 'no exception thrown running example' );
};

done_testing;
