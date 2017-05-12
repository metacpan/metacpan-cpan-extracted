# is a gearman worker

# gearman worker provides
# - registering all methods in this class
# - execute those methods through gearman calls
# - deamonizing the process

package RWDE::Gearman::Worker;

use strict;
use warnings;

use Error qw(:try);
use Storable qw( thaw nfreeze );
use Gearman::Worker;

use RWDE::Configuration;
use RWDE::DB::DbRegistry;
use RWDE::Exceptions;

use base qw(RWDE::Runnable);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 556 $ =~ /(\d+)/;

sub new {
  my ($proto, $params) = @_;

  my $class = ref($proto) || $proto;

  my $gear = Gearman::Worker->new();

  my $self = { gear => $gear };

  bless $self, $class;

  #connect to the server
  $gear->job_servers(@{ RWDE::Configuration->GearHost });

  #register a test method (every class should have one - for monitoring purposes it is in the caller's namespace)
  $self->register_method({ methods => 'ping' });

  #initialize give a chance to the inheriting class to register its exposed methods
  $self->initialize();

  return $self;
}

sub get_gear {
  my ($self, $params) = @_;

  throw RWDE::DevelException({ info => 'No worker present' })
    unless defined $self->{gear};

  return $self->{gear};
}

sub initialize {
  my ($self, $params) = @_;

  warn 'RWDE::Gearman::Worker->initialize should be overriden in subclasses, only ping will be exported';

  return ();
}

sub register_method {
  my ($self, $params) = @_;

  my $worker = $self->get_gear();

  my $namespace = ref $self;
  my $methods   = $$params{'methods'};

  if (ref $methods ne 'ARRAY') {
    $methods = [$methods];
  }

  foreach my $method (@{$methods}) {
    $worker->register_function($namespace . '::' . $method, \&RWDE::Gearman::Worker::handler);
  }

  return ();
}

sub start {
  my ($self, $params) = @_;

  my $gear = $self->get_gear();

  $self->syslog_msg('info', 'Worker starting: ' . (ref $self));

  while (1) {
    $gear->work();
  }

  return ();
}

#do interpretation of error results here - return back $ex and then end user can call throw on that
sub handler {
  my ($args) = @_;

  my $result;
  try {
    my $params = thaw(${ $args->argref });
    my $call   = $$params{method};

    $call =~ m/(.*)::(.*)/;

    my $namespace = $1;
    my $function  = $2;

    @$result = $namespace->$function($params);
  }

  catch Error with {
    my $ex = shift;

    warn $ex;

    #if we have an error, return it
    $result = $ex;
  };

  my $result_ref = \$result;
  return nfreeze $result_ref;
}

sub ping {
  my ($self, $params) = @_;

  return 1;
}

1;
