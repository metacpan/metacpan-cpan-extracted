#
# WARNING: This package is deprecated.
#
# See RPC::ExtDirect::Config perldoc for the description
# of the instance-based configuration options to be used
# instead of the former global variables in this package.
#

package RPC::ExtDirect::Serialize;

use strict;
use warnings;
no  warnings 'uninitialized';       ## no critic

### PACKAGE GLOBAL VARIABLE ###
#
# Turn on for debugging
#
# DEPRECATED. Use `debug_serialize` or `debug` Config options instead.
#

our $DEBUG;

### PACKAGE GLOBAL VARIABLE ###
#
# Set Exception class name so it could be configured
#
# DEPRECATED. Use `exception_class_serialize` or `exception_class`
# Config options instead.
#

our $EXCEPTION_CLASS;

### PUBLIC CLASS METHOD ###
#
# Serialize the passed data into JSON form
#
# DEPRECATED. Use RPC::ExtDirect::Serializer->serializer instance method
# instead.
#

sub serialize {
    # Class name
    shift;
    
    my $mute_exceptions = shift;
    
    warn __PACKAGE__.'->serialize class method is deprecated; ' .
                     'use RPC::ExtDirect::Serializer->serialize ' .
                     'instance method instead';
    
    require RPC::ExtDirect::Config;
    require RPC::ExtDirect::Serializer;
    
    my $config     = RPC::ExtDirect::Config->new();
    my $serializer = RPC::ExtDirect::Serializer->new( config => $config );
    
    return $serializer->serialize(
        mute_exceptions => $mute_exceptions,
        data => [ @_ ],
    );
}

1;
