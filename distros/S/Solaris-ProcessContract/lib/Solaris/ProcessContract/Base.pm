package Solaris::ProcessContract::Base;

our $VERSION = '1.01';

# Standard modules
use strict;
use warnings;

# Modules
use Try::Tiny;

# Exceptions
use Solaris::ProcessContract::Exceptions;


#############################################################################
# Object Methods
#############################################################################

# Invocation
sub new
{
  my ( $class, %opt ) = @_;

  # Turn the debug flag in to a real boolean value
  $opt{debug} = $opt{debug} ? 1 : 0;

  # Create our object
  my $self = bless \%opt, $class;

  return $self;
}


# Destruction
sub DESTROY
{
  my ( $self ) = @_;
  return;
}


#############################################################################
# Private Methods
#############################################################################

# Print debug messages if the debug flag is enabled
sub debug
{
  my ( $self, $message, @vals ) = @_;

  # Bail out now if debug mode isn't enabled
  return if ! $self->{debug};

  # Always kill newlines
  chomp $message;

  # Show the debug message on stderr
  printf STDERR "$message\n", @vals;

  return;
}


1;
