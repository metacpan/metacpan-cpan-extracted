package RPC::ExtDirect::Config;

use strict;
use warnings;
no  warnings 'uninitialized';           ## no critic

use Carp;

use RPC::ExtDirect::Util::Accessor;
use RPC::ExtDirect::Util qw/ parse_global_flags /;

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Create a new Config instance
#

sub new {
    my $class = shift;
    
    my %arg;
    
    if ( @_ == 1 and 'HASH' eq ref $_[0] ) {
        %arg = %{ $_[0] };
    }
    elsif ( @_ % 2 == 0 ) {
        %arg = @_;
    }
    elsif ( @_ != 0 ) {
        croak "Odd number of arguments in RPC::ExtDirect::Config->new()";
    }
    
    my $self = bless {}, $class;
    
    $self->_init();
    $self->set_options(%arg);
    
    return $self;
}

### PUBLIC INSTANCE METHOD (CONSTRUCTOR) ###
#
# Create a new Config instance from existing one (clone it)
# We're only doing shallow copying here.
#

sub clone {
    my ($self) = @_;
    
    my $clone = bless {}, ref $self;
    
    @$clone{ keys %$self } = values %$self;
    
    return $clone;
}

### PUBLIC INSTANCE METHOD ###
#
# Re-parse the global vars
#

sub read_global_vars {
    my ($self) = @_;
    
    $self->_parse_global_vars();
    
    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Add specified accessors to the Config instance class
#

sub add_accessors {
    my ($self, %arg) = @_;
    
    RPC::ExtDirect::Util::Accessor->mk_accessors(
        class  => ref $self || $self, # Class method, too
        ignore => 1,
        %arg,
    );
    
    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Set the options in bulk by calling relevant setters
#

sub set_options {
    my $self = shift;
    
    my $debug = $self->debug;
    
    my %options = @_ == 1 && 'HASH' eq ref($_[0]) ? %{ $_[0] } : @_;
    
    foreach my $option (keys %options) {
        my $value = $options{$option};
        
        # We may as well be passed some options that we don't support;
        # that may happen by accident, or the options hash may be passed
        # on from unknown upper level. This does not represent a problem
        # per se, so rather than bomb out with a cryptic error if a setter
        # happens not to be defined, we warn in debug and silently ignore
        # such occurences when not debugging.
        if ( $self->can($option) ) {
            $self->$option($value);
        }
        elsif ( $debug ) {
            warn ref($self)." instance was passed a config option $option ".
                            "for which there is no setter. A mistake?";
        }
    }
    
    return $self;
}

#
# Note to self: the four deprecated methods below are *intentionally*
# left verbose and not collapsed to some helper sub.
#

### PUBLIC CLASS METHOD ###
#
# Return the default router path; provided for compatibility with 2.x
#
# DEPRECATED. Use `router_path` method on a Config instance instead.
#

sub get_router_path {
    warn __PACKAGE__."->get_router_path class method is deprecated; " .
                     "use router_path instance method instead";
    
    return __PACKAGE__->new->router_path;
}

### PUBLIC CLASS METHOD ###
#
# Return the default poll path; provided for compatibility with 2.x
#
# DEPRECATED. Use `poll_path` method on a Config instance instead.
#

sub get_poll_path {
    warn __PACKAGE__."->get_poll_path class method is deprecated; " .
                     "use poll_path instance method instead";
    
    return __PACKAGE__->new->poll_path;
}

### PUBLIC CLASS METHOD ###
#
# Return the default remoting variable name; provided for
# compatibility with 2.x
#
# DEPRECATED. Use `remoting_var` method on a Config instance instead.
#

sub get_remoting_var {
    warn __PACKAGE__."->get_remoting_var class method is deprecated; " .
                     "use remoting_var instance method instead";

    return __PACKAGE__->new->remoting_var;
}

### PUBLIC CLASS METHOD ###
#
# Return the default polling variable name; provided for
# compatibility with 2.x
#
# DEPRECATED. Use `polling_var` method on a Config instance instead.
#

sub get_polling_var {
    warn __PACKAGE__."->get_polling_var class method is deprecated; " .
                     "use polling_var instance method instead";
    
    return __PACKAGE__->new->polling_var;
}

############## PRIVATE METHODS BELOW ##############

#
# This humongous hashref holds definitions for all fields,
# accessors, default values and global variables involved
# with config objects.
# It's just easier to keep all this stuff in one place
# and pluck the pieces needed for various purposes.
#
my $DEFINITIONS = [{
    accessor => 'api_action_class',
    default  => 'RPC::ExtDirect::API::Action',
}, {
    accessor => 'api_method_class',
    default  => 'RPC::ExtDirect::API::Method',
}, {
    accessor => 'api_hook_class',
    default  => 'RPC::ExtDirect::API::Hook',
}, {
    accessor => 'api_full_action_names',
    default  => !1,
}, {
    accessor => 'debug',
    default  => !1,
}, {
    package  => 'RPC::ExtDirect::API',
    var      => 'DEBUG',
    type     => 'scalar',
    setter   => 'debug_api',
    fallback => 'debug',
}, {
    package  => 'RPC::ExtDirect::EventProvider',
    var      => 'DEBUG',
    type     => 'scalar',
    setter   => 'debug_eventprovider',
    fallback => 'debug',
}, {
    package  => 'RPC::ExtDirect::Serialize',
    var      => 'DEBUG',
    type     => 'scalar',
    setter   => 'debug_serialize',
    fallback => 'debug',
}, {
    package  => 'RPC::ExtDirect::Deserialize',
    var      => 'DEBUG',
    type     => 'scalar',
    setter   => 'debug_deserialize',
    fallback => 'debug',
}, {
    package  => 'RPC::ExtDirect::Request',
    var      => 'DEBUG',
    type     => 'scalar',
    setter   => 'debug_request',
    fallback => 'debug',
}, {
    package  => 'RPC::ExtDirect::Router',
    var      => 'DEBUG',
    type     => 'scalar',
    setter   => 'debug_router',
    fallback => 'debug',
}, {
    accessor => 'exception_class',
    default  => 'RPC::ExtDirect::Exception',
}, {
    package  => 'RPC::ExtDirect::Serialize',
    var      => 'EXCEPTION_CLASS',
    type     => 'scalar',
    setter   => 'exception_class_serialize',
    fallback => 'exception_class',
}, {
    package  => 'RPC::ExtDirect::Deserialize',
    var      => 'EXCEPTION_CLASS',
    type     => 'scalar',
    setter   => 'exception_class_deserialize',
    fallback => 'exception_class',
}, {
    package  => 'RPC::ExtDirect::Request',
    var      => 'EXCEPTION_CLASS',
    type     => 'scalar',
    setter   => 'exception_class_request',
    fallback => 'exception_class',
}, {
    accessor => 'request_class',
    default  => 'RPC::ExtDirect::Request',
}, {
    package  => 'RPC::ExtDirect::Deserialize',
    var      => 'REQUEST_CLASS',
    type     => 'scalar',
    setter   => 'request_class_deserialize',
    fallback => 'request_class',
}, {
    # This is a special case - can be overridden
    # but doesn't fall back to request_class
    accessor => 'request_class_eventprovider',
    default  => 'RPC::ExtDirect::Request::PollHandler',
}, {
    accessor => 'serializer_class',
    default  => 'RPC::ExtDirect::Serializer',
}, {
    setter   => 'serializer_class_api',
    fallback => 'serializer_class',
}, {
    package  => 'RPC::ExtDirect::Router',
    var      => 'SERIALIZER_CLASS',
    type     => 'scalar',
    setter   => 'serializer_class_router',
    fallback => 'serializer_class',
}, {
    package  => 'RPC::ExtDirect::EventProvider',
    var      => 'SERIALIZER_CLASS',
    type     => 'scalar',
    setter   => 'serializer_class_eventprovider',
    fallback => 'serializer_class',
}, {
    accessor => 'deserializer_class',
    default  => 'RPC::ExtDirect::Serializer',
}, {
    package  => 'RPC::ExtDirect::Router',
    var      => 'DESERIALIZER_CLASS',
    type     => 'scalar',
    setter   => 'deserializer_class_router',
    fallback => 'deserializer_class',
}, {
    accessor => 'json_options',
}, {
    setter   => 'json_options_serialize',
    fallback => 'json_options',
}, {
    package  => 'RPC::ExtDirect::Deserialize',
    var      => 'JSON_OPTIONS',
    type     => 'hash',
    setter   => 'json_options_deserialize',
    fallback => 'json_options',
}, {
    accessor => 'router_class',
    default  => 'RPC::ExtDirect::Router',
}, {
    accessor => 'timeout'
}, {
    accessor => 'max_retries'
}, {
    accessor => 'eventprovider_class',
    default  => 'RPC::ExtDirect::EventProvider',
}, {
    accessor => 'verbose_exceptions',
    default  => !1,  # In accordance with Ext.Direct spec
}, {
    accessor => 'api_path',
    default  => '/extdirectapi',
}, {
    accessor => 'router_path',
    default  => '/extdirectrouter',
}, {
    accessor => 'poll_path',
    default  => '/extdirectevents',
}, {
    accessor => 'remoting_var',
    default  => 'Ext.app.REMOTING_API',
}, {
    accessor => 'polling_var',
    default  => 'Ext.app.POLLING_API',
}, {
    accessor => 'namespace',
}, {
    accessor => 'auto_connect',
    default  => !1,
}, {
    accessor => 'no_polling',
    default  => !1,
}];

my @simple_accessors = map  { $_->{accessor} }
                       grep { $_->{accessor} }
                            @$DEFINITIONS;

my @complex_accessors = grep { $_->{fallback} } @$DEFINITIONS;

# Package globals are handled separately, this is only for
# accessors with default values
my %field_defaults = map  { $_->{accessor} => $_ }
                     grep { defined $_->{default} and !exists $_->{var} }
                          @$DEFINITIONS;

my @package_globals = grep { $_->{var} } @$DEFINITIONS;

### PRIVATE INSTANCE METHOD ###
#
# Return the default value for a field.
#

sub _get_default {
    my ($self, $field) = @_;
    
    my $def = $field_defaults{$field};
    
    return $def ? $def->{default} : undef;
}

### PRIVATE INSTANCE METHOD ###
#
# Return true if the current field value is the default.
#

sub _is_default {
    my ($self, $field) = @_;
    
    my $value   = $self->$field();
    my $default = $self->_get_default($field);
    
    return $value eq $default;
}

### PRIVATE INSTANCE METHOD ###
#
# Parse global package variables
#

sub _parse_global_vars {
    my ($self) = @_;
    
    parse_global_flags(\@package_globals, $self);
}

### PRIVATE INSTANCE METHOD ###
#
# Parse global package variables and apply default values
#

sub _init {
    my ($self) = @_;
    
    $self->_parse_global_vars();
    
    # Apply the defaults
    foreach my $field (keys %field_defaults) {
        my $def = $field_defaults{$field};
        my $default = $def->{default};
        
        $self->$field($default) unless defined $self->$field();
    }
}

### PRIVATE PACKAGE SUBROUTINE ###
#
# Export a deep copy of the definitions for testing
#

sub _get_definitions {
    return [ map { +{ %$_ } } @$DEFINITIONS ];
}

RPC::ExtDirect::Util::Accessor::mk_accessors(
    simple    => \@simple_accessors,
    complex   => \@complex_accessors,
    overwrite => 1,
);

1;
