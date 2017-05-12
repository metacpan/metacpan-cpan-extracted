package RPC::ExtDirect::API::Action;

use strict;
use warnings;
no  warnings 'uninitialized';           ## no critic

use Carp;

use RPC::ExtDirect::Config;
use RPC::ExtDirect::Util::Accessor;

### PUBLIC CLASS METHOD (ACCESSOR) ###
#
# Return the hook types supported by this Action class
#

sub HOOK_TYPES { qw/ before instead after / }

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Create a new Action instance
#

sub new {
    my ($class, %arg) = @_;
    
    my $config     = delete $arg{config};
    my $hook_class = $config->api_hook_class;
    
    # For the caller, the 'action' parameter makes sense as the Action's
    # name, but within the Action itself it's just "name" for clarity
    my $name    = delete $arg{action};
    my $package = delete $arg{package};
    my $methods = delete $arg{methods} || [];
    
    # These checks are mostly for debugging
    croak "Can't create an Action without a name!"
        unless defined $name;
    
    # We accept :: in Action names so that the API would feel
    # more natural on the Perl side, but convert them to dots
    # anyway to be compatible with JavaScript
    $name =~ s/::/./g;
    
    # We avoid hard binding on the hook class
    { local $@; eval "require $hook_class"; }
    
    my %hooks;
    
    for my $type ( $class->HOOK_TYPES ) {
        my $hook = delete $arg{ $type };
        
        $hooks{ $type } = $hook_class->new( type => $type, code => $hook )
            if $hook;
    }
        
    my $self = bless {
        config  => $config,
        name    => $name,
        package => $package,
        methods => {},
        %arg,
        %hooks,
    }, $class;
    
    $self->add_method($_) for @$methods;
    
    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Merge method definitions from incoming Action object
#

sub merge {
    my ($self, $action) = @_;
    
    # Add the methods, or replace if they exist
    $self->add_method(@_) for $action->methods();
    
    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Return the list of this Action's Methods' names
#

sub methods { keys %{ $_[0]->{methods} } }

### PUBLIC INSTANCE METHOD ###
#
# Return the list of this Action's publishable
# (non-pollHandler) methods
#

sub remoting_methods {
    my ($self) = @_;
    
    my @method_names = map  {   $_->[0]                 }
                       grep {  !$_->[1]->pollHandler    }
                       map  { [ $_, $self->method($_) ] }
                            $self->methods;
    
    return @method_names;
}

### PUBLIC INSTANCE METHOD ###
#
# Return the list of this Action's pollHandler methods
#

sub polling_methods {
    my ($self) = @_;
    
    my @method_names = map  {   $_->[0]                 }
                       grep {   $_->[1]->pollHandler    }
                       map  { [ $_, $self->method($_) ] }
                            $self->methods;
    
    return @method_names;
}

### PUBLIC INSTANCE METHOD ###
#
# Return the list of API definitions for this Action's
# remoting methods
#

sub remoting_api {
    my ($self, $env) = @_;
    
    # Guard against user overrides returning undefs instead of
    # empty lists
    my @method_names = $self->remoting_methods;
    my @method_defs;
    
    for my $method_name ( @method_names ) {
        my $method = $self->method($method_name);
        my $def    = $method->get_api_definition($env);
        
        push @method_defs, $def if $def;
    }
    
    return @method_defs;
}

### PUBLIC INSTANCE METHOD ###
#
# Return true if this Action has any pollHandler methods
#

sub has_pollHandlers {
    my ($self, $env) = @_;
    
    # By default we're not using the env object here,
    # but an user override may do so
    
    my @methods = $self->polling_methods;
    
    return !!@methods;
}

### PUBLIC INSTANCE METHOD ###
#
# Add a method, or replace it if exists.
# Accepts Method instances, or hashrefs to be fed
# to Method->new()
#

sub add_method {
    my ($self, $method) = @_;
    
    my $config = $self->config;
    
    if ( 'HASH' eq ref $method ) {
        my $m_class = $config->api_method_class();
        
        # This is to avoid hard binding on RPC::ExtDirect::API::Method
        eval "require $m_class";
        
        my $name = delete $method->{method} || delete $method->{name};
        
        $method = $m_class->new(
            config  => $config,
            package => $self->package,
            action  => $self->name,
            name    => $name,
            %$method,
        );
    }
    else {
        $method->config($config);
    }
    
    my $m_name = $method->name;
    
    $self->{methods}->{ $m_name } = $method;
    
    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Returns a Method object by name
#

sub method {
    my ($self, $method_name) = @_;

    return $self->{methods}->{ $method_name };
}

### PUBLIC INSTANCE METHODS ###
#
# Simple read-write accessors
#

my $accessors = [qw/
    config
    name
    package
/,
    __PACKAGE__->HOOK_TYPES,
];

RPC::ExtDirect::Util::Accessor::mk_accessors(
    simple => $accessors,
);

1;
