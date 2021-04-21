package Role::TinyCommons::Collection::PickItems::RandomSeek;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-20'; # DATE
our $DIST = 'Role-TinyCommons-Collection'; # DIST
our $VERSION = '0.003'; # VERSION

# enabled by Role::Tiny
#use strict;
#use warnings;

use Role::Tiny;

requires 'get_item_count';
requires 'get_item_at_pos';

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
# ABSTRACT: Provide pick_items() that gets items by random seeking

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Collection::PickItems::RandomSeek - Provide pick_items() that gets items by random seeking

=head1 VERSION

This document describes version 0.003 of Role::TinyCommons::Collection::PickItems::RandomSeek (from Perl distribution Role-TinyCommons-Collection), released on 2021-04-20.

=head1 DESCRIPTION

This role provides pick_items() that picks random items by random seeking. It is
more suitable for huge collections that support C<get_item_at_pos> and an
efficient C<get_item_count>. If your collection does not support those methods,
there's an alternative can use L<Role::TinyCommons::FindItems::Iterator>.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Role-TinyCommons-Collection/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Collection::PickItems> and other
C<Role::TinyCommons::Collection::PickItems::*>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
