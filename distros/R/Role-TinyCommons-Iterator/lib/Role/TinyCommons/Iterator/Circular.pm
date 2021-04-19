package Role::TinyCommons::Iterator::Circular;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-19'; # DATE
our $DIST = 'Role-TinyCommons-Iterator'; # DIST
our $VERSION = '0.002'; # VERSION

use Role::Tiny;
use Role::Tiny::With;

with 'Role::TinyCommons::Iterator::Basic';

### required

### provided

sub get_all_items {
    my $self = shift;

    my $orig_pos = $self->get_iterator_pos;
    my @items;
    while (1) {
        push @items, $self->get_next_item;
        last if $self->get_iterator_pos == $orig_pos;
    }
    @items;
}

sub get_item_count {
    my $self = shift;

    my $orig_pos = $self->get_iterator_pos;
    my $count = 0;
    while (1) {
        $self->get_next_item;
        $count++;
        last if $self->get_iterator_pos == $orig_pos;
    }
    $count;
}

sub each_item {
    my ($self, $coderef) = @_;

    my $orig_pos = $self->get_iterator_pos;
    my $pos = $orig_pos;
    while (1) {
        my $item = $self->get_next_item;
        my $res = $coderef->($item, $self, $pos);
        return 0 unless $res;
        $pos = $self->get_iterator_pos;
        last if $pos == $orig_pos;
    }
    return 1;
}

1;
# ABSTRACT: A cicular iterator

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Iterator::Circular - A cicular iterator

=head1 VERSION

This document describes version 0.002 of Role::TinyCommons::Iterator::Circular (from Perl distribution Role-TinyCommons-Iterator), released on 2021-04-19.

=head1 DESCRIPTION

A circular iterator is just like a L<basic
iterator|Role::TinyCommons::Iterator::Basic> except that it will never run out
of items (unless it is empty). When the last item has been retrieved, the
position will move back to the beginning; C<get_iterator_pos> will return 0
again and C<get_next_item> will retrieve the first item.

=head1 ROLES MIXED IN

L<Role::TinyCommons::Iterator::Basic>

=head1 REQUIRED METHODS

No additional required methods.

=head1 PROVIDED METHODS

=head2 get_all_items

=head2 get_item_count

=head2 each_item

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Iterator>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-Iterator>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Role-TinyCommons-Iterator/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Iterator::Basic>

L<Role::TinyCommons::Iterator::Resettable>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
