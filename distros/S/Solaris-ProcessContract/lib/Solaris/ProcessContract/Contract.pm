package Solaris::ProcessContract::Contract;

our $VERSION = '1.01';

# Standard modules
use strict;
use warnings;

# Base class
use parent 'Solaris::ProcessContract::Base';

# Child classes
use Solaris::ProcessContract::Contract::Control;


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
      error => "xs option is required when creating a new contract object",
    );
  }

  # Verify that the xs object is really an xs object
  if ( ! ref $opt{xs} || ! $opt{xs}->isa('Solaris::ProcessContract::XS') )
  {
    Solaris::ProcessContract::Exception::Params->throw
    (
      error => "xs option must be a Solaris::ProcessContract::XS when creating a new contract object",
    );
  }

  # Verify that id was passed in
  if ( ! defined $opt{id} )
  {
    Solaris::ProcessContract::Exception::Params->throw
    (
      error => "id option is required when creating a new contract object",
    );
  }  

  # Will hold a reference to the control object for this contract
  $opt{control} = undef;

  # Create our object
  my $self = $class->SUPER::new( %opt );

  return $self;
}


# Destruction
sub DESTROY 
{
  my ( $self ) = @_;

  # Make sure the control object is destroyed when we go out of scope
  undef $self->{control} if defined $self->{control};

  return;
}


#############################################################################
# Public Methods
#############################################################################

# Return the id of this contract
sub id
{
  my ( $self ) = @_;

  return $self->{id};
}


# Return a reference to the control object for this contract
sub control
{
  my ( $self ) = @_;

  # Only create a control object if we need one
  if ( ! defined $self->{control} )
  {
    $self->debug( "creating new control object for contract: %d", $self->{id} );

    # Create the control object for this contract, and pass along our debug
    # setting and the xs class
    my $control = Solaris::ProcessContract::Contract::Control->new
    (
      debug => $self->{debug},
      xs    => $self->{xs},
      id    => $self->{id},
    );

    # Store the control object for the next time this method is called
    $self->{control} = $control;
  }

  return $self->{control};
}


1;
