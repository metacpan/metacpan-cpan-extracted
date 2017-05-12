use Test::More;
use strict; use warnings qw/FATAL all/;

use POE;
use lib 't/inc';
use MxreTestUtils;

my $emitter_got      = {};
my $emitter_expected = {
  'Got emitter_started' => 2,
  'Got emitter_stopped' => 2,
};

{  package
    My::Emitter;
   use Moo;
   use POE;
   with 'MooX::Role::POE::Emitter';

   sub BUILD {
     my ($self) = @_;
     push @{ $self->object_states },
       $self => [ qw/
         emitter_started
         emitter_stopped
       / ];
     $self->_start_emitter;
   }

   sub emitter_started {
     $emitter_got->{'Got emitter_started'}++;
   }

   sub emitter_stopped {
     $emitter_got->{'Got emitter_stopped'}++;
   }
}

{  package
     My::Listener;
   use strictures 1;
   use POE;
   use Test::More;

   sub new {
     my $class = shift;
     my $self  = [];
     bless $self, $class;

     POE::Session->create(
       object_states => [
         $self => [ qw/
           _start
           emitted_registered
         / ],
       ],
     );

     $self
   }

   sub _start {
     my ($kernel, $self) = @_[KERNEL, OBJECT];
     my @emitters = map { My::Emitter->new } 1 .. 2;
     $kernel->post( $_, 'subscribe', 'all' )
       for @emitters;
   }

   sub emitted_registered {
     my ($kernel, $self) = @_[KERNEL, OBJECT];
     $kernel->signal( $kernel, 'SHUTDOWN_EMITTER' );
   }
}

My::Listener->new;
POE::Kernel->run;

test_expected_ok($emitter_got, $emitter_expected,
  'emitter signal tests produced expected result'
);

done_testing;
