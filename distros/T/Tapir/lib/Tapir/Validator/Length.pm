package Tapir::Validator::Length;

use strict;
use warnings;

sub new {
    my ($class, %self) = @_;
    return bless \%self, $class;
}

sub new_from_string {
    my ($class, $string) = @_;
    my ($min, $max) = $string =~ /^\s* (\d*) \s*-\s* (\d*) \s*$/x;
    $min = undef unless length $min;
    $max = undef unless length $max;
    if (! defined $min && ! defined $max) {
        Tapir::InvalidSpec->throw(
            error => "Can't parse length range from '$string' (format '\\d* - \\d*')",
        );
    }
    return $class->new(min => $min, max => $max);
}

sub validate_field {
    my ($self, $field, $desc) = @_;
    $desc ||= defined $field->value ? '"' . $field->value . '"' : 'undef';

    if (! $field->isa('Thrift::Parser::Type::string')) {
        Tapir::InvalidSpec->throw(
            error => "Validator ".ref($self)." is only valid for string",
            key => ref($field)
        );
    }

    my ($min, $max) = @{ $self }{'min', 'max'};
    my $len = length $field->value;
    if (defined $min && $len < $min) {
        Tapir::InvalidArgument->throw(
            error => "Argument $desc is shorter than permitted ($min)",
            key => $field->name, value => $field->value,
        );
    }
    if (defined $max && $len > $max) {
        Tapir::InvalidArgument->throw(
            error => "Argument $desc is longer than permitted ($max)",
            key => $field->name, value => $field->value,
        );
    }
}

sub documentation {
    my $self = shift;
    my ($min, $max) = @{ $self }{'min', 'max'};
    if (defined $min && defined $max) {
        return "Must be between $min and $max characters long";
    }
    if (defined $min) {
        return "Must be at least $min characters long";
    }
    if (defined $max) {
        return "Must be no more than $max characters long";
    }
}

1;
