package TAP::DOM::Entry;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Accessors for TAP::DOM line entries
$TAP::DOM::Entry::VERSION = '1.001';
use 5.006;
use strict;
use warnings;

require TAP::DOM;

use Class::XSAccessor
    chained     => 1,
    constructor => 'new',
    accessors   => [qw( raw
                        type
                        data
                        number
                        severity
                        as_string
                        directive
                        description
                        explanation
                        _children
                     )];

BEGIN {
    no strict 'refs';

    # bitset aware 'is_/has_' accessors
    for my $method (qw( is_plan
                        is_ok
                        is_test
                        is_comment
                        is_unknown
                        is_actual_ok
                        is_version
                        is_pragma
                        is_unplanned
                        is_bailout
                        is_yaml
                        has_skip
                        has_todo
                     ))
    {
            *{$method} = sub {
                    my ($self) = @_;
                    defined $self->{is_has} ? $self->{is_has} & ${"TAP::DOM::".uc($method)} : $self->{$method}
            }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TAP::DOM::Entry - Accessors for TAP::DOM line entries

=head1 DESCRIPTION

All single line entries are blessed to this class providing methods to
get the actual values of C<is_*> and C<has_*> attributes transparently
regardless of their storage as hash entries or bitsets; plus normal
accessors to all other entry fields.

=head1 ACCESSORS & METHODS

=head2 new - constructor

=head2 as_string

=head2 _children

=head2 data

=head2 description

=head2 directive

=head2 explanation

=head2 has_skip

=head2 has_todo

=head2 is_actual_ok

=head2 is_bailout

=head2 is_comment

=head2 is_ok

=head2 is_plan

=head2 is_pragma

=head2 is_test

=head2 is_unknown

=head2 is_unplanned

=head2 is_version

=head2 is_yaml

=head2 number

=head2 raw

=head2 type

=head2 severity

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
