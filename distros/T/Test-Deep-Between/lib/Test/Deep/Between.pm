package Test::Deep::Between;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.02';

use Test::Deep::Cmp;
use Exporter::Lite;

our @EXPORT = qw(between between_str);

sub between {
    my ($from, $to) = @_;
    __PACKAGE__->new($from, $to);
}

sub between_str {
    my ($from, $to) = @_;
    __PACKAGE__->new($from, $to, 1);
}

sub init {
    my $self = shift;
    my ($from, $to, $is_str) = @_;

    $self->{from} = $from;
    $self->{to} = $to;
    $self->{is_str} = $is_str;

    $self->_is_invalid_range();
}

sub _is_invalid_range {
    my $self = shift;
    if ($self->{is_str}) {
        if ($self->{from} gt $self->{to}) {
            $self->{error_mean} = 'from_value is larger than to_value.';
        }
    }
    else {
        if ($self->{from} > $self->{to}) {
            $self->{error_mean} = 'from_value is larger than to_value.';
        }
    }
}

sub _is_in_range {
    my $self = shift;
    my $got = shift;
    if ($self->{is_str}) {
        return $self->{from} le $got && $got le $self->{to};
    }
    else {
        return $self->{from} <= $got && $got <= $self->{to};
    }
}

sub descend {
    my ($self, $got) = @_;

    if (exists $self->{error_mean}) {
        return 0;
    }

    $self->{error_mean} = '%s is not in %s to %s.';
    return $self->_is_in_range($got);
}

sub diagnostics {
    my ($self, $got) = @_;
    return sprintf $self->{error_mean}, $got, $self->{from}, $self->{to};
}

1;
__END__

=head1 NAME

Test::Deep::Between - Number is the range expected

=head1 VERSION

This document describes Test::Deep::Between version 0.01.

=head1 SYNOPSIS

    use Test::Deep;
    use Test::Deep::Between;

    cmp_deeply $hash_ref, { data => between(0, 100) };

=head1 DESCRIPTION

This module check to got number in range in using Test::Deep.

=head1 INTERFACE

=head2 Functions

=head3 C<< between($from, $to) >>

$expected is in $from to $to.

=head3 C<< between_str($from, $to) >>

$expected is in $from to $to with string compare(le).

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Test::Deep>

=head1 AUTHOR

Makoto Taniwaki E<lt>macopy123@gmail.com E<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Makoto Taniwaki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
