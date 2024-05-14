package TableDataRole::Util::GetRowByPos;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-14'; # DATE
our $DIST = 'TableDataRoles-Standard'; # DIST
our $VERSION = '0.025'; # VERSION

requires 'reset_iterator';
requires 'has_next_item';
requires 'get_next_item';
requires 'get_next_row_hashref';
with 'TableDataRole::Spec::GetRowByPos';

sub has_item_at_pos {
    my ($self, $index) = @_;
    $self->reset_iterator;
    my $i = 0;
    # XXX implement caching?
    while ($i < $index) {
        die "StopIteration" unless $self->has_next_item;
        $self->get_next_item;
        $i++;
    }
    $self->has_next_item;
}

sub get_item_at_pos {
    my ($self, $index) = @_;
    $self->reset_iterator;
    my $i = 0;
    # XXX implement caching?
    while ($i < $index) {
        die "StopIteration" unless $self->has_next_item;
        $self->get_next_item;
        $i++;
    }
    $self->get_next_item;
}

sub get_row_at_pos_hashref {
    my ($self, $index) = @_;
    $self->reset_iterator;
    my $i = 0;
    # XXX implement caching?
    while ($i < $index) {
        die "StopIteration" unless $self->has_next_item;
        $self->get_next_item;
        $i++;
    }
    $self->get_next_row_hashref;
}

1;
# ABSTRACT: Provide TableDataRole::Spec::GetRowByPos methods using iteration

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Util::GetRowByPos - Provide TableDataRole::Spec::GetRowByPos methods using iteration

=head1 VERSION

This document describes version 0.025 of TableDataRole::Util::GetRowByPos (from Perl distribution TableDataRoles-Standard), released on 2024-05-14.

=head1 SYNOPSIS

 use Role::Tiny ();

 # instantiate a TableData module that does not support TableDataRole::Spec::GetRowByPos
 my $table = TableData::Foo->new(...);

 # add support for TableDataRole::Spec::GetRowByPos
 Role::Tiny->apply_roles_to_object($table, "TableDataRole::Util::GetRowByPos");

=head1 DESCRIPTION

This role provides methods specified by L<TableDataRole::Spec::GetRowByPos>. The
implementation is iteration using the basic TableData interface. It can make any
TableData module support the GetRowByPos interface, but very inefficiently.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<TableDataRole::Spec::GetRowByPos>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableDataRoles-Standard>.

=head1 SEE ALSO

L<TableData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2023, 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
