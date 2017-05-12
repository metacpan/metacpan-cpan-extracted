
  # package ForceMoose; use Moose;


  package liquor::consumer; # "I'm not an alchoholic: alchoholics go to meetings."
  use Any::Moose; 
  use MooseX::Graph::Easy::StateMachine <<GRAPH; 
  [BASE] - WakeUp -> [sober] - drink -> [drunk] - wait -> [sober]
  [BASE] - drink -> [drunk] 
  [drunk] - passout -> [asleep] - wait -> [BASE] - wait -> [BASE]
  

GRAPH
 
  sub live{ my $self = shift; $self->WakeUp } 
  sub liquor::consumer::sober::live {  my $self = shift; $self->drink }
 
  package alchoholic; 
  use Any::Moose; use strict;
BEGIN { 
           extends ('liquor::consumer'); 
}; 

  has days_sober => (isa => 'Int', is => 'rw', required => 1);

  use MooseX::Graph::Easy::StateMachine <<GRAPH; 
  [sober] - GoToMeeting -> [sober] 
  [drunk] - GoToMeeting -> [sober] 
  [BASE] - GoToMeeting -> [sober] 
GRAPH
our @ISA;
#    warn "alchoholic::ISA is [@ISA]; drink method is ",\&drink;
  after 'drink' => sub { 
    my $self = shift; 
    $self->days_sober(0); 
  }; 
  after 'GoToMeeting' => sub { 
    my $self = shift; 
    $self->days_sober(1+$self->days_sober); 
  };
package alchoholic::sober;
  use Any::Moose; 
  after ('drink' => sub { 
    my $self = shift; 
    $self->days_sober(0); 
  }); 

  sub live{ my $self = shift; $self->GoToMeeting }
  after 'GoToMeeting' => sub { 
    my $self = shift; 
    $self->days_sober(1+$self->days_sober); 
  };




# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MooseX-Graph-Easy-StateMachine.t'

package Testpackage;

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;

my $drinker = liquor::consumer->new();
isa_ok ($drinker, 'liquor::consumer', 'base class new');
my $nondrinker = alchoholic->new(days_sober => 99);
isa_ok ($nondrinker, 'alchoholic', 'subclass new');

can_ok($drinker, qw/drink wait WakeUp/);
can_ok($nondrinker, qw/drink wait WakeUp GoToMeeting/);
is($nondrinker->days_sober, 99, 'attribute initialized');
$nondrinker->live;
isa_ok ($nondrinker, 'alchoholic::sober', 'method on base class');
is($nondrinker->days_sober, 99, 'attribute initialized');
$nondrinker->live;
isa_ok ($nondrinker, 'alchoholic::sober', 'method on base class');
is($nondrinker->days_sober, 100, 'attribute incremented in "after" in derived class');



done_testing;

__END__

