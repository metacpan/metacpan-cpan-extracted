package Role::TinyCommons::Collection::GetItemByPos;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-20'; # DATE
our $DIST = 'Role-TinyCommons-Collection'; # DIST
our $VERSION = '0.008'; # VERSION

use Role::Tiny;

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

This document describes version 0.008 of Role::TinyCommons::Collection::GetItemByPos (from Perl distribution Role-TinyCommons-Collection), released on 2021-05-20.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Role-TinyCommons-Collection/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Collection::GetItemByKey>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
