package SignalWire::Agents::Skills::SkillRegistry;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.

use strict;
use warnings;

# Global registry mapping skill name -> class name
my %REGISTRY;

sub register_skill {
    my ($class, $skill_name, $skill_class) = @_;
    $REGISTRY{$skill_name} = $skill_class;
}

sub get_factory {
    my ($class, $skill_name) = @_;

    # Return if already registered
    return $REGISTRY{$skill_name} if exists $REGISTRY{$skill_name};

    # Attempt to auto-load from Builtin namespace
    my $module = 'SignalWire::Agents::Skills::Builtin::' . _camelize($skill_name);
    eval "require $module";  ## no critic
    if (!$@) {
        # If the module registered itself, return it
        return $REGISTRY{$skill_name} if exists $REGISTRY{$skill_name};
        # Otherwise register it
        $REGISTRY{$skill_name} = $module;
        return $module;
    }

    return undef;
}

sub list_skills {
    my ($class) = @_;
    # Make sure all builtins are loaded
    $class->_load_all_builtins;
    return [ sort keys %REGISTRY ];
}

sub _load_all_builtins {
    my ($class) = @_;
    my @names = qw(
        api_ninjas_trivia claude_skills datasphere datasphere_serverless
        datetime google_maps info_gatherer joke math mcp_gateway
        native_vector_search play_background_file spider swml_transfer
        weather_api web_search wikipedia_search custom_skills
    );
    for my $name (@names) {
        $class->get_factory($name);  # triggers auto-load
    }
}

sub _camelize {
    my ($name) = @_;
    # Convert snake_case to CamelCase: api_ninjas_trivia -> ApiNinjasTrivia
    $name =~ s/_(.)/uc($1)/ge;
    return ucfirst($name);
}

sub clear_registry {
    %REGISTRY = ();
}

1;
