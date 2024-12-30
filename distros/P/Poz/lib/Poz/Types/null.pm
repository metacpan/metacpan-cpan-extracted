package Poz::Types::null;
use 5.032;
use strict;
use warnings;
use parent 'Poz::Types::scalar';

sub new {
    my ($class, $opts) = @_;
    $opts = $opts || {};
    $opts->{required_error} //= "Not a null";
    $opts->{invalid_type_error} //= "Not a null";
    my $self = $class->SUPER::new($opts);
    return $self;
}

sub rule {
    my ($self, $value) = @_;
    return $self->{required_error} if defined $value;
    return $self->{invalid_type_error} if $value ;
    return;
};

1;

=head1 NAME

Poz::Types::null - Null type validation for Poz::Types

=head1 SYNOPSIS

    use Poz qw/z/;

    my $null_validator = z->null;

    $null_validator->parse(undef); # returns undef
    $null_validator->parse(1); # returns error message

    my $array_with_null_or_number = z->array(z->union(z->null, z->number));
    $array_with_null_or_number->parse([undef, 1]); # returns [undef, 1]
    $array_with_null_or_number->parse([1, 2]); # returns [1, 2]
    $array_with_null_or_number->parse([undef, "a"]); # returns error message

=head1 DESCRIPTION

This module provides a null type validator for Poz::Types. It can be used to validate that a value is C<undef>.

=head1 METHODS

=head2 rule

    my $error = $null_validator->rule($value);

Validates the given value. Returns an error message if the value is not C<undef>, otherwise returns C<undef>.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut
