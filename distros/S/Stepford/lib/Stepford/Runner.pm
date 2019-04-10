package Stepford::Runner;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.006000';

use List::AllUtils qw( first );
use Module::Pluggable::Object;
use MooseX::Params::Validate qw( validated_list );
use Parallel::ForkManager;
use Stepford::Error;
use Stepford::GraphBuilder;
use Stepford::Types qw(
    ArrayOfClassPrefixes ArrayOfSteps Bool ClassName
    HashRef Logger Maybe PositiveInt Step
);
use Try::Tiny;

use Moose;
use MooseX::StrictConstructor;

has _step_namespaces => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => ArrayOfClassPrefixes,
    coerce   => 1,
    required => 1,
    init_arg => 'step_namespaces',
    handles  => {
        step_namespaces => 'elements',
    },
);

has logger => (
    is      => 'ro',
    isa     => Logger,
    lazy    => 1,
    builder => '_build_logger',
);

has jobs => (
    is      => 'ro',
    isa     => PositiveInt,
    default => 1,
);

has _memory_stats => (
    is      => 'ro',
    isa     => Maybe ['Memory::Stats'],
    default => sub {
        return try {
            require Memory::Stats;
            my $s = Memory::Stats->new;
            $s->start;
            $s;
        }
        catch {
            undef;
        };
    },
);

has _step_classes => (
    is       => 'ro',
    isa      => ArrayOfSteps,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_step_classes',
);

# We want to preload all the step classes so that the final_steps passed to
# run are recognized as valid classes.
sub BUILD {
    my $self = shift;

    $self->_step_classes;

    return;
}

sub run {
    my $self = shift;
    my ( $final_steps, $config, $force_step_execution, $dry_run )
        = validated_list(
        \@_,
        final_steps => {
            isa    => ArrayOfSteps,
            coerce => 1,
        },
        config => {
            isa     => HashRef,
            default => {},
        },
        force_step_execution => {
            isa     => Bool,
            default => 0,
        },
        dry_run => {
            isa     => Bool,
            default => 'none',
        },
        );

    my $root_graph
        = $self->_make_root_graph_builder( $final_steps, $config )->graph;

    if ( $dry_run ne 'none' ) {
        ## no critic (InputOutput::RequireCheckedSyscalls)
        print $root_graph->as_string($dry_run);
    }
    elsif ( $self->jobs > 1 ) {
        $self->_run_parallel( $root_graph, $force_step_execution );
    }
    else {
        $self->_run_sequential( $root_graph, $force_step_execution );
    }

    return;
}

sub _run_sequential {
    my $self                 = shift;
    my $root_graph           = shift;
    my $force_step_execution = shift;

    $root_graph->traverse(
        sub {
            my $graph = shift;

            return
                unless $self->_should_run_step(
                $graph,
                $force_step_execution
                );

            $self->_run_step_in_process($graph);
            return;
        }
    );
}

sub _run_parallel {
    my $self                 = shift;
    my $root_graph           = shift;
    my $force_step_execution = shift;

    my $pm = Parallel::ForkManager->new( $self->jobs );

    my %graphs;
    my $steps_finished_since_last_iteration = 0;

    $pm->run_on_finish(
        sub {
            my ( $pid, $exit_code, $step_name, $signal, $message )
                = @_[ 0 .. 3, 5 ];

            if ($exit_code) {
                $pm->wait_all_children;
                die "Child process $pid failed while running step $step_name"
                    . " (exited with code $exit_code)";
            }
            elsif ( !$message ) {
                $pm->wait_all_children;
                my $error = "Child process $pid did not send back any data";
                $error .= " while running step $step_name";
                $error .= " (exited because of signal $signal)" if $signal;
                die $error;
            }
            elsif ( $message->{error} ) {
                $pm->wait_all_children;
                die "Child process $pid died"
                    . " while running step $step_name"
                    . " with error:\n$message->{error}";
            }
            else {
                my $graph = $graphs{$pid};
                die "Could not find step graph for $pid"
                    unless defined $graph;

                $graph->set_last_run_time( $message->{last_run_time} );
                $graph->set_step_productions_as_hashref(
                    $message->{productions} );
                $graph->set_is_being_processed(0);
                $graph->set_has_been_processed(1);
                $steps_finished_since_last_iteration++;
            }
        }
    );

    while ( !$root_graph->has_been_processed ) {
        $root_graph->traverse(
            sub {
                my $graph = shift;

                my $class = $graph->step_class;

                return
                    unless $self->_should_run_step(
                    $graph,
                    $force_step_execution
                    );

                unless ( $graph->is_serializable ) {
                    $self->_run_step_in_process($graph);
                    $steps_finished_since_last_iteration++;
                    return;
                }

                if ( my $pid = $pm->start($class) ) {
                    $graph->set_is_being_processed(1);

                    $graphs{$pid} = $graph;

                    $self->logger->debug(
                        "Forked child to run $class - pid $pid");
                    return;
                }

                # child
                my $error;
                try {
                    $self->_run_step_in_process($graph);
                }
                catch {
                    $error = $_;
                };

                my %message
                    = defined $error
                    ? ( error => $error . q{} )
                    : (
                    last_run_time => scalar $graph->last_run_time,
                    productions   => $graph->step_productions_as_hashref,
                    );

                $pm->finish( 0, \%message );
            }
        );

        $pm->reap_finished_children;

        # If none of the child processes have finished, there is no point in
        # wasting a bunch of CPU checking for steps that can be worked on. We
        # wait until at least one step has finished.
        $pm->wait_one_child unless $steps_finished_since_last_iteration;

        $steps_finished_since_last_iteration = 0;
    }

    $self->logger->debug('Waiting for children');
    $pm->wait_all_children;
}

sub _should_run_step {
    my $self                 = shift;
    my $graph                = shift;
    my $force_step_execution = shift;

    return 0 unless $graph->can_run_step;

    if ( $graph->step_is_up_to_date($force_step_execution) ) {
        $self->logger->info( 'Skipping ' . $graph->step_class );
        $graph->set_has_been_processed(1);
        return 0;
    }

    return 1;
}

sub _run_step_in_process {
    my $self  = shift;
    my $graph = shift;

    $self->_log_memory_usage( 'Before running ' . $graph->step_class );
    $graph->run_step;
    $self->_log_memory_usage( 'After running ' . $graph->step_class );

    return;
}

sub _make_root_graph_builder {
    my $self        = shift;
    my $final_steps = shift;
    my $config      = shift;

    return Stepford::GraphBuilder->new(
        config       => $config,
        step_classes => $self->_step_classes,
        final_steps  => $final_steps,
        logger       => $self->logger,
    );
}

sub _build_step_classes {
    my $self = shift;

    # Module::Pluggable does not document whether it returns class names in
    # any specific order.
    my $sorter = $self->_step_class_sorter;

    my @classes;

    for my $class (
        sort { $sorter->() } Module::Pluggable::Object->new(
            search_path => [ $self->step_namespaces ],
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

        $self->logger->debug("Found step class $class");
        push @classes, $class;
    }

    return \@classes;
}

sub _step_class_sorter {
    my $self = shift;

    my $x          = 0;
    my @namespaces = $self->step_namespaces;
    my %order      = map { $_ => $x++ } @namespaces;

    return sub {
        my $a_prefix = first { $a =~ /^\Q$_/ } @namespaces;
        my $b_prefix = first { $b =~ /^\Q$_/ } @namespaces;

        return ( $order{$a_prefix} <=> $order{$b_prefix} or $a cmp $b );
    };
}

sub _build_logger {
    my $self = shift;

    require Log::Dispatch;
    require Log::Dispatch::Null;
    return Log::Dispatch->new(
        outputs => [ [ Null => min_level => 'emerg' ] ] );
}

sub _log_memory_usage {
    my $self       = shift;
    my $checkpoint = shift;

    return unless $self->_memory_stats;

    $self->_memory_stats->checkpoint($checkpoint);

    # There's no way to get the total use so far without calling stop(), which
    # is quite annoying. See
    # https://github.com/celogeek/perl-memory-stats/issues/3.

    ## no critic (Subroutines::ProtectPrivateSubs)
    $self->logger->info(
        sprintf(
            'Total memory use since Stepford started is %d',
            $self->_memory_stats->_memory_usage->[-1][1]
                - $self->_memory_stats->_memory_usage->[0][1]
        )
    );
    $self->logger->info(
        sprintf(
            'Memory since last checked is %d',
            $self->_memory_stats->delta_usage
        )
    );
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Takes a set of steps and figures out what order to run them in

__END__

=pod

=encoding UTF-8

=head1 NAME

Stepford::Runner - Takes a set of steps and figures out what order to run them in

=head1 VERSION

version 0.006000

=head1 SYNOPSIS

    use Stepford::Runner;

    my $runner = Stepford::Runner->new(
        step_namespaces => 'My::Step',
    );

    $runner->run(
        final_steps => [
            'My::Step::DeployCatDatabase',
            'My::Step::DeployDogDatabase',
        ],
        config => {...},
    );

=head1 DESCRIPTION

This class takes a set of objects which do the L<Stepford::Role::Step> role
and determines what order they should be run so as to get to one or more final
steps.

Steps which are up to date are skipped during the run, so no unnecessary work
is done.

=for Pod::Coverage BUILD add_step

=head1 METHODS

This class provides the following methods:

=head2 Stepford::Runner->new(...)

This method returns a new runner object. It accepts the following arguments:

=over 4

=item * step_namespaces

This argument is required.

This can either be a string or an array reference of strings. Each string
should contain a namespace which contains step classes.

For example, if your steps are named C<My::Step::CreateFoo>,
C<My::Step::MergeFooAndBar>, and C<My::Step::DeployMergedFooAndBar>, the
namespace you'd provide is C<'My::Step'>.

The order of the step namespaces I<is> relevant. If more than one step has a
production of the same name, then the first step "wins". Stepford sorts step
class names based on the order of the namespaces provided to the constructor,
and then the full name of the class. You can take advantage of this feature to
provide different steps in different environments (for example, for testing).

The runner object assumes that every B<class> it finds in a step namespace is
a step. Specifically, if it finds a package that is a subclass of
L<Moose::Object>, then it throws an error if that package does not also
consume the L<Stepford::Role::Step> role.

This means you can have utility packages and roles in a step namespace, but
not Moose objects which aren't steps.

=item * jobs

This argument defaults to 1.

The number of jobs to run at a time. By default, all steps are run
sequentially. However, if you set this to a value greater than 1 then the
runner will run steps in parallel, up to the value you set.

=item * logger

This argument is optional.

This should be an object that provides C<debug>, C<info>, C<notice>,
C<warning>, and C<error> methods.

This object will receive log messages from the runner and (possibly your
steps).

If this is not provided, Stepford will create a L<Log::Dispatch> object with a
single L<Log::Dispatch::Null> output (which silently eats all the logging
messages).

Note that if you I<do> provide a logger object of your own, Stepford will not
load L<Log::Dispatch> into memory.

=back

=head2 $runner->run

When this method is called, the runner comes up with a plan of the steps
needed to get to the requested final steps.

When this method is called, we check for circular dependencies among the steps
and will throw a L<Stepford::Error> exception if it finds one. We also check
for unsatisfied dependencies for steps in the plan. Finally, we check to make
sure that no step provides its own dependencies as productions.

For each step, the runner checks if it is up to date compared to its
dependencies (as determined by the C<< $step->last_run_time >> method. If the
step is up to date, it is skipped, otherwise the runner calls C<< $step->run
>> on the step. You can avoid this check and force all steps to be executed
with the C< force_step_execution > parameter (documented below.)

Note that the step objects are always I<constructed>, so you should avoid
doing a lot of work in your constructor. Save that for the C<run> method.

This method accepts the following parameters:

=over 4

=item * final_steps

This argument is required.

This can either be a string or an array reference of strings. Each string
should be a step's class name. These classes must do the
L<Stepford::Role::Step> role.

These are the final steps run when the C<< $runner->run >> method is
called.

=item * config

This is an optional hash reference. For each step constructed, the runner
looks at the attributes that the step accepts. If they match any of the keys
in this hash reference, the key/value pair from this hash reference will be
passed to the step constructor. This matching is done based on attribute
C<init_arg> values.

Note that values generated as productions from previous steps will override
the corresponding key in the config hash reference.

=item * force_step_execution

This argument defaults to false.

This controls if we should force all steps to be executed rather than checking
which steps are up to date and do not need re-executing. Even with this set
each step will only be executed once per run regardless of how many other
steps depend on it during execution.

=item * dry_run

The argument is a boolean that defaults to false. When set to a true value,
Stepford prints out the steps that need to be executed and exits without
executing them.

=back

=head2 $runner->step_namespaces

This method returns the step namespaces passed to the constructor as a list
(not an arrayref).

=head2 $runner->logger

This method returns the C<logger> used by the runner, either what you passed
to the constructor or a default.

=head1 PARALLEL RUNS AND SERIALIZATION

When running steps in parallel, the results of a step (its productions) are
sent from a child process to the parent by serializing them. This means that
productions which can't be serialized (like a filehandle or L<DBI> handle)
will cause the runner to die when it tries to serialize their productions.

You can force a step class to be run in the same process as the runner itself
by having that step consume the L<Stepford::Role::Step::Unserializable>
role. Note that the runner may still fork I<after> a production has been
generated, so the values returned for a production must be able to survive a
fork, even if they cannot be serialized.

You can also work around this by changing the production entirely. For
example, instead of passing a DBI handle you could pass a data structure with
a DSN, username, password, and connection options.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Stepford/issues>.

=head1 AUTHOR

Dave Rolsky <drolsky@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
