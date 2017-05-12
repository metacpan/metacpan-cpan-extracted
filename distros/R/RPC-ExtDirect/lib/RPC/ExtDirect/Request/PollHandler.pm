package RPC::ExtDirect::Request::PollHandler;

# This private class implements overrides for Request
# to be used with EventProvider

use strict;
use warnings;
no  warnings 'uninitialized';           ## no critic

use base 'RPC::ExtDirect::Request';

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Initializes new instance of RPC::ExtDirect::Request
#

sub new {
    my ($class, $arg) = @_;
    
    my $self = $class->SUPER::new($arg);
    
    # We can't return exceptions from poll handler anyway
    return $self->{message} ? undef : $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Checks if method arguments are in order
#

sub check_arguments {

    # There are no parameters to poll handlers
    # so we return undef which means no error
    return undef;       ## no critic
}

### PUBLIC INSTANCE METHOD ###
#
# Return Events data extracted
#

sub result {
    my ($self) = @_;

    my $events = $self->{result};
    
    # A hook can return something that is not an event list
    $events = [] unless 'ARRAY' eq ref $events;
    
    return map { $_->result } @$events;
}

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Handles errors
#

sub _set_error {
    my ($self) = @_;
    
    $self->{result} = [];
}

1;
