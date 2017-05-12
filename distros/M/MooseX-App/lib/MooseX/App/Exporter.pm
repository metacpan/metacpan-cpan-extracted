# ============================================================================
package MooseX::App::Exporter;
# ============================================================================

use 5.010;
use utf8;
use strict;
use warnings;

use Moose::Exporter;
use MooseX::App::Utils;
use MooseX::App::ParsedArgv;
use List::Util qw(first);

my %PLUGIN_SPEC;

sub import {
    my ( $class, @imports ) = @_;

    my $caller_class = caller();

    my $caller_stash = Package::Stash->new($caller_class);
    my $exporter_stash = Package::Stash->new(__PACKAGE__);

    foreach my $import (@imports) {
        my $symbol = $exporter_stash->get_symbol('&'.$import);
        Carp::confess(sprintf('Symbol %s not defined in %s',$import,__PACKAGE__))
            unless defined $symbol;
        $caller_stash->add_symbol('&'.$import, $symbol);
    }

    return;
}

sub parameter {
    my ($meta,$name,@rest) = @_;
    return _handle_attribute($meta,$name,'parameter',@rest);
}

sub option {
    my ($meta,$name,@rest) = @_;
    return _handle_attribute($meta,$name,'option',@rest);
}

sub _handle_attribute {
    my ($meta,$name,$type,@rest) = @_;

    Moose->throw_error('Usage: option \'name\' => ( key => value, ... )')
        if @rest % 2 == 1;

    my %info;
    @info{qw(package file line)} = caller(2);

    my %attributes = ( definition_context => \%info, @rest );
    my $attrs = ( ref($name) eq 'ARRAY' ) ? $name : [ ($name) ];

    # We are in a command class
    if (! $meta->isa('Moose::Meta::Role')
        && $meta->meta->does_role('MooseX::App::Meta::Role::Class::Command')) {

        # Get required extra traits for this class on first attrubute
        unless ($meta->has_app_attribute_metaroles) {
            # Find MooseX::App::Meta::Role::Class::Base in ISA
            foreach my $parent ($meta->linearized_isa) {
                if ($parent->meta->does_role('MooseX::App::Meta::Role::Class::Base')) {
                    $meta->app_attribute_metaroles([]);
                    last;
                }
            }
            # Apply missing meta roles if required to do so
            unless ($meta->has_app_attribute_metaroles) {
                my @extra_classes;
                my $name = $meta->name;
                foreach my $class (keys %PLUGIN_SPEC) {
                    my @commands = $class->meta->command_classes;
                    if (first { $name eq $_ } @commands) {
                        my $attribute_metaclass = $class->meta->attribute_metaclass;
                        push @extra_classes,
                            map { $_->name }
                            grep { $_->name ne 'MooseX::App::Meta::Role::Attribute::Option' }
                            grep { ! $_->isa('Moose::Meta::Role::Composite')  }
                            map {
                                $_->isa('Moose::Meta::Role::Composite') ?
                                $_->calculate_all_roles : $_
                            }
                            $attribute_metaclass->meta->calculate_all_roles_with_inheritance;
                    }
                }

                $meta->app_attribute_metaroles_add(@extra_classes);
            }
        }

        $attributes{traits} ||= [];
        push(@{$attributes{traits}},$meta->app_attribute_metaroles_uniq);
    }

    $attributes{'cmd_type'} = $type;
    # Loop all attributes and check attribute traits
    foreach my $attr (@$attrs) {
        my %local_attributes = %attributes;
        if ($attr =~ m/^\+(.+)/) {
            my $meta_attribute = $meta->find_attribute_by_name($1);
            unless ($meta_attribute->does('MooseX::App::Meta::Role::Attribute::Option')) {
                $local_attributes{traits} ||= [];
                push @{$local_attributes{traits}},'MooseX::App::Meta::Role::Attribute::Option'
                    unless (first { $_ eq 'AppOption' || $_ eq 'MooseX::App::Meta::Role::Attribute::Option' }
                        @{$local_attributes{traits}});
            }
        }

        $meta->add_attribute($attr, %local_attributes);
    }

    return;
}

sub app_prefer_commandline($) {
    my ( $meta, $value ) = @_;
    return $meta->app_prefer_commandline($value);
}

sub app_strict($) {
    my ( $meta, $value ) = @_;
    return $meta->app_strict($value);
}

sub app_fuzzy($) {
    my ( $meta, $value ) = @_;
    return $meta->app_fuzzy($value);
}

sub app_permute($) {
    my ( $meta, $value ) = @_;
    return $meta->app_permute($value);
}

sub app_base($) {
    my ( $meta, $name ) = @_;
    return $meta->app_base($name);
}

sub process_plugins {
    my ($self,$caller_class,@plugins) = @_;

    # Loop all requested plugins
    my @plugin_classes;
    foreach my $plugin (@plugins) {
        my $plugin_class = 'MooseX::App::Plugin::'.$plugin;

        # TODO eval plugin class
        Class::Load::load_class($plugin_class);

        push (@plugin_classes,$plugin_class);
    }

    # Store plugin spec
    $PLUGIN_SPEC{$caller_class} = \@plugin_classes;
    return;
}

sub process_init_meta {
    my ($self,%args) = @_;

    Moose->init_meta( %args );

    my $plugins         = $PLUGIN_SPEC{$args{for_class}} || [];
    my $apply_metaroles = delete $args{metaroles} || {};
    my $apply_roles     = delete $args{roles} || [];

    # Add plugin roles
    foreach my $plugin (@$plugins) {
        push(@{$apply_roles},$plugin,{ -excludes => [ 'plugin_metaroles' ] } )
    }

    # Add common role
    push(@{$apply_roles},'MooseX::App::Role::Common')
        unless first { $_ eq 'MooseX::App::Role::Common' } @{$apply_roles};

    # Process all plugins in the given order
    foreach my $plugin_class (@{$plugins}) {
        if ($plugin_class->can('plugin_metaroles')) {
            my ($metaroles) = $plugin_class->plugin_metaroles($args{for_class});
            if (ref $metaroles eq 'HASH') {
                foreach my $type (keys %$metaroles) {
                    $apply_metaroles->{$type} ||= [];
                    push (@{$apply_metaroles->{$type}},@{$metaroles->{$type}});
                }
            }
        }
    }

    # Add meta roles
    Moose::Util::MetaRole::apply_metaroles(
        for             => $args{for_class},
        class_metaroles => $apply_metaroles
    );

    # Add class roles
    Moose::Util::apply_all_roles($args{for_class},@{$apply_roles});

    # Init plugins
    foreach my $plugin_class (@{$plugins}) {
        if ($plugin_class->can('init_plugin')) {
            $plugin_class->init_plugin($args{for_class});
        }
    }

    # Return meta
    my $meta = $args{for_class}->meta;

    return $meta;
}

sub command_short_description($) {
    my ( $meta, $description ) = @_;
    return $meta->command_short_description($description);
}

sub command_long_description($) {
    my ( $meta, $description ) = @_;
    return $meta->command_long_description($description);
}

sub command_usage($) {
    my ( $meta, $usage ) = @_;
    return $meta->command_usage($usage);
}

*app_description    = \&command_long_description;
*app_usage          = \&command_usage;

sub command_strict($) {
    my ( $meta, $value ) = @_;
    return $meta->command_strict($value);
}

1;
