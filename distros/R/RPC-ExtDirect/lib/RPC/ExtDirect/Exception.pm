package RPC::ExtDirect::Exception;

use strict;
use warnings;
no  warnings 'uninitialized';           ## no critic

use Carp;

use RPC::ExtDirect::Util::Accessor;
use RPC::ExtDirect::Util qw/ clean_error_message get_caller_info /;
    
### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Initializes new instance of Exception.
#

sub new {
    my ($class, $arg) = @_;

    my $where   = $arg->{where};
    my $message = $arg->{message};

    my $self = bless {
        debug   => $arg->{debug},
        action  => $arg->{action},
        method  => $arg->{method},
        tid     => $arg->{tid},
        verbose => $arg->{verbose},
    }, $class;

    $self->_set_error($message, $where);

    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# A stub for duck typing. Always returns failure.
#

sub run { '' }

### PUBLIC INSTANCE METHOD ###
#
# Returns exception hashref; named so for duck typing.
#

sub result {
    my ($self) = @_;

    return $self->_get_exception_hashref();
}

### PUBLIC INSTANCE METHODS ###
#
# Simple read-write accessors
#

RPC::ExtDirect::Util::Accessor::mk_accessors(
    simple => [qw/
        debug action method tid where message verbose
    /],
);

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Sets internal error condition and message
#

sub _set_error {
    my ($self, $message, $where) = @_;

    # Store the information
    $self->{where}   = defined $where ? $where : get_caller_info(3);
    $self->{message} = $message;

    # Ensure fall through for caller methods
    return !1;
}

### PRIVATE INSTANCE METHOD ###
#
# Returns exception hashref
#

sub _get_exception_hashref {
    my ($self) = @_;

    # If debug flag is not set, return generic message. This is for
    # compatibility with Ext.Direct specification.
    my ($where, $message);
    
    if ( $self->debug || $self->verbose ) {
        $where   = $self->where;
        $message = $self->message;
    }
    else {
        $where   = 'ExtDirect';
        $message = 'An error has occured while processing request';
    };

    # Format the hashref
    my $exception_ref = {
        type    => 'exception',
        action  => $self->action,
        method  => $self->method,
        tid     => $self->tid,
        where   => $where,
        message => $message,
    };

    return $exception_ref;
}

1;
