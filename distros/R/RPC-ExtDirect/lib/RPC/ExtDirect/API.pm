package RPC::ExtDirect::API;

use strict;
use warnings;
no  warnings 'uninitialized';           ## no critic

use Carp;

use RPC::ExtDirect::Config;
use RPC::ExtDirect::Serializer;
use RPC::ExtDirect::Util::Accessor;

### PACKAGE GLOBAL VARIABLE ###
#
# Turn this on for debugging
#
# DEPRECATED. Use `debug_api` or `debug` Config options instead.
#

our $DEBUG;

### PUBLIC PACKAGE SUBROUTINE ###
#
# Does not import anything to caller namespace but accepts
# configuration parameters. This method always operates on
# the "default" API object stored in RPC::ExtDirect
#

sub import {
    my ($class, @args) = @_;

    # Nothing to do
    return unless @args;

    # Only hash-like arguments are supported
    croak 'Odd number of arguments in RPC::ExtDirect::API::import()'
        unless (@args % 2) == 0;

    my %arg = @args;
       %arg = map { lc $_ => delete $arg{ $_ } } keys %arg;
    
    # In most cases that's a formality since RPC::ExtDirect
    # should be already required elsewhere; some test scripts
    # may not load it on purpose so we guard against that
    # just in case. We don't want to `use` RPC::ExtDirect above,
    # because that would create a circular dependency.
    require RPC::ExtDirect;

    my $api = RPC::ExtDirect->get_api;
    
    for my $type ( $class->HOOK_TYPES ) {
        my $code = delete $arg{ $type };
        
        $api->add_hook( type => $type, code => $code )
            if $code;
    };
    
    my $api_config = $api->config;
    
    for my $option ( keys %arg ) {
        my $value = $arg{$option};
        
        $api_config->$option($value);
    }
}

### PUBLIC CLASS METHOD (ACCESSOR) ###
#
# Return the hook types supported by the API
#

sub HOOK_TYPES { qw/ before instead after/ }

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Init a new API object
#

sub new {
    my $class = shift;
    
    my %arg = @_ == 1 && 'HASH' eq ref($_[0]) ? %{ $_[0] } : @_;
    
    $arg{config} ||= RPC::ExtDirect::Config->new();
    
    return bless {
        %arg,
        actions => {},
    }, $class;
}

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Init a new API object and populate it from the supplied hashref
#

sub new_from_hashref {
    my ($class, %arg) = @_;
    
    my $api_href = delete $arg{api_href};
    
    my $self = $class->new(%arg);
    
    $self->init_from_hashref($api_href);
    
    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Initialize the API from a hashref
#

sub init_from_hashref {
    my ($self, $api_href) = @_;
    
    # Global hooks go first
    for my $type ( $self->HOOK_TYPES ) {
        $self->add_hook( type => $type, code => delete $api_href->{$type} )
            if exists $api_href->{$type};
    }
    
    for my $key ( keys %$api_href ) {
        my $action_def  = $api_href->{ $key };
        my $remote      = $action_def->{remote};
        my $package     = $remote ? undef : $key;
        my $action_name = $remote ? $key  : $action_def->{action};
        
        my $action = $self->add_action(
            action       => $action_name,
            package      => $package,
            no_overwrite => 1,
        );
        
        for my $hook_type ( $remote ? () : $self->HOOK_TYPES ) {
            my $hook_code = $action_def->{$hook_type};
            
            if ( $hook_code ) {
                $self->add_hook(
                    package => $package,
                    type    => $hook_type,
                    code    => $hook_code,
                );
            }
        }
        
        my $methods = $action_def->{methods};
        
        for my $method_name ( keys %$methods ) {
            my $method_def = $methods->{ $method_name };
            
            $self->add_method(
                action  => $action_name,
                package => $package,
                method  => $method_name,
                %$method_def
            );
        }
    }
}

### PUBLIC INSTANCE METHOD ###
#
# Returns the JavaScript chunk for REMOTING_API
#

sub get_remoting_api {
    my ($class, %arg) = @_;
    
    my ($self, $config);
    
    # There is an option to pass config externally; mainly for testing
    $config = $arg{config};
    
    # Environment object is optional
    my $env = $arg{env};
    
    # Backwards compatibility: if called as a class method, operate on
    # the "global" API object instead, and create a new Config instance
    # as well to take care of possibly-modified-since global variables
    if ( ref $class ) {
        $self     = $class;
        $config ||= $self->config;
    }
    else {
        require RPC::ExtDirect;

        $self     = RPC::ExtDirect->get_api();
        $config ||= $self->config->clone();
        
        $config->read_global_vars();
    }
    
    # Get REMOTING_API hashref
    my $remoting_api = $self->_get_remoting_api($config, $env);

    # Get POLLING_API hashref
    my $polling_api  = $self->_get_polling_api($config, $env);

    # Return empty string if we got nothing to declare
    return '' if !$remoting_api && !$polling_api;

    # Shortcuts
    my $remoting_var = $config->remoting_var;
    my $polling_var  = $config->polling_var;
    my $auto_connect = $config->auto_connect;
    my $no_polling   = $config->no_polling;
    my $s_class      = $config->serializer_class_api;
    my $debug_api    = $config->debug_api;
    
    my $serializer = $s_class->new( config => $config );
    
    my $api_json = $serializer->serialize(
        mute_exceptions => 1,
        debug           => $debug_api,
        data            => [$remoting_api],
    );

    # Compile JavaScript for REMOTING_API
    my $js_chunk = "$remoting_var = " . ($api_json || '{}') . ";\n";

    # If auto_connect is on, add client side initialization code
    $js_chunk .= "Ext.direct.Manager.addProvider($remoting_var);\n"
        if $auto_connect;

    # POLLING_API is added only when there's something in it
    if ( $polling_api && !$no_polling ) {
        $api_json = $serializer->serialize(
            mute_exceptions => 1,
            debug           => $debug_api,
            data            => [$polling_api],
        );
        
        $js_chunk .= "$polling_var = " . ($api_json || '{}' ) . ";\n";

        # Same initialization code for POLLING_API if auto connect is on
        $js_chunk .= "Ext.direct.Manager.addProvider($polling_var);\n"
            if $auto_connect;
    };

    return $js_chunk;
}

### PUBLIC INSTANCE METHOD ###
#
# Get the list of all defined Actions' names
#

sub actions { keys %{ $_[0]->{actions} } }

### PUBLIC INSTANCE METHOD ###
#
# Add an Action (class), or update if it exists
#

sub add_action {
    my ($self, %arg) = @_;
    
    $arg{action} = $self->_get_action_name( $arg{package} )
        unless defined $arg{action};
    
    my $action_name = $arg{action};
    
    return $self->{actions}->{ $action_name }
        if $arg{no_overwrite} && exists $self->{actions}->{ $action_name };
    
    my $config  = $self->config;
    my $a_class = $config->api_action_class();
    
    # This is to avoid hard binding on the Action class
    eval "require $a_class";
    
    my $action_obj = $a_class->new(
        config => $config,
        %arg,
    );
    
    $self->{actions}->{ $action_name } = $action_obj;
    
    return $action_obj;
}

### PUBLIC INSTANCE METHOD ###
#
# Return Action object by its name
#

sub get_action_by_name {
    my ($self, $action_name) = @_;
    
    return $self->{actions}->{ $action_name };
}

### PUBLIC INSTANCE METHOD ###
#
# Return Action object by package name
#

sub get_action_by_package {
    my ($self, $package) = @_;
    
    for my $action ( values %{ $self->{actions} } ) {
        return $action if $action->package eq $package;
    }
    
    return;
}

### PUBLIC INSTANCE METHOD ###
#
# Add a Method, or update if it exists.
# Also create the Method's Action if it doesn't exist yet
#

sub add_method {
    my ($self, %arg) = @_;
    
    my $package     = delete $arg{package};
    my $action_name = delete $arg{action};
    my $method_name = $arg{method};
    
    # Try to find the Action by the package name
    my $action = $action_name ? $self->get_action_by_name($action_name)
               :                $self->get_action_by_package($package)
               ;
    
    # If Action is not found, create a new one
    if ( !$action ) {
        $action_name = $self->_get_action_name($package)
            unless $action_name;
            
        $action = $self->add_action(
            action  => $action_name,
            package => $package,
        );
    }
    
    # Usually redefining a Method means a typo or something
    croak "Attempting to redefine Method '$method_name' ".
          ($package ? "in package $package" : "in Action '$action_name'")
          if $action->can($method_name);
    
    $action->add_method(\%arg);
}

### PUBLIC INSTANCE METHOD ###
#
# Return the Method object by Action and Method name
#

sub get_method_by_name {
    my ($self, $action_name, $method_name) = @_;
    
    my $action = $self->get_action_by_name($action_name);
    
    return unless $action;
    
    return $action->method($method_name);
}

### PUBLIC INSTANCE METHOD ###
#
# Add a hook instance
#

sub add_hook {
    my ($self, %arg) = @_;
    
    my $package     = $arg{package};
    my $action_name = $arg{action};
    my $method_name = $arg{method};
    my $type        = $arg{type};
    my $code        = $arg{code};
    
    my $hook_class = $self->config->api_hook_class;
    
    # This is to avoid hard binding on RPC::ExtDirect::API::Hook
    { local $@; eval "require $hook_class"; }
    
    my $hook = $hook_class->new( type => $type, code => $code );
    
    if ( $package || $action_name ) {
        my $action;
        
        if ( $package ) {
            $action = $self->get_action_by_package($package);
            
            croak "Can't find the Action for package '$package'"
                unless $action;
        }
        else {
            $action = $self->get_action_by_name($action_name);
            
            croak "Can't find the '$action_name' Action"
                unless $action;
        }
        
        if ( $method_name ) {
            my $method = $action->method($method_name);
            
            croak "Can't find Method '$method_name'"
                unless $method;
                
            $method->$type($hook);
        }
        else {
            $action->$type($hook);
        }
    }
    else {
        $self->$type($hook);
    }
    
    return $hook;
}

### PUBLIC INSTANCE METHOD ###
#
# Return the hook object by Method name, Action or package, and type
#

sub get_hook {
    my ($self, %arg) = @_;
    
    my           ($action_name, $package, $method_name, $type)
        = @arg{qw/ action        package   method        type/};
    
    my $action = $action_name ? $self->get_action_by_name($action_name)
               :                $self->get_action_by_package($package)
               ;
    
    croak "Can't find action '", ($action_name || $package), 
          "' for Method $method_name"
        unless $action;
    
    my $method = $action->method($method_name);
    
    my $hook = $method->$type || $action->$type || $self->$type;
    
    return $hook;
}

### PUBLIC INSTANCE METHOD ###
#
# Return the list of all installed poll handlers
#

sub get_poll_handlers {
    my ($self) = @_;
    
    my @handlers;
    
    ACTION:
    for my $action ( values %{ $self->{actions} } ) {
        my @methods = map { $action->method($_) }
                          $action->polling_methods();
        
        push @handlers, @methods;
    }
    
    return @handlers;
}

### PUBLIC INSTANCE METHODS ###
#
# Simple read-write accessors
#

my $accessors = [qw/
    config
/,
    __PACKAGE__->HOOK_TYPES,
];

RPC::ExtDirect::Util::Accessor::mk_accessors(
    simple => $accessors,
);

############## PRIVATE METHODS BELOW ##############

### PRIVATE CLASS METHOD ###
#
# Prepare REMOTING_API hashref
#

sub _get_remoting_api {
    my ($self, $config, $env) = @_;

    my %api;
    
    my %actions = %{ $self->{actions} };
    
    ACTION:
    foreach my $name (keys %actions) {
        my $action = $actions{$name};

        # Get the list of methods for Action
        my @methods = $action->remoting_api($env);

        next ACTION unless @methods;
        
        $api{ $name } = [ @methods ];
    };

    # Compile hashref
    my $remoting_api = {
        url     => $config->router_path,
        type    => 'remoting',
        actions => { %api },
    };

    # Add timeout if it's defined
    $remoting_api->{timeout} = $config->timeout
        if $config->timeout;

    # Add maxRetries if it's defined
    $remoting_api->{maxRetries} = $config->max_retries
        if $config->max_retries;

    # Add namespace if it's defined
    $remoting_api->{namespace} = $config->namespace
        if $config->namespace;

    return $remoting_api;
}

### PRIVATE CLASS METHOD ###
#
# Returns POLLING_API definition hashref
#

sub _get_polling_api {
    my ($self, $config, $env) = @_;
    
    # Check if we have any poll handlers in our definitions
    my $has_poll_handlers;
    
    my %actions = %{ $self->{actions} };
    
    ACTION:
    foreach my $name (keys %actions) {
        my $action = $actions{$name};
        $has_poll_handlers = $action->has_pollHandlers($env);

        last ACTION if $has_poll_handlers;
    };

    # No sense in setting up polling if there ain't no Event providers
    return undef unless $has_poll_handlers;         ## no critic
    
    # Got poll handlers, return definition hashref
    return {
        type => 'polling',
        url  => $config->poll_path,
    };
}

### PRIVATE INSTANCE METHOD ###
#
# Make an Action name from a package name (strip namespace)
#

sub _get_action_name {
    my ($self, $action_name) = @_;
    
    if ( $self->config->api_full_action_names ) {
        $action_name =~ s/::/./g;
    }
    else {
        $action_name =~ s/^.*:://;
    }
    
    return $action_name;
}

1;
