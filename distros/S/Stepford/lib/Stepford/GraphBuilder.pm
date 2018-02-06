package Stepford::GraphBuilder;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.005000';

use List::AllUtils qw( sort_by uniq );
use Stepford::Error;
use Stepford::FinalStep;
use Stepford::Graph ();
use Stepford::Types qw( ArrayOfSteps HashRef Logger Step );

use Moose;
use MooseX::StrictConstructor;

has config => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

has _step_classes => (
    is       => 'ro',
    isa      => ArrayOfSteps,
    init_arg => 'step_classes',
    required => 1,
);

has _final_steps => (
    is       => 'ro',
    isa      => ArrayOfSteps,
    init_arg => 'final_steps',
    required => 1,
);

has graph => (
    is      => 'ro',
    isa     => 'Stepford::Graph',
    lazy    => 1,
    builder => '_build_graph',
);

has _production_map => (
    is       => 'ro',
    isa      => HashRef [Step],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_production_map',
);

has logger => (
    is       => 'ro',
    isa      => Logger,
    required => 1,
);

has _graph_cache => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
    handles => {
        _cache_graph      => 'set',
        _get_cached_graph => 'get',
    },
);

sub _build_graph {
    my $self = shift;

    my $graph = Stepford::Graph->new(
        config          => $self->config,
        logger          => $self->logger,
        step_class      => 'Stepford::FinalStep',
        children_graphs => [
            sort_by { $_->step_class }
            map { $self->_create_graph( $_, {} ) } @{ $self->_final_steps }
        ],
    );

    $self->logger->debug( 'Graph for '
            . ( join q{ - }, @{ $self->_final_steps } ) . ":\n"
            . $graph->as_string );

    return $graph;
}

sub _build_production_map {
    my $self = shift;

    my %map;
    for my $class ( @{ $self->_step_classes } ) {
        for my $attr ( map { $_->name } $class->productions ) {
            next if exists $map{$attr};

            $map{$attr} = $class;
        }
    }

    return \%map;
}

sub _create_graph {
    my $self       = shift;
    my $step_class = shift;
    my $parents    = shift;

    Stepford::Error->throw(
        "The set of dependencies for $step_class is cyclical")
        if exists $parents->{$step_class};

    my $childrens_parents = {
        %{$parents},
        $step_class => 1,
    };

    if ( my $graph = $self->_get_cached_graph($step_class) ) {
        return $graph;
    }

    my $graph = Stepford::Graph->new(
        config     => $self->config,
        logger     => $self->logger,
        step_class => $step_class,
        children_graphs =>
            $self->_create_children_graphs( $step_class, $childrens_parents ),
    );

    $self->_cache_graph( $step_class => $graph );

    return $graph;
}

sub _create_children_graphs {
    my $self              = shift;
    my $step_class        = shift;
    my $childrens_parents = shift;

    my @children_steps = uniq sort
        map { $self->_step_for_dependency( $step_class, $_->name ) }
        $step_class->dependencies;

    return [ map { $self->_create_graph( $_, $childrens_parents ) }
            @children_steps ];
}

sub _step_for_dependency {
    my $self        = shift;
    my $parent_step = shift;
    my $dep         = shift;

    # if a dependency exists in the config, we don't need to build it.
    return if exists $self->config->{$dep};

    my $map = $self->_production_map;

    Stepford::Error->throw( "Cannot resolve a dependency for $parent_step."
            . " There is no step that produces the $dep attribute."
            . ' Do you have a cyclic dependency?' )
        unless $map->{$dep};

    Stepford::Error->throw(
        "A dependency ($dep) for $parent_step resolved to the same step.")
        if $map->{$dep} eq $parent_step;

    $self->logger->debug(
        "Dependency $dep for $parent_step is provided by $map->{$dep}");

    return $map->{$dep};
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Represents a concrete plan for execution by a Stepford::Runner

__END__

=pod

=encoding UTF-8

=head1 NAME

Stepford::GraphBuilder - Represents a concrete plan for execution by a Stepford::Runner

=head1 VERSION

version 0.005000

=head1 DESCRIPTION

This class has no user-facing parts.

=for Pod::Coverage next_step_set

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Stepford/issues>.

=head1 AUTHOR

Dave Rolsky <drolsky@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2018 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
