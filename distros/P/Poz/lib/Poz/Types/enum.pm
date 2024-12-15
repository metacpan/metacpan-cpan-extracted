package Poz::Types::enum;
use strict;
use warnings;
use parent 'Poz::Types::scalar';

sub new {
    my ($class, $enum) = @_;
    $enum = $enum || [];
    my $opts = {};
    $opts->{required_error} //= "required";
    $opts->{invalid_type_error} //= "Invalid data of enum";
    my $self = $class->SUPER::new($opts);
    $self->{__enum__} = $enum;
    return $self;
}

sub rule {
    my ($self, $value) = @_;
    return $self->{required_error} unless defined $value;
    return $self->{invalid_type_error} unless grep { $_ eq $value } @{$self->{__enum__}};
    return;
}

sub as {
    my ($self, $typename) = @_;
    $self->{__as__} = $typename;
    return $self;
}

sub exclude {
    my ($self, $opts) = @_;
    $opts = $opts || [];
    my $enum = [];
    for my $e (@{$self->{__enum__}}) {
        my $found = 0;
        for my $o (@{$opts}) {
            if ($e eq $o) {
                $found = 1;
                last;
            }
        }
        push @{$enum}, $e unless $found;
    }
    return __PACKAGE__->new($enum);
}

sub extract {
    my ($self, $opts) = @_;
    $opts = $opts || [];
    my $enum = [];
    for my $e (@{$self->{__enum__}}) {
        for my $o (@{$opts}) {
            if ($e eq $o) {
                push @{$enum}, $e;
                last;
            }
        }
    }
    return __PACKAGE__->new($enum);
}

1;

=head1 NAME

Poz::Types::enum - Enum type handling for Poz

=head1 SYNOPSIS

    use Poz qw/z/;

    my $enum = Poz::Types::enum->new(['foo', 'bar', 'baz']);
    $enum->rule('foo'); # Valid
    $enum->rule('qux'); # Throws error

=head1 DESCRIPTION

Poz::Types::enum is a module for handling enumeration types within the Poz framework. It allows you to define a set of valid values and provides methods to validate, exclude, and extract these values.

=head1 METHODS

=head2 new

    my $enum = Poz::Types::enum->new(\@values);

Creates a new enum object with
=head1 AUTHOR

Your Name <your.email@example.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
