package Role::TinyCommons::Collection::GetItemByKey;

use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-16'; # DATE
our $DIST = 'Role-TinyCommons-Collection'; # DIST
our $VERSION = '0.010'; # VERSION

### required methods

requires 'get_item_at_key';
requires 'has_item_at_key';
requires 'get_all_keys';

### provides

# alias for has_item_at_key
sub has_key { my $self = shift; $self->has_item_at_key(@_) }

1;
# ABSTRACT: Locating an item by a key

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Collection::GetItemByKey - Locating an item by a key

=head1 VERSION

This document describes version 0.010 of Role::TinyCommons::Collection::GetItemByKey (from Perl distribution Role-TinyCommons-Collection), released on 2024-01-16.

=head1 SYNOPSIS

=head1 DESCRIPTION

This role is for ordered/mapping collections that support subscripting
operation: locating an item via a single key (an integer like in an array, or a
string like in a hash).

=head1 REQUIRED METHODS

=head2 get_item_at_key

Usage:

 my $item = $obj->get_item_at_key($key); # dies when not found

Return item at key C<$key>. Method must die when there is no item at such key.

=head2 has_item_at_key

Usage:

 my $has_item = $obj->has_item_at_key($key); # => bool

Check whether the collection has item at key C<$key>. In Perl, this is
equivalent to doing C<exists()> on a hash.

=head2 get_all_keys

Usage:

 my @keys = $obj->get_all_keys;

Return all known keys. Note that a specific order is not required.

=head1 PROVIDED METHODS

=head2 has_key

Alias for L</has_item_at_key>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-Collection>.

=head1 SEE ALSO

L<Role::TinyCommons::Collection::GetItemByPos>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-Collection>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
