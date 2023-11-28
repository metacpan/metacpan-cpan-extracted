## no critic: TestingAndDebugging::RequireUseStrict
package TableDataRole::Spec::GetRowByPos;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-25'; # DATE
our $DIST = 'TableData'; # DIST
our $VERSION = '0.2.6'; # VERSION

### mixins

with 'Role::TinyCommons::Collection::GetItemByPos';

### requires

requires 'get_row_at_pos_hashref';

### aliases, for convenience and clarity

sub get_row_at_pos {
    my $self = shift;
    $self->get_item_at_pos(@_);
}

### implementation

1;
# ABSTRACT: TableData::* that can access a row by position

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Spec::GetRowByPos - TableData::* that can access a row by position

=head1 VERSION

This document describes version 0.2.6 of TableDataRole::Spec::GetRowByPos (from Perl distribution TableData), released on 2023-11-25.

=head1 DESCRIPTION

Mix this role to C<TableData::*> modules that can access rows by position. You
will need to supply an implementation for C<get_item_at_pos>

=head1 MIXED-IN ROLES

L<Role::TinyCommons::Collection::GetItemByPos>

=head1 REQUIRED METHODS

=head2 get_item_at_pos

Mixed in from L<Role::TinyCommons::Collection::GetItemByPos>.

=head2 has_item_at_pos

Mixed in from L<Role::TinyCommons::Collection::GetItemByPos>.

=head2 get_row_at_pos_hashref

=head1 PROVIDED METHODS

=head2 get_row_at_pos

Alias for L</get_item_at_pos>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData>.

=head1 SEE ALSO

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

This software is copyright (c) 2023, 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
