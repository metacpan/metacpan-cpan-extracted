package Solaris::ProcessContract;

our $VERSION = '1.01';

# Standard modules
use strict;
use warnings;

# Base class
use parent 'Solaris::ProcessContract::Base';

# Child classes
use Solaris::ProcessContract::XS qw(:all);
use Solaris::ProcessContract::Template;
use Solaris::ProcessContract::Contract;


#############################################################################
# Exports
#############################################################################

# We need to export the flags from the xs class, so we will import them above
# and then just resuse the export settings of the xs class
use Exporter 'import';

our @EXPORT_OK   = @Solaris::ProcessContract::XS::EXPORT_OK;
our %EXPORT_TAGS = %Solaris::ProcessContract::XS::EXPORT_TAGS;


#############################################################################
# Object Methods
#############################################################################

# Invocation
sub new
{
  my ( $class, %opt ) = @_;

  # Will hold a reference to the xs class we use for calling libcontract,
  # which will be passed around to any child classes so that they can use it
  # as well
  $opt{xs} = undef;

  # Create our object
  my $self = $class->SUPER::new( %opt );

  # Run initialization routines immediately
  $self->init();

  return $self;
}


# Destruction
sub DESTROY
{
  my ( $self ) = @_;
  return;
}


# Initialization
sub init
{
  my ( $self ) = @_;

  # We need our xs class to do anything in this module, so create one right
  # away if we don't have one already
  if ( ! defined $self->{xs} )
  {
    $self->debug( "creating new xs object" );

    my $xs = Solaris::ProcessContract::XS->new
    (
      debug => $self->{debug},
    );

    $self->{xs} = $xs;
  }

  return;
}


#############################################################################
# Public Methods
#############################################################################

# Create and return a new instance of the template class
sub get_template
{
  my ( $self ) = @_;

  $self->debug( "creating new template object" );

  # Create a new template instance, and pass along our debug flag and xs class
  # so that the template can use them as well
  my $template = Solaris::ProcessContract::Template->new
  (
    debug => $self->{debug},
    xs    => $self->{xs},
  );

  return $template;
}


# Get the latest process contract id
sub get_latest_contract_id
{
  my ( $self ) = @_;

  $self->debug( "getting latest contract id" );

  # Will hold the variables we need outside the eval
  my $latest_fd;
  my $id;

  # Run the following in an eval, so that we can always close the file
  # descriptor if something goes wrong
  eval 
  {
    # Attempt to open a file descriptor to the special "latest" contract file,
    # which will allow us to query what the most recent created contract id
    $latest_fd = $self->{xs}->open_latest_fd();

    # Query the file descriptor to get the the id
    $id = $self->{xs}->get_contract_id( $latest_fd );

    # Close the file descriptor
    $self->{xs}->close_fd( $latest_fd );
  };

  my $ex;
  my $error = $@;

  # If we caught an exception, make sure the file descriptor is closed and then
  # rethrow it
  if ( $ex = Solaris::ProcessContract::Exception->caught() )
  {
    $self->{xs}->close_fd( $latest_fd ) if defined $latest_fd;
    $ex->rethrow();
  }

  # If we got a generic error, make sure the file descriptor is closed and then
  # throw a new error
  if ( $error )
  {
    $self->{xs}->close_fd( $latest_fd ) if defined $latest_fd;
    Solaris::ProcessContract::Exception->throw
    (
      error => $error,
    );
  }

  return $id;
}


# Get a contract object for the latest contract
sub get_latest_contract
{
  my ( $self ) = @_;

  # Query out the latest contract id
  my $id = $self->get_latest_contract_id;

  # Make sure actually got an id before trying to create an object using it
  if ( ! $id )
  {
    Solaris::ProcessContract::Exception->throw
    (
      error => "failed to get latest contract id",
    );
  }

  # Create and return a contract object using this is
  return $self->get_contract( $id );
}


# Get a contract object for the specified contract id
sub get_contract
{
  my ( $self, $id ) = @_;

  # Throw an exception if no id was passed, since it is required for
  # creating a contract object
  if ( ! defined $id )
  {
    Solaris::ProcessContract::Exception::Params->throw
    (
      error => "id is required when calling get_contract",
    );
  }  

  $self->debug( "creating new process contract object for id %d", $id );

  # Create the contract object, and pass along our current debug settings and
  # xs class instance
  my $contract = Solaris::ProcessContract::Contract->new
  (
    debug => $self->{debug},
    xs    => $self->{xs},
    id    => $id,
  );

  return $contract;
}


1;

