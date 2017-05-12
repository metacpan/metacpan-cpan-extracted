package Sash::Plugin::Factory;
use strict;
use warnings;

use Carp;

my $_registry;
my $_using_plugin;

sub _load_registry {
    my $class = shift;
    
    # Find out where the registry has been installed.
    my $base = ( grep { -d "$_/Sash/Plugin/registry" } @INC )[0];

    foreach ( <$base/Sash/Plugin/registry/*.pl*> ) {
        do "$_";
        croak $@ if $@;
    }

}

sub set_registry_item {
    my $class = shift;
    my $key = shift;
    my $value = shift;
    
    croak __PACKAGE__ . '->set_registry_item requires both key and value'
        unless defined $key && defined $value;

    $_registry->{$key} = $value;

    return;
}

sub get_registry_item {
    my $class = shift;
    my $key = shift;
    
    croak __PACKAGE__ . '->get_registry_item requires a key to lookup' unless defined $key;

    return $_registry->{$key};
}

sub get_registry_hash {
    my $class = shift;

    return $_registry;
}

sub get_plugin {
    my $class = shift;
    return $_using_plugin;
}

sub get_plugin_command_class {
    my $class = shift;
    return "${_using_plugin}::Command";
}

sub get_plugin_command_hash {
    my $class = shift;

    my $plugin_class = $class->get_plugin;
    my $command_class = "${plugin_class}::Command";

    return sort keys %{$command_class->get_command_hash};
}

# This is a pass through method to the concrete implementation.
sub get_class {
    my $class = shift;
    my $args = shift; #hashref

    croak __PACKAGE__ . '->get_instance: Invalid Arguments - missing hash ref' unless ref $args eq 'HASH';
    croak __PACKAGE__ . '->get_instance: Invalid Arguments - undefined endpoint or vendor'
        unless defined $args->{endpoint} || defined $args->{vendor};

    $class->_load_registry;

    my $key = ( $args->{endpoint} ) ? $args->{endpoint} : $args->{vendor};
    my $plugin_class = $class->get_registry_item( $key );

    croak __PACKAGE__ . "->get_class: Plugin class identified by $key not found." unless $plugin_class;

    eval "use $plugin_class;";
    croak $@ if $@;
    
    $plugin_class->enable( $args );

    # Keep track of which plugin we are using
    $_using_plugin = $plugin_class;

    return $plugin_class;
}

1;
