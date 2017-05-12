package RPC::ExtDirect::Client;

use strict;
use warnings;
no  warnings 'uninitialized';

use Carp;
use JSON;

use File::Spec;

use RPC::ExtDirect::Util ();
use RPC::ExtDirect::Config;
use RPC::ExtDirect;

#
# This module is not compatible with RPC::ExtDirect < 3.0
#

croak __PACKAGE__." requires RPC::ExtDirect 3.0+"
    if $RPC::ExtDirect::VERSION lt '3.0';

### PACKAGE GLOBAL VARIABLE ###
#
# Module version
#

our $VERSION = '1.25';

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Instantiate a new Client, connect to the specified server
# and initialize the Ext.Direct API
#

sub new {
    my ($class, %params) = @_;
    
    my $api    = delete $params{api};
    my $config = delete $params{config} || ($api && $api->config) ||
                 RPC::ExtDirect::Config->new();
    
    my $self = bless {
        config => $config,
        api    => {},
        tid    => 0,
    }, $class;
    
    $self->_decorate_config($config);
    $self->_decorate_api($api) if $api;
    
    my @config_params = qw/
        api_path router_path poll_path remoting_var polling_var
    /;
    
    for my $key ( @config_params ) {
        $config->$key( delete $params{ $key } )
            if exists $params{ $key };
    }
    
    my @our_params = qw/ host port proto cv cookies api_cb /;
    
    @$self{ @our_params } = delete @params{ @our_params };
    
    # The rest of parameters apply to the transport
    $self->http_params({ %params });
    
    # This may die()
    eval { $self->_init_api($api) };
    
    if ($@) { croak 'ARRAY' eq ref($@) ? $@->[0] : $@ };
    
    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Call specified Action's Method
#

sub call { shift->sync_request('call', @_) }

### PUBLIC INSTANCE METHOD ###
#
# Submit a form to specified Action's Method
#

sub submit { shift->sync_request('form', @_) }

### PUBLIC INSTANCE METHOD ###
#
# Upload a file using POST form. Same as submit()
#

*upload = *submit;

### PUBLIC INSTANCE METHOD ###
#
# Poll server for Ext.Direct events
#

sub poll { shift->sync_request('poll', @_) }

### PUBLIC INSTANCE METHOD ###
#
# Run a specified request type synchronously
#

sub sync_request {
    my $self = shift;
    my $type = shift;
    
    my $tr_class = $self->transaction_class;
    
    my $resp = eval {
        my $transaction = $tr_class->new(@_);
        $self->_sync_request($type, $transaction);
    };
    
    #
    # Internally we throw an exception string enclosed in arrayref,
    # so that die() wouldn't munge it. Easier to do and beats stripping
    # that \n any time. JSON or other packages could throw a plain string
    # though, so we need to guard against that.
    #
    # Rethrow by croak(), and don't strip the file name and line number
    # this time -- seeing exactly where the thing blew up in *your*
    # code is a lot more helpful to a developer than the plain old die()
    # exception would allow.
    #
    if ($@) { croak 'ARRAY' eq ref($@) ? $@->[0] : $@ };
    
    # We're only interested in the data, unless it's a poll. In versions
    # < 1.0, we used to return a scalar value for polls, either a single
    # event or an arrayref of event hashrefs; that behavior was more or
    # less closely following the spec and typical server response.
    # However that was kinda awkward, so we try to DWIM here and adjust
    # to the caller's expectations.
    if ( $type eq 'poll') {
        return wantarray   ? @$resp
             : @$resp == 1 ? $resp->[0]
             :               $resp
             ;
    }
    
    return ref($resp) =~ /Exception/ ? $resp : $resp->{result};
}

### PUBLIC INSTANCE METHOD ###
#
# Return next TID (transaction ID)
#

sub next_tid { $_[0]->{tid}++ }

### PUBLIC INSTANCE METHOD ###
#
# Return API object by its type
#

sub get_api {
    my ($self, $type) = @_;
    
    return $self->{api}->{$type};
}

### PUBLIC INSTANCE METHOD ###
#
# Store the passed API object according to its type
#

sub set_api {
    my ($self, $api, $type) = @_;
    
    $type ||= $api->type;
    
    $self->{api}->{$type} = $api;
}

### PUBLIC INSTANCE METHODS ###
#
# Read-only accessor delegates
#

sub remoting_var { $_[0]->config->remoting_var }
sub polling_var  { $_[0]->config->polling_var  }

### PUBLIC INSTANCE METHOD ###
#
# Return the name of the Transaction class. This was not made
# a Config option since the only case when somebody would want
# to change that is in a subclass.
#

sub transaction_class { 'RPC::ExtDirect::Client::Transaction' }

### PUBLIC INSTANCE METHODS ###
#
# Read-write accessors
#

RPC::ExtDirect::Util::Accessor->mk_accessor(
    simple => [qw/ config host port proto cv cookies http_params api_cb /],
);

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Create a new Exception object
#

sub _exception {
    my ($self, $ex) = @_;
    
    my $config  = $self->config;
    my $exclass = $config->exception_class;
    
    eval "require $exclass";
    
    return $exclass->new($ex);
}

### PRIVATE INSTANCE METHOD ###
#
# Add the Client-specific accessors to a Config instance
# and set defaults
#

my %std_config = (
    api_class_client => 'RPC::ExtDirect::Client::API',
    transport_class  => 'HTTP::Tiny',
);

sub _decorate_config {
    my ($self, $config) = @_;
    
    $config->add_accessors(
        overwrite => 1,
        simple    => [ keys %std_config ],
    );
    
    for my $key ( keys %std_config ) {
        my $predicate = "has_${key}";
        
        $config->$key( $std_config{ $key } )
            unless $config->$predicate;
        
        # This is the best place to load the classes, too
        # since we only want to do this once.
        eval "require " . $config->$key;
    }
    
    my $std_m_class = 'RPC::ExtDirect::Client::API::Method';
    
    $config->api_method_class($std_m_class)
        if $config->_is_default('api_method_class');
    
    # Client uses a flavor of API::Method with disabled
    # metadata arg checks; since the user might have set
    # the config value we want to make sure the class
    # has relevant overrides.
    my $actual_m_class = $config->api_method_class;
    
    croak  __PACKAGE__ . " is configured to use API Method class ".
           "$actual_m_class that is not a subclass of $std_m_class"
        unless $actual_m_class eq $std_m_class ||
               $actual_m_class->isa($std_m_class);
}

### PRIVATE INSTANCE METHOD ###
#
# Make sure that the API instance passed to us is a subclass
# of RPC::ExtDirect::Client::API
#

sub _decorate_api {
    my ($self, $api) = @_;
    
    my $api_class = $self->config->api_class_client;
    
    bless $api, $api_class unless $api->isa($api_class);
}

### PRIVATE INSTANCE METHOD ###
#
# Initialize API declaration.
#
# The two-step between _init_api and _import_api is to allow
# async API retrieval and processing in Client::Async without
# duplicating more code than is necessary
#

sub _init_api {
    my ($self, $api) = @_;
    
    if ( $api ) {
        $self->_assign_api($api);
    }
    else {
        my $api_js = $self->_get_api();
        
        $self->_import_api($api_js);
    }
}

### PRIVATE INSTANCE METHOD ###
#
# Assign API object to the corresponding slots
#

sub _assign_api {
    my ($self, $api) = @_;
    
    $self->set_api($api, 'remoting');
    
    if ( $api->get_poll_handlers ) {
        $self->set_api($api, 'polling');
    }
}

### PRIVATE INSTANCE METHOD ###
#
# Receive API declaration from specified server,
# parse it and return Client::API object
#

sub _get_api {
    my ($self) = @_;

    my $uri    = $self->_get_uri('api');
    my $params = $self->http_params;
    
    my $transport_class = $self->config->transport_class;

    my $resp = $transport_class->new(%$params)->get($uri);

    die ["Can't download API declaration: $resp->{status} $resp->{content}"]
        unless $resp->{success};

    die ["Empty API declaration"] unless length $resp->{content};

    return $resp->{content};
}

### PRIVATE INSTANCE METHOD ###
#
# Import specified API into global namespace
#

sub _import_api {
    my ($self, $api_js) = @_;
    
    my $config       = $self->config;
    my $remoting_var = $config->remoting_var;
    my $polling_var  = $config->polling_var;
    my $api_class    = $config->api_class_client;
    
    eval "require $api_class";
    
    $api_js =~ s/\s*//gms;
    
    my @parts = split /;\s*/, $api_js;
    
    my $api_regex = qr/^\Q$remoting_var\E|\Q$polling_var\E/;
    
    for my $part ( @parts ) {
        next unless $part =~ $api_regex;
        
        my $api = $api_class->new_from_js(
            config => $config,
            js     => $part,
        );
        
        $self->set_api($api);
    }
}

### PRIVATE INSTANCE METHOD ###
#
# Return URI for specified type of call
#

sub _get_uri {
    my ($self, $type) = @_;
    
    my $config = $self->config;
    
    my $api;
    
    if ( $type eq 'remoting' || $type eq 'polling' ) {
        $api = $self->get_api($type);
    
        die ["Don't have API definition for type $type"]
            unless $api;
    }
    
    my $proto = $self->proto || 'http';
    my $host = $self->host;
    my $port = $self->port;

    my $path = $type eq 'api'      ? $config->api_path
             : $type eq 'remoting' ? $api->url || $config->router_path
             : $type eq 'polling'  ? $api->url || $config->poll_path
             :                       die ["Unknown type $type"]
             ;

    $path    =~ s{^/}{};

    my $uri  = $port ? "$proto://$host:$port/$path"
             :         "$proto://$host/$path"
             ;

    return $uri;
}

### PRIVATE INSTANCE METHOD ###
#
# Normalize passed arguments to conform to Method's spec
#

sub _normalize_arg {
    my ($self, $method, $trans) = @_;
    
    my $arg = $trans->arg;
    
    # This could die with a message that has \n at the end to prevent
    # file and line being appended. Catch and rethrow in a format
    # more compatible with what Client does in other places.
    eval { $method->check_method_arguments($arg) };
    
    if ( my $xcpt = $@ ) {
        $xcpt =~ s/\n$//;
        die [$xcpt];
    }

    my $result = $method->prepare_method_arguments( input => $arg );

    return $result;
}

### PRIVATE INSTANCE METHOD ###
#
# Normalize passed metadata to conform to Method's spec
#

sub _normalize_metadata {
    my ($self, $method, $trans) = @_;
    
    my $meta = $trans->metadata;
    
    # See _normalize_arg above
    eval { $method->check_method_metadata($meta) };
    
    if ( my $xcpt = $@ ) {
        $xcpt =~ s/\n$//;
        die [$xcpt];
    }
    
    my $result = $method->prepare_method_metadata( metadata => $meta );
    
    return $result;
}

### PRIVATE INSTANCE METHOD ###
#
# Normalize passed arguments to submit as form POST
#

sub _formalize_arg {
    my ($self, $method, $trans) = @_;
    
    my $arg    = $trans->arg;
    my $upload = $trans->upload;
    
    # formHandler method require arguments in a hashref and will die
    # with an error if the arguments are missing. However it is often
    # convenient to call Client->upload() with empty arg but with a
    # list of file names to upload; it doesn't make a lot of sense to
    # insist on providing an empty argument hashref just for the sake
    # of being strict.
    $arg = $arg || {} if $upload;
    
    # This could die with a message that has \n at the end to prevent
    # file and line being appended. Catch and rethrow in a format
    # more compatible with what Client does in other places.
    eval { $method->check_method_arguments($arg) };
    
    if ( my $xcpt = $@ ) {
        $xcpt =~ s/\n$//;
        die [$xcpt];
    }
    
    my $fields = {
        extAction => $method->action,
        extMethod => $method->name,
        extType   => 'rpc',
        extTID    => $self->next_tid,
    };

    # Go over the uploads and check if they're readable; die if not
    for my $file ( @$upload ) {
        die ["Upload entry '$file' is not readable"] unless -r $file;
    }
    
    $fields->{extUpload} = 'true' if $upload;

    my $actual_arg = $method->prepare_method_arguments( input => $arg );
    
    @$fields{ keys %$actual_arg } = values %$actual_arg;

    # This will die in approved format, so no outer eval
    my $meta_json = $self->_formalize_metadata($method, $trans);
    
    $fields->{metadata} = $meta_json if $meta_json;

    return $fields;
}

### PRIVATE INSTANCE METHOD ###
#
# Normalize passed metadata to conform to Method's spec
# and encode in JSON to be submitted in a form POST
#

sub _formalize_metadata {
    my ($self, $method, $transaction) = @_;
    
    my $meta_json;
    
    # This will die according to plan so no outer eval
    my $metadata = $self->_normalize_metadata($method, $transaction);
    
    if ( $metadata ) {
        # This won't die according to plan :(
        $meta_json = eval { JSON::to_json($metadata) };
    
        if ( $@ ) {
            my $xcpt = RPC::ExtDirect::Util::clean_error_message($@);
            die [$xcpt];
        }
    }
    
    return $meta_json;
}

### PRIVATE INSTANCE METHOD ###
#
# Make an HTTP request in synchronous fashion. Note that we do not
# guard against exceptions here, they should be propagated upwards
# to be caught in public sync_request() that calls this one.
#

sub _sync_request {
    my ($self, $type, $transaction) = @_;
    
    my $prepare = "_prepare_${type}_request";
    my $handle  = "_handle_${type}_response";
    my $method  = $type eq 'poll' ? 'GET' : 'POST';
    
    my ($uri, $request_content, $http_params, $request_options)
        = $self->$prepare($transaction);
    
    $request_options->{content} = $request_content;
    
    my $transport_class = $self->config->transport_class;
    
    my $transport = $transport_class->new(%$http_params);
    my $response  = $transport->request($method, $uri, $request_options);
    
    # By Ext.Direct spec that shouldn't even happen; however the transport
    # may crap out or something else might cause a failed request.
    # Status code 599 is internal for HTTP::Tiny, with the error message
    # placed in the response content.
    if (!$response->{success}) {
        my $err = $response->{status} == 599 ? $response->{content}
                :                              $response->{status}
                ;
        die ["Ext.Direct request unsuccessful: $err"];
    }
    
    return $self->$handle($response, $transaction);
}

### PRIVATE INSTANCE METHOD ###
#
# Prepare the POST body, headers, request options and other
# data necessary to make an HTTP request for a non-form call
#

sub _prepare_call_request {
    my ($self, $transaction) = @_;
    
    my $action_name = $transaction->action;
    my $method_name = $transaction->method;
    
    my $api    = $self->get_api('remoting');
    my $action = $api->get_action_by_name($action_name);
    
    die ["Action $action_name is not found"] unless $action;
    
    my $method = $action->method($method_name);
    
    die ["Method $method_name is not found in Action $action_name"]
        unless $method;
    
    my $actual_arg = $self->_normalize_arg($method, $transaction);
    my $metadata   = $self->_normalize_metadata($method, $transaction);
    
    my $post_body = $self->_encode_post_body(
        action   => $action_name,
        method   => $method_name,
        data     => $actual_arg,
        metadata => $metadata,
    );
    
    # HTTP params is a union between transaction params and client params.
    my $http_params = $self->_merge_params($transaction);

    my $request_options = {
        headers => { 'Content-Type' => 'application/json', }
    };

    $self->_parse_cookies($request_options, $http_params);

    my $uri = $self->_get_uri('remoting');
    
    return (
        $uri,
        $post_body,
        $http_params,
        $request_options,
    );
}

### PRIVATE INSTANCE METHOD ###
#
# Prepare the POST body, headers, request options and other
# data necessary to make an HTTP request for a form call
#

sub _prepare_form_request {
    my ($self, $transaction) = @_;
    
    my $action_name = $transaction->action;
    my $method_name = $transaction->method;
    
    my $api = $self->get_api('remoting');
    my $action = $api->get_action_by_name($action_name);
    
    die ["Action $action_name is not found"] unless $action;
    
    my $method = $action->method($method_name);
    
    die ["Method $method_name is not found in Action $action_name"]
        unless $method;
    
    my $fields = $self->_formalize_arg($method, $transaction);
    my $upload = $transaction->upload;
    
    my $form_body
        = $upload ? $self->_www_form_multipart($fields, $upload)
        :           $self->_www_form_urlencode($fields)
        ;
    
    my $ct
        = $upload ? 'multipart/form-data; boundary='.$self->_get_boundary
        :           'application/x-www-form-urlencoded; charset=utf-8'
        ;
    
    my $request_options = {
        headers => { 'Content-Type' => $ct, },
    };
    
    my $http_params = $self->_merge_params($transaction);
    
    $self->_parse_cookies($request_options, $http_params);
    
    my $uri = $self->_get_uri('remoting');
    
    return (
        $uri,
        $form_body,
        $http_params,
        $request_options,
    );
}

### PRIVATE INSTANCE METHOD ###
#
# Prepare the POST body, headers, request options and other
# data necessary to make an HTTP request for an event poll
#

sub _prepare_poll_request {
    my ($self, $transaction) = @_;
    
    my $uri = $self->_get_uri('polling');
    
    my $http_params = $self->_merge_params($transaction);
    
    my $request_options = {
        headers => { 'Content-Type' => 'application/json' },
    };
    
    $self->_parse_cookies($request_options, $http_params);
    
    return (
        $uri,
        undef,
        $http_params,
        $request_options,
    );
}

### PRIVATE INSTANCE METHOD ###
#
# Create POST payload body
#

sub _create_post_payload {
    my ($self, %arg) = @_;
    
    my $href = {
        type   => 'rpc',
        tid    => $self->next_tid,
        action => $arg{action},
        method => $arg{method},
        data   => $arg{data},
    };
    
    $href->{metadata} = $arg{metadata}
        if exists $arg{metadata};
    
    return $href;
}

### PRIVATE INSTANCE METHOD ###
#
# Encode post payload body
#

sub _encode_post_body {
    my $self = shift;
    
    my $payload = $self->_create_post_payload(@_);

    return JSON->new->utf8(1)->encode($payload);
}

### PRIVATE INSTANCE METHOD ###
#
# Encode form fields as multipart/form-data
#

sub _www_form_multipart {
    my ($self, $arg, $uploads) = @_;

    # This code is shamelessly "adapted" from CGI::Test::Input::Multipart
    my $CRLF     = "\015\012";
    my $boundary = '--' . $self->_get_boundary();
    my $format   = 'Content-Disposition: form-data; name="%s"';

    my $result;

    foreach my $field (keys %$arg) {
        my $value = $arg->{$field};
        
        $result .= $boundary                . $CRLF;
        $result .= sprintf($format, $field) . $CRLF.$CRLF;
        $result .= $value                   . $CRLF;
    };

    while ( $uploads && @$uploads ) {
        my $filename = shift @$uploads;
        my $basename = (File::Spec->splitpath($filename))[2];

        $result .= $boundary                                . $CRLF;
        $result .= sprintf $format, 'upload';
        $result .= sprintf('; filename="%s"', $basename)    . $CRLF;
        $result .= "Content-Type: application/octet-stream" . $CRLF.$CRLF;

        if ( open my $fh, '<', $filename ) {
            binmode $fh;
            local $/;

            $result .= <$fh> . $CRLF;
        };
    }

    $result .= $boundary . '--' if $result;

    return $result;
}

### PRIVATE INSTANCE METHOD ###
#
# Generate multipart/form-data boundary
#

my $boundary;

sub _get_boundary {
    return $boundary if $boundary;
    
    my $rand;

    for ( 0..19 ) {
        $rand .= (0..9, 'A'..'Z')[$_] for int rand 36;
    };

    return $boundary = $rand;
}

### PRIVATE INSTANCE METHOD ###
#
# Encode form fields as application/x-www-form-urlencoded
#

sub _www_form_urlencode {
    my ($self, $arg) = @_;
    
    my $transport_class = $self->config->transport_class;

    return $transport_class->new->www_form_urlencode($arg);
}

### PRIVATE INSTANCE METHOD ###
#
# Produce a union of transaction HTTP parameters
# with client HTTP parameters
#

sub _merge_params {
    my ($self, $trans) = @_;
    
    my %client_params = %{ $self->http_params };
    my %trans_params  = %{ $trans->http_params };
    
    # Transaction parameters trump client's
    @client_params{ keys %trans_params } = values %trans_params;
    
    # Cookies from transaction trump client's as well,
    # but replace them entirely instead of combining
    $client_params{cookies} = $trans->cookies || $self->cookies;
    
    return \%client_params;
}

### PRIVATE INSTANCE METHOD ###
#
# Process Ext.Direct response and return either data or exception
#

sub _handle_call_response {
    my ($self, $resp) = @_;
    
    my $content = $self->_decode_response_body( $resp->{content} );
    
    return $self->_exception($content)
        if 'HASH' eq ref $content and $content->{type} eq 'exception';
    
    return $content;
}

*_handle_form_response = *_handle_call_response;

### PRIVATE INSTANCE METHOD ###
#
# Handle poll response
#

sub _handle_poll_response {
    my ($self, $resp) = @_;

    # JSON->decode can die()
    my $ev = $self->_decode_response_body( $resp->{content} );

    # Poll provider has to return a null event if there are no events
    # because returning empty response would break JavaScript client
    # in certain (now outdated) Ext JS versions. The server has to keep
    # the compatible behavior but we don't have to follow that
    # broken implementation here.
    return []
        if ('HASH' ne ref $ev and 'ARRAY' ne ref $ev) or
           ('HASH' eq ref $ev and
                ($ev->{name} eq '__NONE__' or $ev->{name} eq '' or
                 $ev->{type} ne 'event')
           )
        ;
    
    # Server side can return either a single event, or an array
    # of events. This is how the spec goes. :/ Normalize the output
    # here so that we could sanitize it upstream.
    $ev = 'ARRAY' eq ref($ev) ? $ev : [ $ev ];

    delete $_->{type} for @$ev;

    return $ev;
}

### PRIVATE INSTANCE METHOD ###
#
# Decode Ext.Direct response body
#

sub _decode_response_body {
    my ($self, $body) = @_;

    my $json_text = $body;

    # Form POSTs require this additional handling
    my $re = qr{^<html><body><textarea>(.*)</textarea></body></html>$}msi;

    if ( $body =~ $re ) {
        $json_text = $1;
        $json_text =~ s{\\"}{"}g;
    };

    return JSON->new->utf8(1)->decode($json_text);
}

### PRIVATE INSTANCE METHOD ###
#
# Parse cookies if provided, creating Cookie header
#

sub _parse_cookies {
    my ($self, $to, $from) = @_;

    my $cookie_jar = $from->{cookies};

    return unless $cookie_jar;

    my $cookies;

    if ( 'HTTP::Cookies' eq ref $cookie_jar ) {
        $cookies = $self->_parse_http_cookies($cookie_jar);
    }
    else {
        $cookies = $self->_parse_raw_cookies($cookie_jar);
    }

    $to->{headers}->{Cookie} = $cookies if $cookies;
}

### PRIVATE INSTANCE METHOD ###
#
# Parse cookies from HTTP::Cookies object
#

sub _parse_http_cookies {
    my ($self, $cookie_jar) = @_;

    my @cookies;

    $cookie_jar->scan(sub {
        my ($v, $key, $value) = @_;

        push @cookies, "$key=$value";
    });

    return \@cookies;
}

### PRIVATE INSTANCE METHOD ###
#
# Parse (or rather, normalize) cookies passed as a hashref
#

sub _parse_raw_cookies {
    my ($self, $cookie_jar) = @_;

    return [] unless 'HASH' eq ref $cookie_jar;

    return [ map { join '=', $_ => $cookie_jar->{$_} } keys %$cookie_jar ];
}

package
    RPC::ExtDirect::Client::Transaction;

my @fields = qw/ action method arg upload cookies metadata /;

sub new {
    my ($class, %params) = @_;
    
    my %self_params = map { $_ => delete $params{$_} } @fields;
    
    return bless {
        http_params => { %params },
        %self_params,
    }, $class;
}

sub start  {}
sub finish {}

RPC::ExtDirect::Util::Accessor->mk_accessors(
    simple => ['http_params', @fields],
);

1;
