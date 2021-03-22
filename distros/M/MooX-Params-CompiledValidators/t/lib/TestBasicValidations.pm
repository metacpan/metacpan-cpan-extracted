package TestBasicValidations;
use Moo;
with qw(
    BasicValidationTemplates
    MooX::Params::CompiledValidators
);

# default, no extra storage
sub validate_customer {
    my $self = shift;
    my $args = $self->validate_parameters(
        { $self->parameter(customer => $self->Required) },
        { @_ }
    );

    return $args;
}

# extra storage into lexical
sub store_validate_customer {
    my $self = shift;
    my $args = $self->validate_parameters(
        { $self->parameter(customer => $self->Required, {store => \my $customer}) },
        { @_ }
    );

    return {
        %$args,
        store_customer => $customer,
    };
}

# use the positional interface
sub validate_positional_customer {
    my $self = shift;
    my $args = $self->validate_positional_parameters(
        [ $self->parameter(customer => $self->Required) ],
        [ @_ ]
    );

    return $args;
}

# extra storage into lexical
sub store_validate_positional_customer {
    my $self = shift;
    my $args = $self->validate_positional_parameters(
        [ $self->parameter(customer => $self->Required, {store => \my $customer}) ],
        [ @_ ]
    );

    return {
        %$args,
        store_customer => $customer,
    };
}

1;

=head1 NAME

TestBasicValidations - Test module for basic validations

=head1 SYNOPSIS

    use Moo;
    extends 'TestBasicValidations';

    use namespace::autoclean;
    1;

=head1 DESCRIPTION

This is a test class. It shows that the C<ValidationTemplates()> can come from a
I<Role> so one can ensure consistent parameter validation. For cases where
interface consistency is more important than validation rules, those templates
can also be local to the class.

=head2 validate_customer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 AUTHOR

(c) MMXXI - Abe Timmerman <abeltje@cpan.org>

=cut
