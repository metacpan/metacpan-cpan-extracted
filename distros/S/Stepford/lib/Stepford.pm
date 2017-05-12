package Stepford;

use strict;
use warnings;

our $VERSION = '0.004001';

1;

# ABSTRACT: A vaguely Rake/Make/Cake-like thing for Perl - create steps and let a runner run them

__END__

=pod

=encoding UTF-8

=head1 NAME

Stepford - A vaguely Rake/Make/Cake-like thing for Perl - create steps and let a runner run them

=head1 VERSION

version 0.004001

=head1 SYNOPSIS

    package My::Step::MakeSomething;

    use autodie;
    use Moose;

    has input_file => (
        traits   => ['StepDependency'],
        is       => 'ro',
        required => 1,
    );

    has output_file => (
        traits  => ['StepProduction'],
        is      => 'ro',
        default => '/path/to/file',
    );

    with 'Stepford::Role::Step::FileGenerator';

    sub run {
        my $self = shift;

        open my $input_fh,  '<', $self->input_file;
        open my $output_fh, '>', $self->output_file;
        while (<$input_fh>) {
            chomp;
            print {$output_fh} $_ * 2, "\n";
        }
        close $input_fh;
        close $output_fh;
    }

    package My::Runner;

    use Stepford::Runner;

    my $runner = Stepford::Runner->new(
        step_namespaces => 'My::Step',
        logger          => $log_object,    # optional
        jobs            => 4,              # optional
    );

    # Runs all the steps needed to get to the final_steps.
    $runner->run(
        final_steps => 'My::Step::MakeSomething',
    );

=head1 DESCRIPTION

B<NOTE: This is alpha code. You have been warned!>

Stepford provides a framework for running a set of steps that are dependent on
other steps. At a high level, this is a lot like Make, Rake, etc. However, the
actual implementation is fairly different. Currently, there is no DSL, no
Stepfile, etc.

With Stepford, each step is represented by a class you create. That class
should consume one of the available Step roles. Those are:

=over 4

=item * L<Stepford::Role::Step::FileGenerator>

For steps that generate files.

=item * L<Stepford::Role::Step>

For steps that I<don't> generate files.

=item * L<Stepford::Role::Step::FileGenerator::Atomic>

For a step that wants to generate a single file atomically.

=back

Steps declare both their dependencies (required inputs) and productions
(outputs) as attributes. These attributes should be given either the
C<StepDependency> or C<StepProduction> trait as appropriate.

The L<Stepford::Runner> class analyzes the dependencies and productions for
each step to figure out what steps it needs to run in order to satisfy the
dependencies of the final steps you specify.

Each step can specify a C<last_run_time> method (or get one from the
L<Stepford::Role::Step::FileGenerator> role). The runner uses this to skip
steps that are up to date.

See L<Stepford::Runner>, L<Stepford::Role::Step>, and
L<Stepford::Role::Step::FileGenerator>, and
L<Stepford::Role::Step::FileGenerator::Atomic> for more details.

=head1 CONCEPTS AND DESIGN

In order to understand how Stepford works you must understand a few key concepts.

First off, we have steps. A step is simply a self-contained unit of work, like
generating a file, populating a database, etc. There are no restrictions on
what steps can do. The only restriction is that they are expected to declare
their dependencies and/or productions (more on these below).

Each step is a L<Moose> class. Each step class should represent a concrete
action, not a higher-level concept. In other words, the class name should be
something like "CopyFooBarFilesToProduction", B<not> "CopyFiles". If you have
several steps that all share similar logic, you can use a role to share that
logic between classes.

Each step must declare its dependencies and/or productions as regular Moose
attributes. These attributes can contain any type of value. They are simply
data. Note, however, that if you want to run steps in parallel, then the
dependencies (and therefore productions) must be serializable data types (so
no L<DBI> handles, etc.).

A dependency is simply a value that a given step expects to get from another
step (they can also be supplied to the runner manually).

The flip side of a dependency is a production. This is a value that the step
will generate as needed.

Steps are run by a L<Stepford::Runner> object. To create this object, you give
it a list of step namespaces and the class(es) of the final step(s) you want
to run. The runner looks at the final steps' dependencies and uses this
information to figure out what other steps to run. It looks for steps with
productions that satisfy these dependencies and adds any matching steps to the
execution plan. It does this iteratively for each step it adds to the plan
until the dependencies are satisfied for every step.

The runner detects cyclic dependencies (A requires B requires C requires B)
and throws an error. It also detects when a step has a dependency that cannot
be satisfied by the production of any other step.

Note that the matching of production to dependency is done solely by
name. It's up to you to ensure that the output of a production is something
that satisfies the dependency (in terms of the value's type, content, etc.).

If multiple classes have a production of the same name, then the first class
that Stepford sees "wins". This can be useful if you want to override a step
for testing, for example. See the documentation of the L<Stepford::Runner>
class's C<new> method for more details on step namespaces.

It is not possible for a class to have an attribute that is simultaneously a
dependency and a production. This would be a natural design for a step that
transformed a data value, but it makes dependency resolution
impossible. However, nothing stops you from having two attributes that each
produce the same B<value>. For example, the attributes could both reference a
path on disk and the step's C<run> method could alter the content of that file
in place.

It is not currently possible for a class to have optional dependencies. This
may be added in the future if it turns out to be useful.

=head1 FUTURE FEATURES

There are several very obvious things that should be added to this framework:

=over 4

=item * Dry runs

=back

=head1 VERSIONING POLICY

This module uses semantic versioning as described by
L<http://semver.org/>. Version numbers can be read as X.YYYZZZ, where X is the
major number, YYY is the minor number, and ZZZ is the patch number.

=head1 SUPPORT

Please report all issues with this code using the GitHub issue tracker at
L<https://github.com/maxmind/Stepford/issues>.

Bugs may be submitted through L<https://github.com/maxmind/Stepford/issues>.

=head1 AUTHOR

Dave Rolsky <drolsky@maxmind.com>

=head1 CONTRIBUTORS

=for stopwords Greg Oschwald Mark Fowler Olaf Alders Ran Eilam

=over 4

=item *

Greg Oschwald <goschwald@maxmind.com>

=item *

Mark Fowler <mfowler@maxmind.com>

=item *

Olaf Alders <oalders@maxmind.com>

=item *

Ran Eilam <reilam@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2017 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
