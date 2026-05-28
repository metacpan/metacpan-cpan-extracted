package SignalWire::Skills::SkillRegistry;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.

use strict;
use warnings;

# Global registry mapping skill name -> class name
my %REGISTRY;
# External skill directories registered via add_skill_directory.
# Mirrors Python's SkillRegistry._external_paths.
my @EXTERNAL_PATHS;

sub register_skill {
    my ($class, $skill_name, $skill_class) = @_;
    $REGISTRY{$skill_name} = $skill_class;
}

sub get_factory {
    my ($class, $skill_name) = @_;

    # Return if already registered
    return $REGISTRY{$skill_name} if exists $REGISTRY{$skill_name};

    # Attempt to auto-load from Builtin namespace
    my $module = 'SignalWire::Skills::Builtin::' . _camelize($skill_name);
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

# Get complete schema for all registered skills.
#
# Mirrors Python's ``SkillRegistry.get_all_skills_schema()`` — returns a
# hashref keyed by skill name where each value carries metadata + the
# parameter schema for that skill. Perl skills don't carry rich
# Python-style parameter introspection in v1, so the value defaults to
# the minimal shape with just the skill name; built-in skills that
# expose ``parameter_schema`` get richer detail.
sub get_all_skills_schema {
    my ($self) = @_;
    # Accept both class-method (SkillRegistry->get_all_skills_schema) and
    # instance-method ($registry->get_all_skills_schema) calls.
    my $class = ref($self) || $self || __PACKAGE__;
    $class->_load_all_builtins;
    my %schema;
    for my $name (sort keys %REGISTRY) {
        my $skill_class = $REGISTRY{$name};
        my %entry = (name => $name, parameters => {});
        if (ref($skill_class) eq 'CODE') {
            # Factory closure; can't introspect statically
            ;
        } elsif (defined $skill_class) {
            if ($skill_class->can('parameter_schema')) {
                eval {
                    my $params = $skill_class->parameter_schema;
                    $entry{parameters} = $params if ref($params) eq 'HASH';
                };
            }
            if ($skill_class->can('skill_description')) {
                eval { $entry{description} = $skill_class->skill_description };
            }
            if ($skill_class->can('skill_version')) {
                eval { $entry{version} = $skill_class->skill_version };
            }
        }
        $schema{$name} = \%entry;
    }
    return \%schema;
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
    @EXTERNAL_PATHS = ();
}

# Add a directory to search for skills.
#
# Mirrors Python's
# `signalwire.skills.registry.SkillRegistry.add_skill_directory`:
# validate the path, die with an "X: <path>" message (Perl's analog of
# raising ValueError) when the path doesn't exist or isn't a directory,
# and de-duplicate entries in the external paths list.
sub add_skill_directory {
    my ($class, $path) = @_;
    die "Skill directory does not exist: $path\n" unless -e $path;
    die "Path is not a directory: $path\n"        unless -d $path;
    return if grep { $_ eq $path } @EXTERNAL_PATHS;
    push @EXTERNAL_PATHS, $path;
    return;
}

# Returns the registered external skill directories.
# Parity surface for Python's private `_external_paths` attribute —
# exposed under the underscored name so the signature enumerator skips
# it (matches Python convention).
sub _external_paths {
    my ($class) = @_;
    return [@EXTERNAL_PATHS];
}

1;
