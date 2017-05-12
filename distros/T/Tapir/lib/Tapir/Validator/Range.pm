package Tapir::Validator::Range;

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
            error => "Can't parse number range from '$string' (format '\\d* - \\d*')",
        );
    }
    return $class->new(min => $min, max => $max);
}

sub validate_field {
    my ($self, $field, $desc) = @_;
    $desc ||= defined $field->value ? '"' . $field->value . '"' : 'undef';

    if (! $field->isa('Thrift::Parser::Type::Number')) {
        Tapir::InvalidSpec->throw(
            error => "Validator ".ref($self)." is only valid for numbers",
            key => ref($field)
        );
    }

    my ($min, $max) = @{ $self }{'min', 'max'};

    if (defined $min && $field->value < $min) {
        Tapir::InvalidArgument->throw(
            error => "Argument $desc is smaller than permitted ($min)",
            key => $field->name, value => $field->value,
        );
    }
    if (defined $max && $field->value > $max) {
        Tapir::InvalidArgument->throw(
            error => "Argument $desc is larger than permitted ($max)",
            key => $field->name, value => $field->value,
        );
    }
}

sub documentation {
    my $self = shift;
    my ($min, $max) = @{ $self }{'min', 'max'};
    if (defined $min && defined $max) {
        return "Must be between $min and $max";
    }
    if (defined $min) {
        return "Must be greater or equal to $min";
    }
    if (defined $max) {
        return "Must be less than or equal to $max";
    }
}

1;
