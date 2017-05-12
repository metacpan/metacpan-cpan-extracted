package Solaris::ProcessContract::XS;

our $VERSION    = '1.01';
our $XS_VERSION = $VERSION;

# Standard modules
use strict;
use warnings;

# Base class
use parent 'Solaris::ProcessContract::Base';


#############################################################################
# Bootstrap
#############################################################################

# Bootstrap xs code
use XSLoader;
XSLoader::load 'Solaris::ProcessContract', $VERSION;


#############################################################################
# Constants
#############################################################################

# List of functions to expose as methods from the xs code
our @FUNCTIONS = qw(
  _open_template_fd
  _open_latest_fd
  _open_control_fd
  _close_fd
  _activate_template
  _clear_template
  _set_template_parameters
  _get_template_parameters
  _set_template_informative_events
  _get_template_informative_events
  _set_template_fatal_events
  _get_template_fatal_events
  _set_template_critical_events
  _get_template_critical_events
  _get_contract_id
  _abandon_contract
  _adopt_contract
);

# List of param flags to expose from the xs code
our @PARAM_FLAGS = qw(
  CT_PR_INHERIT
  CT_PR_NOORPHAN
  CT_PR_PGRPONLY
  CT_PR_REGENT
  CT_PR_ALLPARAM
);

# List of event flags to expose from the xs code
our @EVENT_FLAGS = qw(
  CT_PR_EV_EMPTY
  CT_PR_EV_FORK
  CT_PR_EV_EXIT
  CT_PR_EV_CORE
  CT_PR_EV_SIGNAL
  CT_PR_EV_HWERR
  CT_PR_ALLEVENT
  CT_PR_ALLFATAL
);


#############################################################################
# Exports
#############################################################################

use Exporter 'import';

our @EXPORT_OK =
(
  @PARAM_FLAGS,
  @EVENT_FLAGS, 
);

our %EXPORT_TAGS = 
(
  all         => [ @EXPORT_OK ],
  flags       => [ @PARAM_FLAGS, @EVENT_FLAGS ],
  param_flags => [ @PARAM_FLAGS ],
  event_flags => [ @EVENT_FLAGS ],
);


#############################################################################
# Object Methods
#############################################################################

# Invocation
sub new
{
  my ( $class, %opt ) = @_;

  my $self = $class->SUPER::new( %opt );

  $self->init();

  return $self;
}


# Initialize
sub init
{
  my ( $self ) = @_;

  $self->init_methods();

  return;
}


# Initialize xs function methods
sub init_methods
{
  my ( $self ) = @_;

  # Create a method for each xs function 
  FUNCTION: foreach my $function ( @FUNCTIONS )
  {
    $self->debug( "installing method for xs function: %s", $function );

    # Remove the initial underscore to figure out what the real public method
    # for this function should be called
    my $method = substr $function, 1;

    # Create a method handler that wraps our xs method with this function
    my $handler = sub 
    {
      my $self = shift;
      return $self->xs( $function, @_ );
    };
  
    # Install the method handler so that it can be accessed from an object
    # instance, and do so in a block so that we can disable warnings for just
    # this operation, as we are doing this on purpose
    {
      no strict 'refs';
      no warnings 'redefine';
      *{__PACKAGE__ . '::' . $method} = $handler;
    }

  }

}


#############################################################################
# Public Methods
#############################################################################

# Run an xs function
sub xs
{
  my ( $self, $function, @args ) = @_;

  # Make sure a function was passed in, and that the function is in the list
  # of xs functions we know about
  return if ! defined $function;
  return if ! grep { $function eq $_ } @FUNCTIONS;

  $self->debug( "calling xs function: %s", $function );

  # Execute the function wrapped in an eval so that we can capture any errors
  my $result = eval 
  {
    no strict 'refs';
    return $function->( @args );
  };

  # Throw exception if we saw an error
  if ( my $error = $@ )
  {
    Solaris::ProcessContract::Exception::XS->throw
    (
      error => $error,
    );
  };

  return $result;
}


1;

