package Solaris::ProcessContract::Template;

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
      error => "xs option is required when creating a new template object",
    );
  }

  # Verify that the xs object is really an xs object
  if ( ! ref $opt{xs} || ! $opt{xs}->isa('Solaris::ProcessContract::XS') )
  {
    Solaris::ProcessContract::Exception::Params->throw
    (
      error => "xs option must be a Solaris::ProcessContract::XS when creating a new template object",
    );
  }

  # Will hold a reference to the open file descriptor for the template, so
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

# Set the behavior flags for this template
sub set_parameters
{
  my ( $self, $flags ) = @_;

  # Bail out now if no flags passed in, as this would do nothing anyhow
  return if ! defined $flags;

  $self->debug( "setting template parameteters to: %d", $flags );

  $self->{xs}->set_template_parameters( $self->fd, $flags );

  return;
}


# Returns the current parameters flags for this template
sub get_parameters
{
  my ( $self ) = @_;

  $self->debug( "getting template parameteters" );

  return $self->{xs}->get_template_parameters( $self->fd );
}


# Set the informative event monitoring flags for this template
sub set_informative_events
{
  my ( $self, $flags ) = @_;

  # Bail out now if no flags passed in, as this would do nothing anyhow
  return if ! defined $flags;

  $self->debug( "setting template informative events to: %d", $flags );

  $self->{xs}->set_template_informative_events( $self->fd, $flags );

  return;
}


# Returns the current event monitoring flags for this template
sub get_informative_events
{
  my ( $self ) = @_;

  $self->debug( "getting template informative events" );

  return $self->{xs}->get_template_informative_events( $self->fd );
}


# Set the fatal event monitoring flags for this template
sub set_fatal_events
{
  my ( $self, $flags ) = @_;

  # Bail out now if no flags passed in, as this would do nothing anyhow
  return if ! defined $flags;

  $self->debug( "setting template fatal events to: %d", $flags );

  $self->{xs}->set_template_fatal_events( $self->fd, $flags );

  return;
}


# Returns the current fatal event flags for this template
sub get_fatal_events
{
  my ( $self ) = @_;

  $self->debug( "getting template fatal events" );

  return $self->{xs}->get_template_fatal_events( $self->fd );
}


# Set the fatal event monitoring flags for this template
sub set_critical_events
{
  my ( $self, $flags ) = @_;

  # Bail out now if no flags passed in, as this would do nothing anyhow
  return if ! defined $flags;

  $self->debug( "setting template critical events to: %d", $flags );

  $self->{xs}->set_template_critical_events( $self->fd, $flags );

  return;
}


# Returns the current critical event flags for this template
sub get_critical_events
{
  my ( $self ) = @_;

  $self->debug( "getting template critical events" );

  return $self->{xs}->get_template_critical_events( $self->fd );
}


# Use this template the next time a new contract is created
sub activate
{
  my ( $self ) = @_;

  $self->debug( "activating template" );

  $self->{xs}->activate_template( $self->fd );

  return;
}


# Don't use this template the next time a new contract is created
sub clear
{
  my ( $self ) = @_;

  $self->debug( "clearing template" );

  $self->{xs}->clear_template( $self->fd );

  return;
}


# Close and reopen the file descriptors to refresh the template
sub reset
{
  my ( $self ) = @_;

  $self->debug( "resetting template" );

  $self->close();
  $self->open();

  return;
}


#############################################################################
# Private Methods
#############################################################################

# Open the template file descriptor
sub open
{
  my ( $self ) = @_;

  return if defined $self->{fd};

  $self->debug( "opening template file descriptor" );

  my $fd = $self->{xs}->open_template_fd();

  $self->{fd} = $fd;

  return;
}


# Close the template file descriptor
sub close
{
  my ( $self ) = @_;

  return if ! defined $self->{fd};

  $self->debug( "closing template file descriptor" );

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
      error => "template file descriptor closed unexpectedly",
    );
  }

  return $self->{fd};
}


1;
