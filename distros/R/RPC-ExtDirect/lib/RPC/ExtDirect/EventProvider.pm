package RPC::ExtDirect::EventProvider;

use strict;
use warnings;
no  warnings 'uninitialized';           ## no critic

use RPC::ExtDirect::Util::Accessor;
use RPC::ExtDirect::Config;
use RPC::ExtDirect;
use RPC::ExtDirect::NoEvents;

### PACKAGE GLOBAL VARIABLE ###
#
# Turn this on for debugging.
#
# DEPRECATED. Use `debug_eventprovider` Config option instead.
# See RPC::ExtDirect::Config.
#

our $DEBUG;

### PACKAGE GLOBAL VARIABLE ###
#
# Set Serializer class name so it could be configured
#
# DEPRECATED. Use `serializer_class_eventprovider` or `serializer_class`
# Config options instead.
#

our $SERIALIZER_CLASS;

### PACKAGE GLOBAL VARIABLE ###
#
# DEPRECATED. This option did nothing in previous versions of
# RPC::ExtDirect library, and is ignored in 3.x+
#

our $EVENT_CLASS;

### PACKAGE GLOBAL VARIABLE ###
#
# Set Request class name so it could be configured
#
# DEPRECATED. Use `request_class_eventprovider` Config option instead.
#

our $REQUEST_CLASS;

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Create a new EventProvider object with default API and Config
#

sub new {
    my ($class, %arg) = @_;
    
    $arg{config} ||= RPC::ExtDirect::Config->new();
    $arg{api}    ||= RPC::ExtDirect->get_api();
    
    return bless { %arg }, $class;
}

### PUBLIC CLASS/INSTANCE METHOD ###
#
# Run all poll handlers in succession, collect the Events returned
# by them and return serialized representation suitable for passing
# on to client side.
#
# Note that the preferred way to call this method is on the EventProvider
# object instance, but we support the class-based way for backwards
# compatibility.
#
# Be aware that the only supported way to configure the EventProvider
# is to pass a Config object to the constructor and then call poll()
# on the instance.
#

sub poll {
    my ($class, $env) = @_;
    
    my $self = ref($class) ? $class : $class->new();
    
    my @poll_requests = $self->_get_poll_requests();

    # Even if we have nothing to poll, we must return a stub Event
    # or client side will throw an unhandled JavaScript exception
    return $self->_no_events unless @poll_requests;

    # Run all the requests and collect their results
    my @results = $self->_run_requests($env, \@poll_requests);

    # No events returned by the handlers? We still gotta return something.
    return $self->_no_events unless @results;

    # Polling results are always JSON; no content type needed
    my $serialized = $self->_serialize_results(@results);

    # And if serialization fails we have to return something positive
    return $serialized || $self->_no_events;
}

### PUBLIC INSTANCE METHODS ###
#
# Simple read-write accessors
#

RPC::ExtDirect::Util::Accessor::mk_accessors(
    simple => [qw/ api config /],
);

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Return a list of Request::PollHandler objects
#

sub _get_poll_requests {
    my ($self) = @_;

    # Compile the list of poll handler Methods
    my @handlers = $self->api->get_poll_handlers();

    # Now create the corresponding Request objects
    my @poll_requests;
    for my $handler ( @handlers ) {
        my $req = $self->_create_request($handler);

        push @poll_requests, $req if $req;
    };
    
    return @poll_requests;
}

### PRIVATE INSTANCE METHOD ###
#
# Create Request off a poll handler
#

sub _create_request {
    my ($self, $handler) = @_;
    
    my $config      = $self->config;
    my $api         = $self->api;
    my $action_name = $handler->action;
    my $method_name = $handler->name;
    
    my $request_class = $config->request_class_eventprovider;
    
    eval "require $request_class";
    
    my $req = $request_class->new({
        config => $config,
        api    => $api,
        action => $action_name,
        method => $method_name,
    });
    
    return $req;
}

### PRIVATE INSTANCE METHOD ###
#
# Run poll requests and collect results
#

sub _run_requests {
    my ($self, $env, $requests) = @_;
    
    # Run the requests
    $_->run($env) for @$requests;

    # Collect responses
    my @results = map { $_->result } @$requests;
    
    return @results;
}

### PRIVATE CLASS METHOD ###
#
# Serialize results
#

sub _serialize_results {
    my ($self, @results) = @_;
    
    # Fortunately, client side does understand more than on event
    # batched as array
    my $final_result = @results > 1 ? [ @results ]
                     :                  $results[0]
                     ;
    
    my $config = $self->config;
    my $api    = $self->api;
    my $debug  = $config->debug_eventprovider;
    
    my $serializer_class = $config->serializer_class_eventprovider;
    
    eval "require $serializer_class";
    
    my $serializer = $serializer_class->new(
        config => $config,
        api    => $api,
    );

    my $json = eval {
        $serializer->serialize(
            mute_exceptions => 1,
            debug           => $debug,
            data            => [$final_result],
        )
    };

    return $json;
}

### PRIVATE CLASS METHOD ###
#
# Serializes and returns a NoEvents object.
#

sub _no_events {
    my ($self) = @_;
    
    my $config = $self->config;
    my $api    = $self->api;
    my $debug  = $config->debug_eventprovider;
    
    my $serializer_class = $config->serializer_class_eventprovider;
    
    eval "require $serializer_class";
    
    my $serializer = $serializer_class->new(
        config => $config,
        api    => $api,
    );

    my $no_events  = RPC::ExtDirect::NoEvents->new();
    my $result     = $no_events->result();
    
    # NoEvents result can't blow up, hence no eval
    my $serialized = $serializer->serialize(
        mute_exceptions => !1,
        debug           => $debug,
        data            => [$result],
    );

    return $serialized;
}

1;
