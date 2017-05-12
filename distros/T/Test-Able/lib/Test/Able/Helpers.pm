package Test::Able::Helpers;

use List::Util qw( shuffle );
use strict;
use Sub::Exporter -setup => {
    exports => [ qw(
        prune_super_methods
        shuffle_methods
        get_loop_plan
    ), ],
    groups => {
        default => [ qw(
            prune_super_methods
            shuffle_methods
            get_loop_plan
        ), ],
    },
};
use warnings;

=head1 NAME

Test::Able::Helpers

=head1 SYNOPSIS

 use Test::Able::Helpers;

 my $t = MyTest;
 $t->shuffle_methods;
 $t->run_tests;

=head1 DESCRIPTION

Test::Able::Helpers are a collection of mixin methods that can
be exported into the calling test class.  These are meant to
make doing some things with Test::Able easier.

See L<Test::Able::Cookbook> for example usages.

=head1 METHODS

=over

=item prune_super_methods

Removes any test-related methods from the associated method list if its from
a superclass (literally not from $self's class).

By default it does this for all test-related method types.
Type names can be optionally provided as args to limit what
types this is done for.

=cut

sub prune_super_methods {
    my ( $self, @types, ) = @_;

    @types = @{ $self->meta->method_types } unless @types;

    my $self_pkg = ref $self;
    for my $type ( @types ) {
        my $accessor = $type . '_methods';
        $self->meta->$accessor( [ grep {
            $_->package_name eq $self_pkg;
        } @{ $self->meta->$accessor } ] );
    }

    return;
}

=item shuffle_methods

Randomizes the test-related method lists.

By default it does this for all test-related method types.
Type names can be optionally provided as args to limit what
types this is done for.

=cut

sub shuffle_methods {
    my ( $self, @types, ) = @_;

    @types = @{ $self->meta->method_types } unless @types;

    for my $type ( @types ) {
        my $accessor = $type . '_methods';
        $self->meta->$accessor( [ shuffle @{ $self->meta->$accessor } ] );
    }

    return;
}

=item get_loop_plan

Calculates the plan for a test method when used in a "Loop-Driven" context.
This assumes the setup and teardown method lists are being explicitly
run as many times as the test method.

Has two required args: the test method name and the test count.
The test method name is used to lookup the plan of the test method
itself.  The test count is the number of times the test method will
be called.

=back

=cut

sub get_loop_plan {
    my ( $self, $test_method_name, $test_count, ) = @_;

    my $test_plan
      = $self->meta->test_methods->{ $test_method_name }->plan;
    return 'no_plan' if $test_plan eq 'no_plan';

    my $setup_plan;
    for my $method ( @{ $self->meta->setup_methods } ) {
        return 'no_plan' if $method->plan eq 'no_plan';
        $setup_plan += $method->plan;
    }

    my $teardown_plan;
    for my $method ( @{ $self->meta->teardown_methods } ) {
        return 'no_plan' if $method->plan eq 'no_plan';
        $teardown_plan += $method->plan;
    }

    return(
        ( $test_plan + $setup_plan + $teardown_plan ) * $test_count
    );
}

=head1 AUTHOR

Justin DeVuyst, C<justin@devuyst.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Justin DeVuyst.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
