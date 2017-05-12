package Solaris::ProcessContract::Contract::Control;

our $VERSION = '1.01';

# Standard modules
use strict;
use warnings;

# Base class
use parent 'Solaris::ProcessContract::Base';


#############################################################################
# Object Methods
#############################################################################

# Invocation
sub new
{
  my ( $class, %opt ) = @_;

  # Verify that an xs object was passed in
  if ( ! defined $opt{xs} )
  {
    Solaris::ProcessContract::Exception::Params->throw
    (
      error => "xs option is required when creating a new control object",
    );
  }

  # Verify that the xs object is really an xs object
  if ( ! ref $opt{xs} || ! $opt{xs}->isa('Solaris::ProcessContract::XS') )
  {
    Solaris::ProcessContract::Exception::Params->throw
    (
      error => "xs option must be a Solaris::ProcessContract::XS when creating a new control object",
    );
  }

  # Verify that id was passed in
  if ( ! defined $opt{id} )
  {
    Solaris::ProcessContract::Exception::Params->throw
    (
      error => "id is required when creating a new contract control object",
    );
  }  

  # Will hold a reference to the open file descriptor for the control, so
  # that we can always close it on destroy
  $opt{fd} = undef;

  # Create our object
  my $self = $class->SUPER::new( %opt );

  # Run initialization routines immediately
  $self->init;

  return $self;
}


# Destruction
sub DESTROY 
{
  my ( $self ) = @_;

  # Make sure to close our file descriptor when we go out of scope
  $self->close() if defined $self->{fd};

  return;
}


# Initialization
sub init
{
  my ( $self ) = @_;

  # Make sure to always open our file descriptor when we are initialized, as
  # it is needed for most every method in this class
  $self->open() if ! defined $self->{fd};

  return;
}


#############################################################################
# Public Methods
#############################################################################

# Abandon this contract, so that it no longer is running the calling process'
# contract space
sub abandon
{
  my ( $self ) = @_;
  
  $self->debug( "abandoning contract: %d", $self->{id} );

  $self->{xs}->abandon_contract( $self->fd );

  return;
}


# Adopt a previously abandonded contract, bringing it back in to the calling
# process' contract space
sub adopt
{
  my ( $self ) = @_;

  $self->debug( "abandoning contract: %d", $self->{id} );

  $self->{xs}->adopt_contract( $self->fd );

  return;
}


# Close and reopen the control file descriptor to reset it
sub reset
{
  my ( $self ) = @_;

  $self->debug( "resetting contract control file for: %d", $self->{id} );

  $self->close();
  $self->open();
}


#############################################################################
# Private Methods
#############################################################################

# Open the control file descriptor for this contract id
sub open
{
  my ( $self ) = @_;

  return if defined $self->{fd};
  return if ! defined $self->{id};

  $self->debug( "opening control file for contract: %d", $self->{id} );

  my $fd = $self->{xs}->open_control_fd( $self->{id} );

  $self->{fd} = $fd;

  return;
}


# Close the control file descriptor for this contract id
sub close
{
  my ( $self ) = @_;

  return if ! defined $self->{fd};

  $self->debug( "closing control file for contract: %d", $self->{id} );

  $self->{xs}->close_fd( $self->{fd} );

  undef $self->{fd};

  return;
}


# Convenience method to grab the open file descriptior, this is here for other
# methods to use so that they stop and throw an exception if the descriptor
# somehow disappears out from underneath us
sub fd
{
  my ( $self ) = @_;

  if ( ! defined $self->{fd} )
  {
    Solaris::ProcessContract::Exception->throw
    (
      error => "control file descriptor closed unexpectedly",
    );
  }

  return $self->{fd};
}


1;
