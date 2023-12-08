package Role::TinyCommons::Collection::GetItemByPos;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-26'; # DATE
our $DIST = 'Role-TinyCommons-Collection'; # DIST
our $VERSION = '0.009'; # VERSION

### required methods

requires 'get_item_at_pos';
requires 'has_item_at_pos';

1;
# ABSTRACT: Locating an item by an integer position

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Collection::GetItemByPos - Locating an item by an integer position

=head1 VERSION

This document describes version 0.009 of Role::TinyCommons::Collection::GetItemByPos (from Perl distribution Role-TinyCommons-Collection), released on 2023-08-26.

=head1 SYNOPSIS

=head1 DESCRIPTION

This role is for ordered collections that support locating an item via an
integer position (0 is the first, 1 the second and so on). Arrays are example of
such collections. This operation is a more specific type of getting an item by
key (see L<Role::TinyCommons::Collection::GetItemByKey>).

=head1 REQUIRED METHODS

=head2 get_item_at_pos

Usage:

 my $item = $obj->get_item_at_pos($pos); # dies when not found

Return item at position C<$pos> (0-based integer). Method must die when there is
no item at such position.

=head2 has_item_at_pos

Usage:

 my $has_item = $obj->has_item_at_pos($pos); # => bool

Check whether the collection has item at position C<$pos>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-Collection>.

=head1 SEE ALSO

L<Role::TinyCommons::Collection::GetItemByKey>

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-Collection>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
