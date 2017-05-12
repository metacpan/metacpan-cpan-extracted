package RPC::ExtDirect;

use strict;
use warnings;
no  warnings 'uninitialized';       ## no critic

use Carp;
use Attribute::Handlers;

use RPC::ExtDirect::API;
use RPC::ExtDirect::Util;

### PACKAGE VARIABLE ###
#
# Version of this module. This should be kept as a string
# because otherwise 'make dist' strips "insignificant" digits
# at the end.
#

our $VERSION = '3.24';

### PACKAGE GLOBAL VARIABLE ###
#
# Debugging; defaults to off.
#
# DEPRECATED. Use `debug` Config option instead.
#

our $DEBUG;

# This is a bit hacky, but we've got to keep a reference to the API object
# so that *compilation time* attributes would work as expected,
# as well as the configuration options for the RPC::ExtDirect::API class.
{
    my $api = RPC::ExtDirect::API->new();
    
    ### PUBLIC CLASS METHOD ###
    #
    # Return the global API instance
    #
    
    sub get_api { $api }
}


### PUBLIC PACKAGE SUBROUTINE ###
#
# Provides a facility to assign package-level (action) properties.
# Despite its name, does not import anything to the caller package's
# namespace.
#

sub import {
    my ($class, @args) = @_;

    # Nothing to do
    return unless @args;

    # Only hash-like arguments are supported
    croak "Odd number of arguments in RPC::ExtDirect::import()"
        unless (@args % 2) == 0;

    my %arg = @args;
       %arg = map { lc $_ => delete $arg{ $_ } } keys %arg;

    my ($package, $filename, $line) = caller();
    
    my $api = $class->get_api;

    # Store Action (class) name as an alias for a package
    my $action_name = defined $arg{action} ? $arg{action}
                    : defined $arg{class}  ? $arg{class}
                    :                        undef
                    ;
    
    # We don't want to overwrite the existing Action, if any
    $api->add_action(
        package      => $package,
        action       => $action_name,
        no_overwrite => 1,
    );

    # Store package level hooks
    for my $type ( $api->HOOK_TYPES ) {
        my $code = $arg{ $type };

        $api->add_hook( package => $package, type => $type, code => $code )
            if defined $code;
    };
}

### PUBLIC ATTRIBUTE DEFINITION ###
#
# Define ExtDirect attribute subroutine and export it into UNIVERSAL
# namespace. Attribute processing phase depends on the perl version
# we're running under.
#

{
    my $phase = $] >= 5.012 ? 'BEGIN' : 'CHECK';
    my $pkg   = __PACKAGE__;
    
    eval <<END;
    sub UNIVERSAL::ExtDirect : ATTR(CODE,$phase) {
        my \$attr = RPC::ExtDirect::Util::parse_attribute(\@_);
        
        eval { ${pkg}->add_method(\$attr) };

        if (\$@) { die 'ARRAY' eq ref(\$@) ? \$\@->[0] : \$@ }; };
END
}

### PUBLIC CLASS METHOD ###
#
# Add a hook to the global API
#
# DEPRECATED. See RPC::ExtDirect::API for replacement.
#

sub add_hook {
    my ($class, %arg) = @_;

    my $api = $class->get_api();
    
    $api->add_hook(%arg);

    return $arg{code};
}

### PUBLIC CLASS METHOD ###
#
# Return hook coderef by package and method, with hierarchical lookup.
#
# DEPRECATED. See RPC::ExtDirect::API for replacement.
#

sub get_hook {
    my ($class, %arg) = @_;

    my $api  = $class->get_api();
    my $hook = $api->get_hook(%arg);
    
    return $hook ? $hook->code : undef;
}

### PUBLIC CLASS METHOD ###
#
# Adds Action name as an alias for a package
#
# DEPRECATED. See RPC::ExtDirect::API for replacement.
#

sub add_action {
    my ($class, $package, $action_for_pkg) = @_;
    
    my $api = $class->get_api();
    
    return $api->add_action(
        package => $package,
        action  => $action_for_pkg,
    );
}

### PUBLIC CLASS METHOD ###
#
# Returns the list of Actions that have ExtDirect methods
#
# DEPRECATED. See RPC::ExtDirect::API for replacement.
#

sub get_action_list {
    my ($class) = @_;
    
    my $api = $class->get_api();
    
    my @actions = sort $api->actions();
    
    return @actions;
}

### PUBLIC CLASS METHOD ###
#
# Returns the list of poll handler methods as list of
# arrayrefs: [ $action, $method ]
#
# DEPRECATED. See RPC::ExtDirect::API for replacement.
#

sub get_poll_handlers {
    my ($class) = @_;
    
    my $api     = $class->get_api();
    my @actions = $class->get_api->actions;
    my @handlers;
    
    for my $name ( @actions ) {
        my $action  = $api->get_action_by_name($name);
        my @methods = $action->polling_methods;
        
        push @handlers, [ $name, $_ ] for @methods;
    }
    
    return @handlers;
}

### PUBLIC CLASS METHOD ###
#
# Adds a method to the global API
#
# DEPRECATED. See RPC::ExtDirect::API for replacement.
#

sub add_method {
    my ($class, $attribute_ref) = @_;
    
    my $api = $class->get_api;
    
    return $api->add_method( %$attribute_ref );
}

### PUBLIC CLASS METHOD ###
#
# Returns the list of method names with ExtDirect attribute
# for $action_name, or all methods for all actions if $action_name
# is empty
#
# DEPRECATED. See RPC::ExtDirect::API for replacement.
#

sub get_method_list {
    my ($class, $action_name) = @_;
    
    my $api = $class->get_api;
    
    my @actions = $action_name ? ( $action_name ) : $api->actions;
    my @list;
    
    for my $name ( @actions ) {
        my $action = $api->get_action_by_name($name);
        
        # The output of this method is inconsistent:
        # when called with $action_name it returns the list of
        # method names; when it is called with empty @_
        # it returns the list of Action::method pairs.
        # I don't remember  what was the original intent here but
        # we've got to keep up compatibility. The whole method is
        # deprecated anyway...
        my $tpl = $action_name ? "" : $name.'::';
        
        push @list, map { $tpl.$_ } $action->methods;
    }
    
    return wantarray ? @list : shift @list;
}

### PUBLIC CLASS METHOD ###
#
# Returns parameters for given action and method name
# with ExtDirect attribute.
#
# Returns full attribute hash in list context.
# Croaks if called in scalar context.
#
# DEPRECATED. See RPC::ExtDirect::API for replacement.
#

sub get_method_parameters {
    my ($class, $action_name, $method_name) = @_;
    
    croak "Wrong context" unless wantarray;
    
    croak "ExtDirect action name is required" unless defined $action_name;
    croak "ExtDirect method name is required" unless defined $method_name;
    
    my $action = $class->get_api->get_action_by_name($action_name);
    
    croak "Can't find ExtDirect action $action"
        unless $action;
    
    my $method = $action->method($method_name);

    croak "Can't find ExtDirect properties for method $method_name"
        unless $method;
    
    return $method->get_api_definition_compat();
}

1;
