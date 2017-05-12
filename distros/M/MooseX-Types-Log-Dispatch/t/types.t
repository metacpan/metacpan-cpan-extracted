
use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

#laziest test suite EVER. but it works and whatever its a brain-dead simple module

{
  package TestMXTypesLogDispatch;
  use Moose;
  use MooseX::Types::Log::Dispatch qw(Logger LogLevel);

  has logger => (
    isa => Logger,
    is => 'ro',
    coerce => 1,
  );

  has event_log_level => (
    isa => LogLevel,
    is => 'ro',
  );

  sub some_event_happened {
    my ($self, $event) = @_;
    $self->logger->log( level => $self->event_log_level, message => "$event happened");
  }
}

dies_ok {
  TestMXTypesLogDispatch->new( event_log_level => 'debbbug', );
} 'dies ok';

lives_ok {
  TestMXTypesLogDispatch->new( event_log_level => 'debug', );
} 'lives ok';

my $obj1;
lives_ok {
  $obj1 = TestMXTypesLogDispatch->new(
    event_log_level => 'debug',
    logger => [ ['Null', min_level => 'notice' ] ]
  );
} 'coerces ok';

## or
my $obj2;
lives_ok {
  $obj2 = TestMXTypesLogDispatch->new(
    event_log_level => 'warn',
    logger => { outputs => [ ['Null', min_level => 'debug' ] ] }
  );
} 'coerces ok';

lives_ok {
  $obj1->some_event_happened('zoom');
  $obj2->some_event_happened('zoom');
} 'logging actually works';
