package Test::Able::Role::Meta::Class;

use Moose::Role;
use Moose::Util::TypeConstraints;
use Scalar::Util;
use strict;
use Test::Able::Role::Meta::Method;
use Test::Able::Method::Array;
use warnings;

with qw( Test::Able::Planner );

=head1 NAME

Test::Able::Role::Meta::Class - Main metarole

=head1 DESCRIPTION

This metarole gets applied to the Moose::Meta::Class metaclass objects
for all Test::Able objects.  This metarole also pulls in
L<Test::Able::Planner>.

=head1 ATTRIBUTES

=over

=item method_types

The names of the different types of test-related methods.
The default set is startup, setup, test, teardown, and shutdown.

=cut

has 'method_types' => (
    is => 'ro', isa => 'ArrayRef', lazy_build => 1,
);

=item *_methods

The test-related method lists.  There will be one for each method
type.  The default set will be:

startup_methods
setup_methods
test_methods
teardown_methods
shutdown_methods

These lists are what forms the basis of the test execution plan.

The lists themselves will be coerced into L<Test::Able::Method::Array> objects
just for the convenience of overloading for hash access.  The elements of the
lists will be L<Test::Able::Role::Meta::Method>-based method metaclass
objects.

=cut

for ( @{ __PACKAGE__->_build_method_types } ) {
    has "${_}_methods" => (
        is => 'rw', isa => 'Test::Able::MethodArray', lazy_build => 1,
        coerce => 1,
        trigger => sub {
            my ( $self, $value, ) = @_;

            $self->clear_plan;

            return;
        },
    );
}

subtype 'Test::Able::MethodArray'
  => as 'Object'
  => where { $_->isa( 'Test::Able::Method::Array' ); };

coerce 'Test::Able::MethodArray'
  => from 'ArrayRef'
  => via { bless( $_, 'Test::Able::Method::Array' ); };

=item test_objects

The list of L<Test::Able::Object>-based objects that the test runner
object will iterate through to make up the test run.

=cut

has 'test_objects' => (
    is => 'rw', isa => 'ArrayRef', lazy_build => 1,
);

=item current_test_object

The test object that is currently being executed (or introspected).

=cut

has 'current_test_object' => (
    is => 'rw', isa => 'Object', clearer => 'clear_current_test_object',
);

=item current_test_method

The method metaclass object of the associated test method.
This is only useful from within a setup or teardown method.
Its also available in the test method itself but current_method()
would be exactly the same in a test method and its shorter to type.

=cut

has 'current_test_method' => (
    is => 'rw', isa => 'Object', clearer => 'clear_current_test_method',
);

=item current_method

The method metaclass object of the currently executing test-related
method.

=cut

has 'current_method' => (
    is => 'rw', isa => 'Object', clearer => 'clear_current_method',
);

=item test_runner_object

The test object that will be running the show.  It may itself be in the
test_objects list.  The run_tests() method sets this value to its invocant.

=cut

has 'test_runner_object' => (
    is => 'rw', isa => 'Object',
);

=item dry_run

Setting this true will cause all test-related method execution to be skipped.
This means things like method exception handling, method plan handling, and
Test::Builder integration will also not happen.  One use of this could be to
print out the execution plan.  The default is 0.

=cut

has 'dry_run' => (
    is => 'rw', isa => 'Bool', default => 0,
);

=item on_method_plan_fail

Determines what is done, if anything, when the observed method plan doesn't
match the expected method plan after the test-related method runs.  If this
attribute is not set then nothing special is done.  Setting this to log or die
will cause the failure to be logged via log() or just died upon.  The default
is log.

=cut

enum 'Test::Able::MethodPlanFailAction' => qw( die log );

has 'on_method_plan_fail' => (
    is => 'rw', isa => 'Test::Able::MethodPlanFailAction', default => 'log',
    clearer => 'clear_on_method_plan_fail',
);

=item on_method_exception

Determines what is done, if anything, when an exception is thrown within a
test-related method.

If this attribute isn't set then the exception is simply rethrown.  This is
the default.

If its set to "continue" then the exception will be silently ignored.

And if set to "continue_at_level" the exception will also be silently ignored
and the test runner will skip over lower levels, if there are any, of the test
execution plan.  The levels are defined as follows. The startup and shutdown
methods are at the first level.  The setup and teardown methods are the second
level.  And test methods are the third and last level.  Or in visual form:

 startup
     setup
         test
     teardown
 shutdown

In addition, when this attribute is set to continue or continue_at_level the
exceptions will be recorded in the method_exceptions attribute of the
currently executing test object.

There is only one way to cause a fatal exception when this attribute is set to
continue or continue_at_level.  And that is to throw a
L<Test::Able::FatalException> exception.

=cut

enum 'Test::Able::MethodExceptionAction' => qw( continue continue_at_level );

has 'on_method_exception' => (
    is => 'rw', isa => 'Test::Able::MethodExceptionAction',
    clearer => 'clear_on_method_exception',
);

=item method_exceptions

List of exceptions that have occurred while inside a test-related method in
this test object.  Each element of the list is a hashref that looks like this:

 {
     method    => $self->current_method,
     exception => $exception,
 }

=back

=cut

has 'method_exceptions' => (
    is => 'rw', isa => 'ArrayRef[HashRef]', lazy_build => 1,
);

sub _build_method_types {
    my ( $self, ) = @_;

    return [ qw( startup setup test teardown shutdown ) ];
}

sub _build_startup_methods {
    my ( $self, ) = @_;

    return $self->build_methods( 'startup' );
}

sub _build_setup_methods {
    my ( $self, ) = @_;

    return $self->build_methods( 'setup' );
}

sub _build_test_methods {
    my ( $self, ) = @_;

    return $self->build_methods( 'test' );
}

sub _build_teardown_methods {
    my ( $self, ) = @_;

    return $self->build_methods( 'teardown' );
}

sub _build_shutdown_methods {
    my ( $self, ) = @_;

    return $self->build_methods( 'shutdown' );
}

sub _build_test_objects {
    my ( $self, ) = @_;

    return $self->current_test_object
      ? [ $self->current_test_object, ] : [];
}

sub _build_method_exceptions { []; }

=head1 METHODS

=over

=item run_tests

The main test runner method.  Iterates over test_objects list calling
run_methods() to run through the test execution plan.

Manages test_runner_object, current_test_object, runner_plan, and
last_runner_plan along the way.

=cut
sub run_tests {
    my ( $self, ) = @_;

    $self->test_runner_object( $self, );
    for my $test_object ( @{ $self->test_objects } ) {
        $test_object->meta->test_runner_object( $self, );
    }

    # Initial plan calc.
    $self->runner_plan;

    $self->log( "$self->run_tests() called but there are no test objects" )
      unless @{ $self->test_objects };
    for my $test_object ( @{ $self->test_objects } ) {
        $test_object->meta->current_test_object( $test_object );

        my $exceptions_before_startup = @{ $self->method_exceptions };
        $test_object->meta->run_methods( 'startup'  );
        $test_object->meta->run_methods( 'test'     )
          if $exceptions_before_startup == @{ $self->method_exceptions };
        $test_object->meta->run_methods( 'shutdown' );

        $test_object->meta->clear_current_test_object;
    }

    # Finalize planning for this run.
    $self->clear_runner_plan;
    $self->runner_plan;
    $self->clear_last_runner_plan;

    return;
}

=item run_methods

Executes a test-related method list as part of the test execution plan.  Takes
one argument and that's the name of the test-related method type.  Also, for
each test method, it calls run_methods() for the setup and teardown method
lists.

=cut

sub run_methods {
    my ( $self, $type, ) = @_;

    my $accessor_name = $type . '_methods';
    my $methods       = $self->$accessor_name;
    my $count         = @{ $methods };
    my $i;
    for my $method ( @{ $methods } ) {
        my $setup_exception_count;
        if ( $type eq 'test' ) {
            $self->current_test_method( $method );
            my $exceptions_before_setup = @{ $self->method_exceptions };
            $self->run_methods( 'setup' ) if $method->do_setup;
            $setup_exception_count
              = @{ $self->method_exceptions } - $exceptions_before_setup;
        }

        my $method_name = $method->name;
        unless ( $setup_exception_count ) {
            $self->current_method( $method );
            $self->log(
                $self->current_test_object . '->' . $method_name
                . "($type/" . $method->plan . ")"
                . '('. ++$i . "/$count)"
            );
        }

        unless ( $setup_exception_count || $self->dry_run ) {
            my $tests_before = $self->builder->{Curr_Test};

            eval { $self->current_test_object->$method_name; };
            if ( my $exception = $@ ) {
                die $exception unless $self->on_method_exception;

                my $test_object_meta = $self->current_test_object->meta;
                push(
                    @{ $test_object_meta->method_exceptions },
                    {
                        method    => $self->current_method,
                        exception => $exception,
                    }
                );

                die $exception if Scalar::Util::blessed( $exception )
                  && $exception->isa( 'Test::Able::FatalException' );
            }

            if ( $self->on_method_plan_fail && $method->plan =~ /^\d+$/ ) {
                my $tests_diff = $self->builder->{Curr_Test} - $tests_before;
                if ( $tests_diff != $method->plan ) {
                    my $msg = "Method $method_name planned " . $method->plan
                      . " tests but ran $tests_diff.";
                    if ( $self->on_method_plan_fail eq 'die' ) {
                        die "$msg\n";
                    }
                    else { $self->log( $msg ); }
                }
            }
        }

        if ( $type eq 'test' ) {
            $self->run_methods( 'teardown' ) if $method->do_teardown;
            $self->clear_current_test_method;
        }
        $self->clear_current_method;
    }

    return;
}

=item build_methods

Builds a test-related method list from the method metaclass objects associated
with this metaclass object.  The method list is sorted alphabetically by
method name.  Takes one argument and that's the name of the test-related
method type.

=cut

sub build_methods {
    my ( $self, $type, ) = @_;

    my @methods;
    for my $method ( $self->current_test_object->meta->get_all_methods ) {
        if ( $method->can( 'type' ) ) {
            my $method_type = $method->type;
            push( @methods, $method )
              if defined $method_type && $method_type eq $type;
        }
    }

    return bless(
        [ sort {
            $a->order <=> $b->order || $a->name cmp $b->name
        } @methods ],
        'Test::Able::Method::Array'
    );
}

=item build_all_methods

Convenience method to call build_methods() for all method types.

=cut

sub build_all_methods {
    my ( $self, ) = @_;

    for my $type ( @{ $self->method_types } ) {
        my $accessor_name =          $type . '_methods';
        my $has_name      = 'has_' . $type . '_methods';
        $self->$accessor_name unless $self->$has_name;
    }

    return;
}

=item clear_all_methods

Convenience method to clear all the test-related method lists out.

=cut

sub clear_all_methods {
    my ( $self, ) = @_;

    for my $type ( @{ $self->method_types } ) {
        my $clear_name = 'clear_' . $type . '_methods';
        my $has_name   = 'has_'   . $type . '_methods';
        $self->$clear_name if $self->$has_name;
    }

    return;
}

=item log

All logging goes through this method.  It sends its args along to
Test::Builder::diag.  And only if $ENV{TEST_VERBOSE} is set.

=cut

sub log {
    my $self = shift;

    $self->builder->diag( @_ ) if $ENV{ 'TEST_VERBOSE' };

    return;
}

sub _build_plan {
    my ( $self, ) = @_;

    my $plan;
    my $test_method_with_setup_count = grep {
        $_->do_setup;
    } @{ $self->test_methods };
    my $test_method_with_teardown_count = grep {
        $_->do_teardown;
    } @{ $self->test_methods };
    METHOD_TYPE: for my $type ( @{ $self->method_types } ) {
        my $accessor_name = $type . '_methods';
        for my $method ( @{ $self->$accessor_name } ) {
                if ( $method->plan eq 'no_plan' ) {
                    $plan = $method->plan;
                    last METHOD_TYPE;
                }
                else {
                    if ( $accessor_name eq 'setup_methods' ) {
                        $plan
                          += $method->plan * $test_method_with_setup_count;
                    }
                    elsif ( $accessor_name eq 'teardown_methods' ) {
                        $plan
                          += $method->plan * $test_method_with_teardown_count;
                    }
                    else { $plan += $method->plan; }
                }
        }
    }
    $plan = 'no_plan' unless defined $plan;

    return $plan;
}

=item clear_plan

Special purpose plan clearer that dumps the test object's plan and the test
runner's plan in one shot.

=back

=cut

#TODO: Could change this if Class::MOP bug 41449 is resolved.
#sub clear_plan {
before 'clear_plan' => sub {
    my ( $self, ) = @_;

    delete $self->{ 'plan' };
    delete $self->{ 'runner_plan' };

    return;
};
#}

# Hack Test::Builder because it doesn't do plan alterations.
sub _build_runner_plan {
    my ( $self, ) = @_;

    $self->_hack_test_builder( $self->builder );

    # Compute current plan.
    my $plan;
    for my $test_object ( @{ $self->test_objects } ) {
        $test_object->meta->current_test_object( $test_object );

        my $object_plan = $test_object->meta->plan;
        if ( $object_plan eq 'no_plan' ) {
            $plan = $object_plan;
            last;
        }
        else { $plan += $object_plan; }

        $test_object->meta->clear_current_test_object;
    }
    $plan = 'no_plan' unless defined $plan;

    return $plan if $self->dry_run;

    $self->builder->no_plan unless $self->builder->has_plan;

    # Update Test::Builder.
    if ( $self->builder->{No_Plan} || $self->builder->{was_No_Plan} ) {
        if ( $plan =~ /^\d+$/ ) {
            if ( $self->has_last_runner_plan ) {
                my $last = $self->last_runner_plan;
                my $plan_diff = $plan - ( $last eq 'no_plan' ? 0 : $last );
                $self->builder->{Expected_Tests} += $plan_diff;
            }
            else {
                $self->builder->{Expected_Tests} += $plan;
            }
                $self->builder->{No_Plan}     = 0;
                $self->builder->{was_No_Plan} = 1;
                $self->last_runner_plan( $plan );
        }
        else { $self->builder->{No_Plan} = 1; }
    }

    return $plan;
}

#TODO:  dump this ASAP.
# Hack Test::Builder cause it doesn't do deferred plans; yet.
my $hacked_test_builder;
sub _hack_test_builder {
    my ( $self, ) = @_;

    return if $hacked_test_builder;
    $hacked_test_builder++;
    no warnings 'redefine';
    my $original_sub = \&Test::Builder::_ending;
    *Test::Builder::_ending = sub {
        my $builder = shift;

        if ( $builder->{was_No_Plan} && $self->runner_plan =~ /\d+/ ) {
            $builder->expected_tests( $self->builder->{Expected_Tests} );
            $builder->no_header( 1 );
        }

        return $builder->$original_sub( @_, );
    };
}

=head1 AUTHOR

Justin DeVuyst, C<justin@devuyst.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Justin DeVuyst.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
