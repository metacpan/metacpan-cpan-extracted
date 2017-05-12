package RPC::ExtDirect::API::Hook;

use strict;
use warnings;
no  warnings 'uninitialized';           ## no critic

use B;

use RPC::ExtDirect::Util::Accessor;

### PUBLIC CLASS METHOD (ACCESSOR) ###
#
# Return the list of supported hook types
#

sub HOOK_TYPES { qw/ before instead after / }

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Instantiate a new Hook object
#

sub new {
    my ($class, %arg) = @_;
    
    my ($type, $coderef) = @arg{qw/ type code /};
    
    # If we're passed an undef or 'NONE' instead of a coderef,
    # then the hook is not runnable. Otherwise, try resolving
    # package if we have a coderef.
    my $runnable = !('NONE' eq $coderef || !defined $coderef);
    
    my ($package, $sub_name);
    
    if ( 'CODE' eq ref $coderef ) {
        $package = _package_from_coderef($coderef);
    }
    else {
        my @parts = split /::/, $coderef;
        
        $sub_name = pop @parts;
        $package  = join '::', @parts;
        
        # We've got to have at least the sub_name part
        die "Can't resolve '$type' hook $coderef" unless $sub_name;
    }
    
    my $self = bless {
        package  => $package,
        type     => $type,
        code     => $coderef,
        sub_name => $sub_name,
        runnable => $runnable,
    }, $class;
    
    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Run the hook
#

sub run {
    my ($self, %args) = @_;
    
    my $method_ref  = $args{method_ref};
    my $action_name = $method_ref->action;
    my $method_name = $method_ref->name;
    my $method_pkg  = $method_ref->package;
    
    my %hook_arg = $method_ref->get_api_definition_compat();
    
    $hook_arg{method_ref} = $method_ref;
    $hook_arg{code}       = $method_ref->code;

    @hook_arg{qw/arg env metadata aux_data/}
      = @args{qw/arg env metadata aux_data/};

    # Result and exception are passed to "after" hook only
    if ( $self->type eq 'after' ) {
        @hook_arg{ qw/result exception method_called/ }
          = @args{ qw/result exception callee/ }
    }

    for my $type ( $self->HOOK_TYPES ) {
        my $hook = $args{api}->get_hook(
            action => $action_name,
            method => $method_name,
            type   => $type,
        );
        
        $hook_arg{ $type.'_ref' } = $hook;
        $hook_arg{ $type }        = $hook ? $hook->code : undef;
    }
    
    my $arg = $args{arg};

    # A drop of sugar
    $hook_arg{orig} = sub { $method_pkg->$method_name(@$arg) };

    my $hook_coderef  = $self->code;
    my $hook_sub_name = $self->sub_name;
    my $hook_pkg      = $self->package;

    # By convention, hooks are called as class methods. If we were passed
    # a method name instead of a coderef, call it indirectly on the package
    # so that inheritance works properly
    return $hook_pkg && $hook_sub_name ? $hook_pkg->$hook_sub_name(%hook_arg)
         :                               $hook_coderef->($hook_pkg, %hook_arg)
         ;
}

### PUBLIC INSTANCE METHODS ###
#
# Simple read-write accessors
#

RPC::ExtDirect::Util::Accessor::mk_accessors(
    simple => [qw/ type code package sub_name runnable /],
);

############## PRIVATE METHODS BELOW ##############

### PRIVATE PACKAGE SUBROUTINE ###
#
# Return package name from coderef
#

sub _package_from_coderef {
    my ($code) = @_;

    my $pkg = eval { B::svref_2object($code)->GV->STASH->NAME };

    return defined $pkg && $pkg ne '' ? $pkg : undef;
}

1;
