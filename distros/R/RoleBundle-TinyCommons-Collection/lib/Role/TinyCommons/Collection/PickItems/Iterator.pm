package Role::TinyCommons::Collection::PickItems::Iterator;

use strict;
use warnings;
use Role::Tiny;
use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-07'; # DATE
our $DIST = 'RoleBundle-TinyCommons-Collection'; # DIST
our $VERSION = '0.009'; # VERSION

requires 'get_next_item';
requires 'has_next_item';
requires 'reset_iterator';

with 'Role::TinyCommons::Collection::PickItems';

sub pick_items {
    my ($self, %args) = @_;

    my $n = $args{n} || 1;

    my @items;
    my $i = -1;
    $self->reset_iterator;
    while ($self->has_next_item) {
        $i++;
        my $item = $self->get_next_item;
        if (@items < $n) {
            # we haven't reached $num_items, insert item to array in a random
            # position
            splice @items, rand(@items+1), 0, $item;
        } else {
            # we have reached $num_items, just replace an item randomly, using
            # algorithm from Learning Perl, slightly modified
            rand($i+1) < @items and splice @items, rand(@items), 1, $item;
        }
    }
    @items;
}

1;
# ABSTRACT: Provide pick_items() that picks by iterating all items once

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Collection::PickItems::Iterator - Provide pick_items() that picks by iterating all items once

=head1 VERSION

This document describes version 0.009 of Role::TinyCommons::Collection::PickItems::Iterator (from Perl distribution RoleBundle-TinyCommons-Collection), released on 2021-10-07.

=head1 DESCRIPTION

This role provides C<pick_items()> that picks random items by doing a one-time
full scan (or iteration) of a resettable iterator. The algorithm is a modified
form of one that was presented in Learning Perl book.

Note that for a huge collection, this might not be a good idea. If your
collection supports a fast C<get_item_at_pos> and an efficient
C<get_item_count>, you can use L<Role::TinyCommons::FindItems::RandomPos>. If
your collection's items are lines from a filehandle, you can use
L<Role::TinyCommons::FindItems::RandomSeekLines>.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<Role::TinyCommons::Collection::PickItems>

=head1 REQUIRED METHODS

=head2 reset_iterator

=head2 get_next_item

=head2 has_next_item

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/RoleBundle-TinyCommons-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-RoleBundle-TinyCommons-Collection>.

=head1 SEE ALSO

L<Role::TinyCommons::Collection::PickItems> and other
C<Role::TinyCommons::Collection::PickItems::*>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=RoleBundle-TinyCommons-Collection>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
