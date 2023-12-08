package Role::TinyCommons::Collection::PickItems::RandomPos;

use Role::Tiny;
use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-26'; # DATE
our $DIST = 'Role-TinyCommons-Collection'; # DIST
our $VERSION = '0.009'; # VERSION

requires 'get_item_count';
requires 'get_item_at_pos';

with 'Role::TinyCommons::Collection::PickItems';

sub pick_items {
    my ($self, %args) = @_;

    my $n = $args{n} || 1;
    my $allow_resampling = defined $args{allow_resampling} ? $args{allow_resampling} : 0;
    my $item_count = $self->get_item_count;

    $n = $item_count if $n > $item_count;

    my @items;
    my %used_pos;
    while (@items < $n) {
        my $pos = int(rand() * $item_count);
        unless ($allow_resampling) {
            next if $used_pos{$pos}++;
        }
        push @items, $self->get_item_at_pos($pos);
    }
    @items;
}

1;
# ABSTRACT: Provide pick_items() that picks items by random positions

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Collection::PickItems::RandomPos - Provide pick_items() that picks items by random positions

=head1 VERSION

This document describes version 0.009 of Role::TinyCommons::Collection::PickItems::RandomPos (from Perl distribution Role-TinyCommons-Collection), released on 2023-08-26.

=head1 DESCRIPTION

This role provides pick_items() that picks random items by position. It is more
suitable for huge collections that support a fast C<get_item_at_pos> (see
L<Role::TinyCommons::Collection::GetItemByPos>) and an efficient
C<get_item_count>, for example when you store your items in a Perl array (e.g.
L<ArrayDataRole::Source::Array>). If your collection does not support those
methods, there's an alternative you can use:
L<Role::TinyCommons::FindItems::Iterator>.

Another alternative using binary search:
L<Role::TinyCommons::Collection::PickItems::RandomSeekLines>, if your items are
lines from a filehandle.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<Role::TinyCommons::Collection::PickItems>

=head1 REQUIRED METHODS

=head2 get_item_at_pos

=head2 get_item_count

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-Collection>.

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
