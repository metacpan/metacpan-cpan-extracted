package RPC::ExtDirect::Event;

use strict;
use warnings;
no  warnings 'uninitialized';           ## no critic

use Carp;

use RPC::ExtDirect::Util::Accessor;

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Initialize a new Event instance
#

sub new {
    my $class = shift;
    
    # Allow passing either ordered parameters, or hashref,
    # or even a hash. This is to allow Mooseish and other
    # popular invocation patterns without having to pile on
    # argument converters or doing some other nonsense.
    my ($name, $data);
    
    if ( @_ == 1 ) {
        if ( 'HASH' eq ref $_[0] ) {
            $name = $_[0]->{name};
            $data = $_[0]->{data};
        }
        else {
            $name = $_[0];
        }
    }
    elsif ( @_ == 2 ) {
        $name = $_[0];
        $data = $_[1];
    }
    elsif ( @_ % 2 == 0 ) {
        my %arg = @_;
        
        $name = $arg{name};
        $data = $arg{data};
    }

    croak "Ext.Direct Event name is required"
        unless defined $name;

    my $self = bless { name => $name, data => $data }, $class;

    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# A stub for duck typing. Does nothing, returns failure.
#

sub run { !1 }

### PUBLIC INSTANCE METHOD ###
#
# Returns hashref with Event data. Named so for compatibility with
# Exceptions and Requests.
#

sub result {
    my ($self) = @_;

    return {
        type => 'event',
        name => $self->name,
        data => $self->data,
    };
}

### PUBLIC INSTANCE METHODS ###
#
# Simple read-write accessors
#

RPC::ExtDirect::Util::Accessor::mk_accessors(
    simple => [qw/ name data /],
);

1;
