## @file
# (Enter your file info here)
#
# $Id: Client.pm 462 2008-05-09 15:34:28Z damjan $

## @class RWDE::Gearman::Client
# (Enter RWDE::Gearman::Client info here)
package RWDE::Gearman::Client;

use strict;

use Error qw(:try);
use Gearman::Client;
use Storable qw( thaw nfreeze );

use RWDE::Configuration;
use RWDE::Exceptions;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 560 $ =~ /(\d+)/;

## @cmethod object new()
# Construct a new Gearman clients
# @return initialized object
sub new {
  my ($proto, $params) = @_;

  my $class = ref($proto) || $proto;

  my $gear = Gearman::Client->new();

  my $self = { gear => $gear };

  bless $self, $class;

  $gear->job_servers(@{ RWDE::Configuration->GearHost });

  $self->initialize();

  return $self;
}

## @method object get_gear()
# (Enter get_gear info here)
# @return (Enter explanation for return value----here)
sub get_gear {
  my ($self, $params) = @_;

  throw RWDE::DevelException({ info => 'No worker present' })
    unless defined $self->{gear};

  return $self->{gear};
}

## @method void initialize()
# Use this method to define initial behavior of the class. It should be overriden in subclasses
sub initialize {
  my ($self, $params) = @_;

  return;
}

## @cmethod object Do_task()
# Call the method do_task on the instance
# @return The value/reference produced by the RPC
sub Do_task {
  my ($self, $params) = @_;

  my $client = $self->new;

  return $client->do_task($params);
}

## @method object do_task($method)
# (Enter do_task info here)
# @param method  (Enter explanation for param here)
# @return The value/reference produced by the RPC
sub do_task {
  my ($self, $params) = @_;

  my $client = $self->get_gear();

  my $result_ref;

  try {
    local $SIG{ALRM} = sub { $self->alarm() };

    #waiting for longer than 5 seconds raises an exception
    alarm 5;

    #issue job
    $result_ref = $client->do_task($$params{method}, nfreeze($params));
    alarm 0;

    throw RWDE::DevelException({ info => 'Undefined error trying to execute ' })
      unless defined $result_ref;
  }

  catch Error with {
    my $ex = shift;

    if ($ex =~ m/Can't call method "syswrite" on an undefined value/) {
      throw RWDE::DevelException({ info => "Couldn't connect to Gearman server/worker pair\n" });
    }
    else {
      $ex->throw();
    }
  };

  my $result = thaw $$result_ref;
  $result = $$result;

  #temporarily support multi-element returns as the default case
  #special case the single element returns
  if ((ref $result eq 'ARRAY') && scalar @{$result} == 1) {
    $result = @{$result}[0];
  }

  #check for error
  if ((ref $result) =~ m/Exception/i || (ref $result) =~ m/Error::Simple/i) {

    #result is an exception :/
    $result->throw();
  }

  return $result;
}

## @method void alarm()
# Handle the timeout fromt the server by throwing an exception (devel)
sub alarm {
  my ($self, $params) = @_;

  throw RWDE::DevelException({ info => 'Haven\'t received response within allotted time' });

  return ();
}

1;
