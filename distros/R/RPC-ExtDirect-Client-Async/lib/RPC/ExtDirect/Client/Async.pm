package RPC::ExtDirect::Client::Async;

use strict;
use warnings;

use Carp;
use File::Spec;
use AnyEvent::HTTP;

use RPC::ExtDirect::Util::Accessor;
use RPC::ExtDirect::Config;
use RPC::ExtDirect::API;
use RPC::ExtDirect;
use RPC::ExtDirect::Client;

use base 'RPC::ExtDirect::Client';

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

### PUBLIC INSTANCE METHOD ###
#
# Call specified Action's Method asynchronously
#

sub call_async { shift->async_request('call', @_) }

### PUBLIC INSTANCE METHOD ###
#
# Submit a form to specified Action's Method asynchronously
#

sub submit_async { shift->async_request('form', @_) }

### PUBLIC INSTANCE METHOD ###
#
# Upload a file using POST form. Same as submit()
#

*upload_async = *submit_async;

### PUBLIC INSTANCE METHOD ###
#
# Poll server for events asynchronously
#

sub poll_async { shift->async_request('poll', @_) }

#
# This is to prevent mistakes leading to hard to find bugs
#

sub call   { croak "Use call_async instead"   }
sub submit { croak "Use submit_async instead" }
sub upload { croak "Use upload_async instead" }
sub poll   { croak "Use poll_async instead"   }

### PUBLIC INSTANCE METHOD ###
#
# Run a specified request type asynchronously
#

sub async_request {
    my $self = shift;
    my $type = shift;
    
    my $tr_class = $self->transaction_class;
    
    # We try to avoid action-at-a-distance here, so we will
    # call all the stuff that could die() up front, to pass
    # the exception on to the caller immediately rather than
    # blowing up later on.
    # The only case when that may happen realistically is
    # when the caller forgot to specify a callback coderef;
    # anything else is passed as an $error to the callback
    # (which is hard to do when it's missing).
    eval {
        my $transaction = $tr_class->new(@_);
        $self->_async_request($type, $transaction);
    };
    
    if ($@) { croak 'ARRAY' eq ref($@) ? $@->[0] : $@ };
    
    # Stay positive
    return 1;
}

### PUBLIC INSTANCE METHOD ###
#
# Return the name of the Transaction class
#

sub transaction_class { 'RPC::ExtDirect::Client::Async::Transaction' }

### PUBLIC INSTANCE METHOD ###
#
# Read-write accessor
#

RPC::ExtDirect::Util::Accessor->mk_accessor(
    simple => [qw/ api_ready exception request_queue /],
);

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Initialize API declaration
#

sub _init_api {
    my ($self, $api) = @_;
    
    # If we're passed a local API instance, init immediately
    # and don't bother with request queue - we won't need it anyway.
    if ($api) {
        my $cv     = $self->cv;
        my $api_cb = $self->api_cb;
        
        $cv->begin if $cv;
        
        $self->_assign_api($api);
        $self->api_ready(1);
        
        $api_cb->($self, 1) if $api_cb;
        
        $cv->end if $cv;
    }
    else {
    
        # We want to be truly asynchronous, so instead of blocking
        # on API retrieval, we create a request queue and return
        # immediately. If any call/form/poll requests happen before
        # we've got the API result back, we push them in the queue
        # and wait for the API to arrive, then re-run the requests.
        # After the API declaration has been retrieved, all subsequent
        # requests run without queuing.
        $self->request_queue([]);

        $self->_get_api(sub {
            my ($success, $api_js, $error) = @_;
        
            if ( $success ) {
                $self->_import_api($api_js);
                $self->api_ready(1);
            }
            else {
                $self->exception($error);
            }
        
            $self->api_cb->($self, $success, $error) if $self->api_cb;
        
            my $queue = $self->request_queue;
            delete $self->{request_queue};  # A bit quirky
    
            $_->($success, $error) for @$queue;
        });
    }
    
    return 1;
}

### PRIVATE INSTANCE METHOD ###
#
# Receive API declaration from the specified server,
# parse it and return a Client::API object
#

sub _get_api {
    my ($self, $cb) = @_;

    # Run additional checks before firing the curried callback
    my $api_cb = sub {
        my ($content, $headers) = @_;

        my $status         = $headers->{Status};
        my $content_length = do { use bytes; length $content; };
        my $success        = $status eq '200' && $content_length > 0;
        my $error;
        
        if ( !$success ) {
            if ( $status ne '200' ) {
                $error = "Can't download API declaration: $status";
            }
            elsif ( !$content_length ) {
                $error = "Empty API declaration received";
            }
        }
        
        my $cv = $self->cv;
        $cv->end if $cv;
        
        $self->{api_guard} = undef;
        
        $cb->($success, $content, $error);
    };
    
    my $cv     = $self->cv;
    my $uri    = $self->_get_uri('api');
    my $params = $self->{http_params};
    
    $cv->begin if $cv;
    
    #
    # Note that we're passing a falsy value to the `persistent` option
    # here; that's because without it, GET requests will generate some
    # weird 596 error code responses for every request after the very
    # first one, if a condvar is used.
    #
    # I can surmise that it has something to do with AnyEvent::HTTP
    # having procedural interface without any clear way to separate
    # requests. Probably something within the (very tangled) bowels
    # of AnyEvent::HTTP::http_request is erroneously confusing condvars;
    # in any case, turning off permanent connections seem to cure that.
    #
    # You can override that by passing `persistent => 1` to the Client
    # constructor, but don't try to do that if you are not ready to
    # spend HOURS untangling the callback hell inside http_request.
    # I was not, hence the "fix".
    #
    # Also store the "cancellation guard" to prevent it being destroyed,
    # which would end the request prematurely.
    #
    $self->{api_guard} = AnyEvent::HTTP::http_request(
        GET        => $uri,
        persistent => !1,
        %$params,
        $api_cb,
    );
    
    return 1;
}

### PRIVATE INSTANCE METHOD ###
#
# Queue asynchronous request(s)
#

sub _queue_request {
    my $self = shift;
    
    my $queue = $self->{request_queue};
    
    push @$queue, @_;
}

### PRIVATE INSTANCE METHOD ###
#
# Make an HTTP request in asynchronous fashion
#

sub _async_request {
    my ($self, $type, $transaction) = @_;
    
    # Transaction should be primed *before* the request has been
    # dispatched. This way we ensure that requests don't get stuck
    # in the queue if something goes wrong (API retrieval fails, etc).
    # Also if we're passed a cv this will prime it enough times so
    # that any blocking later on won't end prematurely before *all*
    # queued requests have had a chance to run.
    $transaction->start;
    
    # The parameters to this sub ($api_success, $api_error) mean
    # success of the API retrieval operation, and an error that caused
    # the failure, if any. This should NOT be confused with success
    # of the HTTP request below.
    my $request_closure = sub {
        my ($api_success, $api_error) = @_;
        
        # If request was queued and API retrieval failed,
        # transaction still has to finish.
        return $transaction->finish(undef, $api_success, $api_error)
            unless $api_success;
        
        my $prepare = "_prepare_${type}_request";
        my $method  = $type eq 'poll' ? 'GET' : 'POST';

        # We can't allow an exception to be thrown - there is no
        # enveloping code to handle it. So we catch it here instead,
        # and pass it to the transaction to be treated as an error.
        # Note that the transaction itself has already been started
        # before the request closure was executed.
        my ($uri, $request_content, $http_params, $request_options)
            = eval { $self->$prepare($transaction) };
    
        if ( my $xcpt = $@ ) {
            my $err = 'ARRAY' eq ref($xcpt) ? $xcpt->[0] : $xcpt;
        
            return $transaction->finish(undef, !1, $err);
        }
        
        my $request_headers = $request_options->{headers};

        # TODO Handle errors
        my $guard = AnyEvent::HTTP::http_request(
            $method, $uri,
            headers    => $request_headers,
            body       => $request_content,
            persistent => !1,
            %$http_params,
            $self->_curry_response_cb($type, $transaction),
        );
        
        $transaction->guard($guard);
        
        return 1;
    };
    
    # If a fatal exception has occured before this point in time
    # (API retrieval failed) run the request closure immediately
    # with an error. This will fall through and finish the
    # transaction, passing the error to the callback subroutine.
    if ( my $fatal_exception = $self->exception ) {
        $request_closure->(!1, $fatal_exception);
    }
    
    # If API is ready, run the request closure immediately with the
    # success flag set to true.
    elsif ( $self->api_ready ) {
        $request_closure->(1);
    }
    
    # If API is not ready, queue the request closure to be ran
    # at a later time, when the result of API retrieval operation
    # will be known.
    else {
        $self->_queue_request($request_closure);
    }
    
    return 1;
}

### PRIVATE INSTANCE METHOD ###
#
# Parse cookies if provided, creating Cookie header
#

sub _parse_cookies {
    my ($self, $to, $from) = @_;
    
    $self->SUPER::_parse_cookies($to, $from);
    
    # This results in Cookie header being a hashref,
    # but we need a string for AnyEvent::HTTP::http_request
    if ( $to->{headers} && (my $cookies = $to->{headers}->{Cookie}) ) {
        $to->{headers}->{Cookie} = join '; ', @$cookies;
    }
}

### PRIVATE INSTANCE METHOD ###
#
# Generate result handling callback
#

sub _curry_response_cb {
    my ($self, $type, $transaction) = @_;
    
    return sub {
        my ($data, $headers) = @_;
        
        my $status  = $headers->{Status};
        my $success = $status eq '200';
        
        # No sense in trying to decode the response if request failed
        return $transaction->finish(undef, !1, $headers->{Reason})
            unless $success;
        
        local $@;
        my $handler  = "_handle_${type}_response";
        my $response = eval {
            $self->$handler({
                status  => $status,
                success => $success,
                content => $data,
            })
        } if $success;
        
        my $error = 'ARRAY' eq ref($@) ? $@->[0] : $@;
        
        return $transaction->finish(undef, !1, $error) if $error;
        
        # We're only interested in the data, unless it was a poll.
        my $result = 'poll' eq $type          ? $response
                   : 'HASH' eq ref($response) ? $response->{result}
                   :                            $response
                   ;
        
        return $transaction->finish($result, $success);
    };
}

package
    RPC::ExtDirect::Client::Async::Transaction;

use base 'RPC::ExtDirect::Client::Transaction';

my @fields = qw/ cb cv actual_arg fields /;

sub new {
    my ($class, %params) = @_;
    
    my $cb = $params{cb};
    
    die ["Callback subroutine is required"]
        if 'CODE' ne ref $cb && !($cb && $cb->isa('AnyEvent::CondVar'));
    
    my %self_params = map { $_ => delete $params{$_} } @fields;
    
    my $self = $class->SUPER::new(%params);
    
    @$self{ keys %self_params } = values %self_params;
    
    return $self;
}

sub start {
    my ($self) = @_;
    
    my $cv = $self->cv;
    
    $cv->begin if $cv;
}

sub finish {
    my ($self, $result, $success, $error) = @_;
    
    my $cb = $self->cb;
    my $cv = $self->cv;
    
    $cb->($result, $success, $error) if $cb;
    $cv->end                         if $cv;
    
    return $success;
}

RPC::ExtDirect::Util::Accessor->mk_accessors(
    simple => [qw/ cb cv guard /],
);

1;
