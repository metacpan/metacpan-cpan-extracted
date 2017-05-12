package MooseX::Role::Validatable;

use Moose::Role;
use MooseX::Role::Validatable::Error;

our $VERSION = '0.10';

use Class::Load qw/load_class/;
use Carp qw(confess);
use Scalar::Util qw/blessed/;

has '_init_errors' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    init_arg => undef,
    default  => sub { return [] },
);
has '_validation_errors' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    init_arg => undef,
    default  => sub { return [] },
);

has 'error_class' => (
    is      => 'ro',
    default => sub { 'MooseX::Role::Validatable::Error' },
    trigger => sub {
        my $self = shift;
        load_class($self->error_class);
    });

has validation_methods => (
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    lazy_build => 1,
);

sub _build_validation_methods {
    my $self = shift;
    return [grep { $_ =~ /^_validate_/ } ($self->meta->get_all_method_names)];
}

sub all_errors {
    my $self = shift;
    return (@{$self->{_init_errors}}, @{$self->{_validation_errors}});
}

sub all_init_errors {
    return @{(shift)->{_init_errors}};
}

sub all_validation_errors {
    return @{(shift)->{_validation_errors}};
}

sub passes_validation {
    my $self       = shift;
    my @all_errors = $self->all_errors;
    return (scalar @all_errors) ? 0 : 1;
}

sub should_alert {
    my $self = shift;
    return (grep { $_->alert } ($self->all_errors)) ? 1 : 0;
}

sub confirm_validity {
    my $self = shift;
    $self->{_validation_errors} = [
        map { $self->_errfilter($_) }
        map { $self->$_ } @{$self->validation_methods}];
    return $self->passes_validation;
}

sub add_errors {
    my ($self, @errors) = @_;
    push @{$self->{_init_errors}}, map { $self->_errfilter($_) } @errors;
    return scalar @errors;
}

sub initialized_correctly {
    my $self = shift;
    return (@{$self->{_init_errors}}) ? 0 : 1;
}

sub all_errors_by_severity {
    my $self = shift;
    return (sort { $b->severity <=> $a->severity } ($self->all_errors));
}

sub primary_validation_error {
    my $self = shift;

    my @errors = $self->all_errors_by_severity;
    return unless @errors;

    # We may wish to do something with perm v. transient here at some point.
    return $errors[0];
}

sub _errfilter {
    my ($self, $error) = @_;
    return $error if blessed($error);

    $error = {message => $error} unless ref($error);    # when it's a string

    confess "Cannot add validation error which is not blessed nor hashref" unless ref($error) eq 'HASH';
    $error->{message_to_client} = $error->{message} unless exists $error->{message_to_client};
    $error->{set_by}            = caller(1)         unless exists $error->{set_by};
    return $self->error_class->new($error);
}

no Moose::Role;

1;
__END__

=encoding utf-8

=head1 NAME

MooseX::Role::Validatable - Role to add validation to a class

=head1 SYNOPSIS

    package MyClass;

    use Moose;
    with 'MooseX::Role::Validatable';

    has 'attr1' => (is => 'ro', lazy_build => 1);

    sub _build_attr1 {
        my $self = shift;

        # Note initialization errors
        $self->add_errors( {
            message => 'Error: blabla',
            message_to_client => 'Something is wrong!'
        } ) if 'blabla';
    }

    sub _validate_some_other_errors { # _validate_*
        my $self = shift;

        my @errors;
        push @errors, {
            message => '...',
            message_to_client => '...',
        };

        return @errors;
    }

    ## use
    my $ex = MyClass->new();

    if (not $ex->initialized_correctly) {
        my @errors = $ex->all_init_errors();
        ...;    # We didn't even start with good data.
    }

    if (not $ex->confirm_validity) { # does not pass those _validate_*
        my @errors = $ex->all_errors();
        ...;
    }

=head1 DESCRIPTION

MooseX::Role::Validatable is a Moo/Moose role which provides a standard way to add validation to a class.

=head1 METHODS

=head2 initialized_correctly

no error when init the object (no add_errors is called)

=head2 add_errors

    $self->add_errors(...)

add errors on those lazy attributes or sub BUILD

=head2 confirm_validity

run all those B<_validate_*> messages and returns true if no error found.

=head2 all_errors

An array of the errors currently noted. combined with B<all_init_errors> and B<all_validation_errors>

all errors including below methods are instance of error_class, default to L<MooseX::Role::Validatable::Error>

=head2 all_init_errors

all errors on init

=head2 all_validation_errors

all errors on validation

=head2 all_errors_by_severity

order by severity

=head2 primary_validation_error

the first error of B<all_errors_by_severity>

=head2 validation_methods

A list of all validation methods available on this object.
This can be auto-generated from all methods which begin with
"_validate_" which is especially helpful in devleoping new validations.

You may wish to set this list directly on the object, if
you create and validate a lot of static objects.

=head2 error_class

default to L<MooseX::Role::Validatable::Error>, override by

    has '+error_class' => (is => 'ro', default => sub { 'My::Validatable::Error' });

    # or
    ->new(error_class => 'My::Validatable::Error');

=head2 passes_validation

=head2 should_alert

=head1 AUTHOR

Binary.com E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
