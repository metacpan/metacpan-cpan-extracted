#
# WARNING: This package is deprecated.
#
# See RPC::ExtDirect::Config perldoc for the description
# of the instance-based configuration options to be used
# instead of the former global variables in this package.
#

package RPC::ExtDirect::Deserialize;

use strict;
use warnings;
no  warnings 'uninitialized';       ## no critic

### PACKAGE GLOBAL VARIABLE ###
#
# Set it to true value to turn on debugging
#
# DEPRECATED. Use `debug_deserialize` or `debug` Config options instead.
#

our $DEBUG;

### PACKAGE GLOBAL VARIABLE ###
#
# Set Exception class name so it could be configured
#
# DEPRECATED. Use `exception_class_deserialize` or `exception_class`
# Config options instead.
#

our $EXCEPTION_CLASS;

### PACKAGE GLOBAL VARIABLE ###
#
# Set Request class name so it could be configured
#
# DEPRECATED. Use `request_class_deserialize` or `request_class`
# Config options instead.
#

our $REQUEST_CLASS;

### PACKAGE GLOBAL VARIABLE ###
#
# JSON decoding options
#
# DEPRECATED. Use `json_options_deserialize` or `json_options`
# Config options instead.
#

our %JSON_OPTIONS;

### PUBLIC CLASS METHOD ###
#
# Turns JSONified POST request(s) into array of instantiated
# RPC::ExtDirect::Request (Exception) objects. Returns reference
# to array.
#
# DEPRECATED. Use RPC::ExtDirect::Serializer->decode_post() instead.
#

sub decode_post {
    shift; # class name
    
    my $post_text = shift;
    
    warn __PACKAGE__.'->decode_post class method is deprecated; ' .
                     'use RPC::ExtDirect::Serializer->decode_post ' .
                     'instance method instead';
    
    require RPC::ExtDirect::Config;
    require RPC::ExtDirect::Serializer;
    
    my $config     = RPC::ExtDirect::Config->new();
    my $serializer = RPC::ExtDirect::Serializer->new( config => $config );
    
    return $serializer->decode_post(
        data => $post_text,
        @_
    );
}

### PUBLIC CLASS METHOD ###
#
# Instantiates Request based on form submitted to ExtDirect handler
# Returns arrayref with single Request.
#
# DEPRECATED. Use RPC::ExtDirect::Serializer->decode_form() instead.
#

sub decode_form {
    shift; # class name
    
    my $form_href = shift;
    
    warn __PACKAGE__.'->decode_form class method is deprecated; ' .
                     'use RPC::ExtDirect::Serializer->decode_form ' .
                     'instance method instead';
    
    require RPC::ExtDirect::Config;
    require RPC::ExtDirect::Serializer;
    
    my $config     = RPC::ExtDirect::Config->new();
    my $serializer = RPC::ExtDirect::Serializer->new( config => $config );
    
    return $serializer->decode_form(
        data => $form_href,
        @_
    );
}

1;
