use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;
## skip Test::Tabs

{ package Local::Dummy1; use Test::Requires { 'Moo' => '1.006' } };

use constant { true => !!1, false => !!0 };

BEGIN {
  package My::Class;
  use Moo;
  use Sub::HandlesVia;
  use Types::Standard 'CodeRef';
  has attr => (
    is => 'rwp',
    isa => CodeRef,
    handles_via => 'Code',
    handles => {
      'my_execute' => 'execute',
      'my_execute_method' => 'execute_method',
    },
    default => sub { sub {} },
  );
};

## execute

can_ok( 'My::Class', 'my_execute' );

subtest 'Testing my_execute' => sub {
  my $e = exception {
    my $coderef = sub { 'code' };
    my $object  = My::Class->new( attr => $coderef );
    
    # $coderef->( 1, 2, 3 )
    $object->my_execute( 1, 2, 3 );
  };
  is( $e, undef, 'no exception thrown running execute example' );
};

## execute_method

can_ok( 'My::Class', 'my_execute_method' );

subtest 'Testing my_execute_method' => sub {
  my $e = exception {
    my $coderef = sub { 'code' };
    my $object  = My::Class->new( attr => $coderef );
    
    # $coderef->( $object, 1, 2, 3 )
    $object->my_execute_method( 1, 2, 3 );
  };
  is( $e, undef, 'no exception thrown running execute_method example' );
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
