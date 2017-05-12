package RPC::ExtDirect::Request;

use strict;
use warnings;
no  warnings 'uninitialized';           ## no critic

use Carp;

use RPC::ExtDirect::Config;
use RPC::ExtDirect::Util::Accessor;
use RPC::ExtDirect::Util qw/ clean_error_message /;

### PACKAGE GLOBAL VARIABLE ###
#
# Turn on for debugging
#
# DEPRECATED. Use `debug_request` or `debug` Config options instead.
#

our $DEBUG;

### PACKAGE GLOBAL VARIABLE ###
#
# Set Exception class name so it could be configured
#
# DEPRECATED. Use `exception_class_request` or
# `exception_class` Config options instead.
#

our $EXCEPTION_CLASS;

### PUBLIC CLASS METHOD (ACCESSOR) ###
#
# Return the list of supported hook types
#

sub HOOK_TYPES { qw/ before instead after / }

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Initializes new instance of RPC::ExtDirect::Request
#

sub new {
    my ($class, $arg) = @_;
    
    my $api    = delete $arg->{api}    || RPC::ExtDirect->get_api();
    my $config = delete $arg->{config} || RPC::ExtDirect::Config->new();
    
    my $debug = exists $arg->{debug} ? !!(delete $arg->{debug})
              :                        $config->debug_request
              ;

    # Need blessed object to call private methods
    my $self = bless {
        api    => $api,
        config => $config,
        debug  => $debug,
    }, $class;

    # Unpack and validate arguments
    my ($action_name, $method_name, $tid, $data, $type, $upload, $meta, $aux)
        = eval { $self->_unpack_arguments($arg) };
    
    return $self->_exception({
        action  => $action_name,
        method  => $method_name,
        tid     => $tid,
        message => $@->[0],
    }) if $@;

    # Look up the Method
    my $method_ref = $api->get_method_by_name($action_name, $method_name);
    
    return $self->_exception({
        action  => $action_name,
        method  => $method_name,
        tid     => $tid,
        message => 'ExtDirect action or method not found'
    }) unless $method_ref;

    # Check if arguments passed in $data are of right kind
    my $exception = $self->check_arguments(
        action_name => $action_name,
        method_name => $method_name,
        method_ref  => $method_ref,
        tid         => $tid,
        data        => $data,
        metadata    => $meta,
    );
    
    return $exception if defined $exception;
    
    # Bulk assignment for brevity
    @$self{ qw/ tid type data metadata upload method_ref run_count aux / }
        = ($tid, $type, $data, $meta, $upload, $method_ref, 0, $aux);
    
    # Finally, resolve the hooks; it's easier to do that upfront
    # since it involves API lookup
    for my $hook_type ( $class->HOOK_TYPES ) {
        my $hook = $api->get_hook(
            action => $action_name,
            method => $method_name,
            type   => $hook_type,
        );
        
        $self->$hook_type($hook) if $hook;
    }

    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Checks if method arguments are in order
#

my @checkers = qw/ check_method_arguments check_method_metadata /;

my %checker_property = (
    check_method_arguments => 'data',
    check_method_metadata  => 'metadata',
);

sub check_arguments {
    my ($self, %arg) = @_;
    
    my $action_name = $arg{action_name};
    my $method_name = $arg{method_name};
    my $method_ref  = $arg{method_ref};
    my $tid         = $arg{tid};

    # Event poll handlers return Event objects instead of plain data;
    # there is no sense in calling them directly
    if ( $method_ref->pollHandler ) {
        return $self->_exception({
            action  => $action_name,
            method  => $method_name,
            tid     => $tid,
            message => "ExtDirect pollHandler method ".
                       "$action_name.$method_name should not ".
                       "be called directly"
        });
    }

    else {
        # One extra check for formHandlers
        if ( $method_ref->formHandler ) {
            my $data = $arg{data};
            
            if ( 'HASH' ne ref($data) || !exists $data->{extAction} ||
                 !exists $data->{extMethod} )
            {
                return $self->_exception({
                    action  => $action_name,
                    method  => $method_name,
                    tid     => $tid,
                    message => "ExtDirect formHandler method ".
                               "$action_name.$method_name should only ".
                               "be called with form submits"
                })
            }
        }
        
        # The actual heavy lifting happens in the Method itself
        for my $checker ( @checkers ) {
            my $what = $checker_property{ $checker };
            my $have = $arg{ $what };
            
            local $@;
            
            eval { $method_ref->$checker($have) };
            
            if ( my $error = $@ ) {
                $error =~ s/\n$//;
            
                return $self->_exception({
                    action  => $action_name,
                    method  => $method_name,
                    tid     => $tid,
                    message => $error,
                    where   => ref($method_ref) ."->${checker}",
                });
            }
        }
    }

    # undef means no exception
    return undef;               ## no critic
}

### PUBLIC INSTANCE METHOD ###
#
# Runs the request; returns false value if method died on us,
# true otherwise
#

sub run {
    my ($self, $env) = @_;

    # Ensure run() is not called twice
    return $self->_set_error("ExtDirect request can't run more than once per batch")
            if $self->run_count > 0;
    
    # Set the flag
    $self->run_count(1);
    
    my $method_ref = $self->method_ref;

    # Prepare the arguments
    my @method_arg = $method_ref->prepare_method_arguments(
        env      => $env,
        input    => $self->{data},
        upload   => $self->upload,
        metadata => $self->metadata,
    );
    
    my %params = (
        api        => $self->api,
        method_ref => $method_ref,
        env        => $env,
        arg        => \@method_arg,
        metadata   => $self->metadata,
        aux_data   => $self->aux,
    );

    my ($run_method, $callee, $result, $exception) = (1);

    # Run "before" hook if we got one
    ($result, $exception, $run_method) = $self->_run_before_hook(%params)
        if $self->before && $self->before->runnable;

    # If there is "instead" hook, call it instead of the method
    ($result, $exception, $callee) = $self->_run_method(%params)
        if $run_method;

    # Finally, run "after" hook if we got one
    $self->_run_after_hook(
        %params,
        result    => $result,
        exception => $exception,
        callee    => $callee
    ) if $self->after && $self->after->runnable;

    # Fail gracefully if method call was unsuccessful
    return $self->_process_exception($env, $exception)
        if $exception;

    # Else stash the results
    $self->{result} = $result;

    return 1;
}

### PUBLIC INSTANCE METHOD ###
#
# If method call was successful, returns result hashref.
# If an error occured, returns exception hashref. It will contain
# error-specific message only if we're debugging. This is somewhat weird
# requirement in ExtDirect specification. If the debug config option
# is not set, the exception hashref will contain generic error message.
#

sub result {
    my ($self) = @_;

    return $self->_get_result_hashref();
}

### PUBLIC INSTANCE METHOD ###
#
# Return the data represented as a list
#

sub data {
    my ($self) = @_;

    return 'HASH'  eq ref $self->{data} ? %{ $self->{data} }
         : 'ARRAY' eq ref $self->{data} ? @{ $self->{data} }
         :                                ()
         ;
}

### PUBLIC INSTANCE METHODS ###
#
# Simple read-write accessors.
#

my $accessors = [qw/
    config
    api
    debug
    method_ref
    type
    tid
    state
    where
    message
    upload
    run_count
    metadata
    aux
/,
    __PACKAGE__->HOOK_TYPES,
];

RPC::ExtDirect::Util::Accessor::mk_accessors(
    simple => $accessors,
);

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Return new Exception object
#

sub _exception {
    my ($self, $arg) = @_;
    
    my $config   = $self->config;
    my $ex_class = $config->exception_class_request;
    
    eval "require $ex_class";
    
    my $where = $arg->{where};

    if ( !$where ) {
        my ($package, $sub)
            = (caller 1)[3] =~ / \A (.*) :: (.*?) \z /xms;
        $arg->{where} = $package . '->' . $sub;
    };
    
    return $ex_class->new({
        config  => $config,
        debug   => $self->debug,
        verbose => $config->verbose_exceptions,
        %$arg
    });
}

### PRIVATE INSTANCE METHOD ###
#
# Replaces Request object with Exception object
#

sub _set_error {
    my ($self, $msg, $where) = @_;

    # Munge $where to avoid it being '_set_error' all the time
    if ( !defined $where ) {
        my ($package, $sub) = (caller 1)[3] =~ / \A (.*) :: (.*?) \z /xms;
        $where = $package . '->' . $sub;
    };
    
    my $method_ref = $self->method_ref;

    # We need newborn Exception object to tear its guts out
    my $ex = $self->_exception({
        action  => $method_ref->action,
        method  => $method_ref->name,
        tid     => $self->tid,
        message => $msg,
        where   => $where,
        debug   => $self->debug,
    });

    # Now the black voodoo magiKC part, live on stage
    delete @$self{ keys %$self };
    @$self{ keys %$ex } = values %$ex;

    # Finally, cover our sins with a blessing and we've been born again!
    bless $self, ref $ex;

    # Humbly return failure to be propagated upwards
    return !1;
}

### PRIVATE INSTANCE METHOD ###
#
# Unpacks arguments into a list and validates them
#

my @std_keys = qw/
    extAction action extMethod method extTID tid data metadata
    extType type extUpload _uploads
/;

sub _unpack_arguments {
    my ($self, $arg) = @_;

    # Unpack and normalize arguments
    my $action = $arg->{extAction} || $arg->{action};
    my $method = $arg->{extMethod} || $arg->{method};
    my $tid    = $arg->{extTID}    || $arg->{tid}; # can't be 0
    my $type   = $arg->{type}      || 'rpc';
    
    # For a formHandler, the "data" field is the form itself;
    # the arguments are fields in the form-encoded POST body
    my $data   = $arg->{data} || $arg;
    my $meta   = $arg->{metadata};
    my $upload = $arg->{extUpload} eq 'true' ? $arg->{_uploads}
               :                               undef
               ;

    # Throwing arrayref so that die() wouldn't add file/line to the string
    die [ "ExtDirect action (class name) required" ]
        unless defined $action && length $action > 0;

    die [ "ExtDirect method name required" ]
        unless defined $method && length $method > 0;

    my %arg_keys = map { $_ => 1, } keys %$arg;
    delete @arg_keys{ @std_keys };

    # Collect ancillary data that might be passed in the packet
    # and make it available to the Hooks. This might be used e.g.
    # for passing CSRF protection tokens, etc.
    my %aux = map { $_ => $arg->{$_} } keys %arg_keys;
    
    my $aux_ref = %aux ? { %aux } : undef;

    return (
        $action, $method, $tid, $data, $type, $upload, $meta, $aux_ref
    );
}

### PRIVATE INSTANCE METHOD ###
#
# Run "before" hook
#

sub _run_before_hook {
    my ($self, %arg) = @_;
    
    my ($run_method, $result, $exception) = (1);
    
    # This hook may die() with an Exception
    local $@;
    my $hook_result = eval { $self->before->run(%arg) };

    # If "before" hook died, cancel Method call
    if ( $@ ) {
        $exception  = $@;
        $run_method = !1;
    };

    # If "before" hook returns anything but number 1,
    # treat it as an Ext.Direct response and do not call
    # the actual method
    if ( $hook_result ne '1' ) {
        $result     = $hook_result;
        $run_method = !1;
    };
    
    return ($result, $exception, $run_method);
}

### PRIVATE INSTANCE METHOD ###
#
# Runs "instead" hook if it exists, or the method itself
#

sub _run_method {
    my ($self, %arg) = @_;
    
    # We call methods by code reference    
    my $hook      = $self->instead;
    my $run_hook  = $hook && $hook->runnable;
    my $callee    = $run_hook ? $hook : $self->method_ref;
    
    local $@;
    my $result    = eval { $callee->run(%arg) };
    my $exception = $@;
    
    return ($result, $exception, $callee->code);
}

### PRIVATE INSTANCE METHOD ###
#
# Run "after" hook
#

sub _run_after_hook {
    my ($self, %arg) = @_;
    
    # Localize so that we don't clobber the $@
    local $@;
    
    # Return value and exceptions are ignored
    eval { $self->after->run(%arg) };
}

### PRIVATE INSTANCE METHOD ###
#
# Return result hashref
#

sub _get_result_hashref {
    my ($self) = @_;
    
    my $method_ref = $self->method_ref;

    my $result_ref = {
        type   => 'rpc',
        tid    => $self->tid,
        action => $method_ref->action,
        method => $method_ref->name,
        result => $self->{result},  # To avoid collisions
    };

    return $result_ref;
}

### PRIVATE INSTANCE METHOD ###
#
# Process exception message returned by die() in method or hooks
#

sub _process_exception {
    my ($self, $env, $exception) = @_;

    # Stringify exception and treat it as error message
    my $msg = clean_error_message("$exception");
    
    # Report actual package and method in case we're debugging
    my $method_ref = $self->method_ref;
    my $where      = $method_ref->package .'->'. $method_ref->name;

    return $self->_set_error($msg, $where);
}

1;
