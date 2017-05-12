package RPC::ExtDirect::Router;

use strict;
use warnings;
no  warnings 'uninitialized';       ## no critic

use RPC::ExtDirect::Util::Accessor;
use RPC::ExtDirect::Config;
use RPC::ExtDirect;

### PACKAGE GLOBAL VARIABLE ###
#
# Turn this on for debug output
#
# DEPRECATED. Use `debug_router` or `debug` Config options instead.
#

our $DEBUG;

### PACKAGE GLOBAL VARIABLE ###
#
# Set Serializer class name so it could be configured
#
# DEPRECATED. Use `serializer_class_router` or `serializer_class`
# Config options instead.
#

our $SERIALIZER_CLASS;

### PACKAGE GLOBAL VARIABLE ###
#
# Set Deserializer class name so it could be configured
#
# DEPRECATED. Use `deserializer_class_router` or `deserializer_class`
# Config options instead.
#

our $DESERIALIZER_CLASS;

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

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Create a new Router object with default API and Config
#

sub new {
    my ($class, %arg) = @_;
    
    $arg{config} ||= RPC::ExtDirect::Config->new();
    $arg{api}    ||= RPC::ExtDirect->get_api();
    
    return bless { %arg }, $class;
}

### PUBLIC CLASS/INSTANCE METHOD ###
#
# Route the request(s) and return serialized responses
#
# Note that the preferred way to call this method is on the Router
# object instance, but we support the class-based way for backwards
# compatibility.
#
# Be aware that the only supported way to configure the Router
# is to pass a Config object to the constructor and then call route()
# on the instance.
#

sub route {
    my ($class, $input, $env) = @_;
    
    my $self = ref($class) ? $class : $class->new();
    
    # Decode requests
    my ($has_upload, $requests) = $self->_decode_requests($input);

    # Run requests and collect responses
    my $responses = $self->_run_requests($env, $requests);

    # Serialize responses
    my $result = $self->_serialize_responses($responses);

    my $http_response = $self->_format_response($result, $has_upload);
    
    return $http_response;
}

### PUBLIC INSTANCE METHODS ###
#
# Read-write accessors.
#

RPC::ExtDirect::Util::Accessor::mk_accessors(
    simple => [qw/ api config /],
);

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Decode requests
#

sub _decode_requests {
    my ($self, $input) = @_;
    
    # $input can be scalar containing POST data,
    # or a hashref containing form data
    my $has_form   = ref $input eq 'HASH';
    my $has_upload = $has_form && $input->{extUpload} eq 'true';
    
    my $config = $self->config;
    my $api    = $self->api;
    my $debug  = $config->debug_router;
    
    my $deserializer_class = $config->deserializer_class_router;
    
    eval "require $deserializer_class";
    
    my $dser = $deserializer_class->new( config => $config, api => $api );

    my $requests
        = $has_form ? $dser->decode_form(data => $input, debug => $debug)
        :             $dser->decode_post(data => $input, debug => $debug)
        ;
    
    return ($has_upload, $requests);
}

### PRIVATE INSTANCE METHOD ###
#
# Run the requests and return their results
#

sub _run_requests {
    my ($self, $env, $requests) = @_;

    my @responses;
    
    # Run the requests, collect the responses
    for my $request ( @$requests ) {
        $request->run($env);
        push @responses, $request->result();
    }

    return \@responses;
}

### PRIVATE INSTANCE METHOD ###
#
# Serialize the responses and return result
#

sub _serialize_responses {
    my ($self, $responses) = @_;
    
    my $api    = $self->api;
    my $config = $self->config;
    my $debug  = $config->debug_router;
    
    my $serializer_class = $config->serializer_class_router;
    
    eval "require $serializer_class";
    
    my $serializer
        = $serializer_class->new( config => $config, api => $api );

    my $result = $serializer->serialize(
        mute_exceptions => !1,
        debug           => $debug,
        data            => $responses,
    );
    
    return $result;
}

### PRIVATE INSTANCE METHOD ###
#
# Format Plack-compatible HTTP response
#

sub _format_response {
    my ($self, $result, $has_upload) = @_;
    
    # Wrap in HTML if that was form upload request
    $result = "<html><body><textarea>$result</textarea></body></html>"
        if $has_upload;

    # Form upload responses are JSON wrapped in HTML, not plain JSON
    my $content_type = $has_upload ? 'text/html' : 'application/json';

    # We need content length in octets
    my $content_length = do { no warnings; use bytes; length $result };

    return [
        200,
        [
            'Content-Type',   $content_type,
            'Content-Length', $content_length,
        ],
        [ $result ],
    ];
}

1;
