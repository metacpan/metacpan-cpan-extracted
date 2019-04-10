package Stepford::Role::Step;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.006000';

use List::AllUtils qw( any );
use Stepford::LoggerWithMoniker;
use Stepford::Trait::StepDependency;
use Stepford::Trait::StepProduction;
use Stepford::Types qw( Logger );

use Moose::Role;

requires qw( run last_run_time );

has logger => (
    is       => 'ro',
    isa      => Logger,
    required => 1,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    if ( $args->{logger} ) {
        $args->{logger} = Stepford::LoggerWithMoniker->new(
            logger  => $args->{logger},
            moniker => $class->_log_moniker,
        );
    }

    return $args;
};

sub _log_moniker {
    my $class = shift;
    return $class;
}

# Some of these should be moved into a metaclass extension
sub productions {
    my $class = shift;

    return
        grep { $_->does('Stepford::Trait::StepProduction') }
        $class->meta->get_all_attributes;
}

sub has_production {
    my $class = shift;
    my $name  = shift;

    return any { $_->name eq $name } $class->productions;
}

sub productions_as_hashref {
    my $self = shift;

    return { map { $_->name => $self->production_value( $_->name ) }
            $self->productions };
}

sub production_value {
    my $self = shift;
    my $name = shift;

    my $reader = $self->meta->find_attribute_by_name($name)->get_read_method;
    return $self->$reader;
}

sub dependencies {
    my $class = shift;

    return
        grep { $_->does('Stepford::Trait::StepDependency') }
        $class->meta->get_all_attributes;
}

1;

# ABSTRACT: The basic role all step classes must implement

__END__

=pod

=encoding UTF-8

=head1 NAME

Stepford::Role::Step - The basic role all step classes must implement

=head1 VERSION

version 0.006000

=head1 DESCRIPTION

All of your step classes must consume this role. It provides the basic
interface that the L<Stepford::Runner> class expects.

=head1 ATTRIBUTES

This role provides one attribute:

=head2 logger

This attribute is required for all roles. It will be provided to your step
classes by the L<Stepford::Runner> object.

The Step object will wrap the logger with an object that prepends prepends
C<[$log_moniker] > to each log message. The moniker is determined by calling
C<< $class->_log_moniker >> on the class during object construction.

=head1 METHODS

This role provides the following methods:

=head2 $step->productions

This method returns a list of L<Moose::Meta::Attribute> objects that were
given the C<StepProduction> trait. This can be an empty list.

=head2 $step->has_production($name)

Returns true if the step has a production of the given name.

=head2 $step->productions_as_hashref

Returns all production values as a hash reference.

=head2 $step->production_value($name)

This method returns the value of the given production for the object it is
called on.

=head2 $step->dependencies

This method returns a list of L<Moose::Meta::Attribute> objects that were
given the C<StepDependency> trait. This can be an empty list.

=head1 REQUIRED METHODS

All classes which consume the L<Stepford::Role::Step> role must implement the
following methods:

=head2 $step->run

This method receives no arguments. It is expected to do whatever it is that
the step does.

It may also do other things such as record the last run time.

=head2 $step->last_run_time

This method must return a timestamp marking the last time the step was
run. You are encouraged to use L<Time::HiRes> as appropriate to provide hi-res
timestamps.

You can return C<undef> from this method to request an unconditional rebuild
of this step, regardless of the C<last_run_time> of previous steps. If a step
has an C<undef> C<last_run_time> after being run, then all steps that depend
on that step will also be re-run.

=head1 OPTIONAL METHODS

All classes which consume the L<Stepford::Role::Step> role may implement the
following methods:

=head2 $class->_log_moniker

This is expected to return a string identifying the class for the purposes of
logging. The default moniker is the full class name, but you may prefer to
override this in your step classes with something shorter or more descriptive.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Stepford/issues>.

=head1 AUTHOR

Dave Rolsky <drolsky@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
