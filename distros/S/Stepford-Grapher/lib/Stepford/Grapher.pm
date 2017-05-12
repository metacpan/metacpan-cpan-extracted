package Stepford::Grapher;

use strict;
use warnings;
use namespace::autoclean;

use Module::Pluggable::Object;

use Moose;
use Stepford::Error;

our $VERSION = '1.01';

use Stepford::Grapher::Types qw(
    ArrayRef ArrayOfSteps ArrayOfClassPrefixes HashRef Int Step Str
);

use List::Util qw( first );

has step => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _step_classes => (
    is       => 'ro',
    isa      => ArrayOfSteps,
    init_arg => 'step_classes',
    lazy     => 1,
    builder  => '_build_step_classes',
);

has step_namespace => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => ArrayOfClassPrefixes,
    required => 1,
    handles  => {
        all_step_namespaces => 'elements',
    },
);

has _renderer => (
    is       => 'ro',
    does     => 'Stepford::Grapher::Role::Renderer',
    init_arg => 'renderer',
    required => 1,
);

has depth => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

# We want to preload all the step classes so that the final_steps passed to
# run are recognized as valid classes.
sub BUILD {
    my $self = shift;

    $self->_step_classes;

    return;
}

########################################################################
# cargo culted from Stepford::Runner
# ugh, but whatchagonnado?

sub _build_step_classes {
    my $self = shift;

    # Module::Pluggable does not document whether it returns class names in
    # any specific order.
    my $sorter = $self->_step_class_sorter;

    my @classes;

    for my $class (
        sort { $sorter->() } Module::Pluggable::Object->new(
            search_path => [ $self->all_step_namespaces ],
            require     => 1,
        )->plugins
        ) {

        # We need to skip roles
        next unless $class->isa('Moose::Object');

        unless ( $class->does('Stepford::Role::Step') ) {
            Stepford::Error->throw( message =>
                    qq{Found a class which doesn't do the Stepford::Role::Step role: $class}
            );
        }

        # $self->logger->debug("Found step class $class");
        push @classes, $class;
    }

    return \@classes;
}

sub _step_class_sorter {
    my $self = shift;

    my $x          = 0;
    my @namespaces = $self->all_step_namespaces;
    my %order      = map { $_ => $x++ } @namespaces;

    return sub {
        my $a_prefix = first { $a =~ /^\Q$_/ } @namespaces;
        my $b_prefix = first { $b =~ /^\Q$_/ } @namespaces;

        return ( $order{$a_prefix} <=> $order{$b_prefix} or $a cmp $b );
    };
}

########################################################################

# has _renderer => (
#     is       => 'ro',
#     init_arg => 'renderer',
#     does     => 'Stepford::Grapher::Role::Renderer',
#     required => 1,
# );

has _step_deps => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef [ HashRef [Step] ],
    lazy    => 1,
    builder => '_build_step_deps',
);

sub _build_step_deps {
    my $self = shift;

    unless ( is_Step( $self->step ) ) {
        Stepford::Error->throw( message => $self->step
                . q{ is not a valid Step (maybe your step_namespace didn't load it?)}
        );
    }

    my $depth = 0;

    my %steps;
    my @todo_steps = ( $self->step );
    while (@todo_steps) {
        last if $self->depth && $depth > $self->depth;

        my $step = shift @todo_steps;
        next if $steps{$step};

        $steps{$step} = $self->_deps_for($step);
        push @todo_steps, values %{ $steps{$step} };

        $depth++;
    }

    return \%steps;
}

sub _deps_for {
    my $self = shift;
    my $step = shift;

    my %return_values;

    for my $dep ( $step->dependencies ) {
        my $name = $dep->name;

        # inefficent;  Should probably make this quicker
        my $producing_class = first {
            $_->has_production($name)
        }
        @{ $self->_step_classes };

        unless ($producing_class) {
            Stepford::Error->throw(
                message => "Cannot resolve step dependancy '$name'" );
        }
        $return_values{$name} = $producing_class;
    }

    return \%return_values;
}

########################################################################

with 'MooseX::Getopt::Dashes';

sub run {
    my $self = shift;
    $self->_renderer->render( $self->_step_deps );
    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=head1 NAME

Stepford::Grapher - produce graphs of Stepford Dependencies

=head1 VERSION

version 1.01

=head1 SYNOPSIS

From the shell:

    foo@bar:~/steps$ graph-stepford.pl --step-namespace=My::Step --step=My::Step::ExampleStep --output='diagram.png'

Or from code:

    my $grapher = Stepford::Grapher->new(
        step  => 'My::Step::ExampleStep',
        step_namespaces => ['My::Steps'],
        renderer => Stepford::Grapher::Renderer::Graphviz->new(
            output => 'diagram.png',
        ),
    );
    $grapher->run;

=head1 DESCRIPTION

STOP: The most common usage for this module is to use the command line C<graph-
stepford.pl> program. You should read the documentation for C<graph-stepford.pl>
to see how that works.

=head1 ATTRIBUTES

=head2 step

A string containing the class name of the step you wish to create a diagram for.

Required.

=head2 step_namespace

An array of strings containing the prefixes of step class names that should
be loaded.  This must contain the step class passed in the C<step> parameter.

For example, if you have the steps C<My::Step::Foo>, C<My::Step::Bar>,
C<ThirdyParty::Step::Baz> you would need to pass
C<['My::Step','ThirdParty::Step']>

All classes under the prefix will be loaded and it is an error if any of those
classes are do not consume the L<Stepford::Role::Step> role (this is the same
behavior as Stepford itself.)

Required.

=head2 depth

If this is provided, the graph will not go more than this number of levels
back from the target step.

By default, this is zero and all levels are included.

=head2 renderer

The renderer instance (i.e. an instance of something that consumes the
L<Stepford::Grapher::Role::Renderer> role.)

Required.

=head1 METHOD

=head2 run

Use the renderer to render the dependencies graph.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Stepford-Grapher/issues>.

=head1 AUTHOR

Mark Fowler <mfowler@maxmind.com>

=head1 CONTRIBUTOR

=for stopwords Dave Rolsky

Dave Rolsky <drolsky@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2017 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: produce graphs of Stepford Dependencies

