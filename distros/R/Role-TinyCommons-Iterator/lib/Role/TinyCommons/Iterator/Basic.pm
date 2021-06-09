package Role::TinyCommons::Iterator::Basic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-08'; # DATE
our $DIST = 'Role-TinyCommons-Iterator'; # DIST
our $VERSION = '0.003'; # VERSION

use Role::Tiny;

### required

requires 'get_next_item';
requires 'has_next_item';
requires 'get_iterator_pos';

### provided

sub get_coderef_iterator {
    my ($self, $dies) = @_;
    if ($dies) {
        return sub { $self->get_next_item };
    } else {
        return sub { $self->has_next_item ? $self->get_next_item : undef };
    }
}

1;
# ABSTRACT: A basic iterator

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Iterator::Basic - A basic iterator

=head1 VERSION

This document describes version 0.003 of Role::TinyCommons::Iterator::Basic (from Perl distribution Role-TinyCommons-Iterator), released on 2021-06-08.

=head1 SYNOPSIS

In your class:

 package YourClass;
 use Role::Tiny;
 with 'Role::TinyCommons::Iterator::Basic';

 sub new { ... }

 # implement required methods
 sub get_next_item { ... }
 sub try_get_next_item { ... }
 sub has_next_item { ... }

In your class user's code:

 use YourClass;

 my $obj = YourClass->new(...);

 # iterate
 my @items;
 while ($obj->has_next_item) {
     push @items, $obj->get_next_item;
 }

=head1 DESCRIPTION

This role provides a basic iterator that's unidirectional, non-resettable, and
non-circular. For a bidirectional iterator, see
L<Role::TinyCommons::Iterator::Bidirectional>. For a resettable iterator, see
L<Role::TinyCommons::Iterator::Resettable>. For a circular iterator, see
L<Role::TinyCommons::Iterator::Circular>

=head1 REQUIRED METHODS

=head2 get_next_item

Usage:

 while ($obj->has_next_item) {
     push @items, $obj->get_next_item;
 }

Get the next item. Must throw an exception (string based, "StopIteration") if
there is no more item to get. Usually used with L</has_next_item> to check first
if there is stil another item to get.

=head2 has_next_item

Usage:

 while ($obj->has_next_item) {
     push @items, $obj->get_next_item;
 }

Check whether iterator has another item.

=head2 get_iterator_pos

Usage:

 my $pos = $obj->get_iterator_pos;

Return the iterator's current position, which is a non-negative integer. The
first item has the position 0.

=head1 PROVIDED METHODS

=head2 get_coderef_iterator

Usage:

 my $iterator = $obj->get_coderef_iterator($dies); # => coderef

Return a coderef that can be called repeatedly to get items. There are two kinds
of coderef iterator that can be returned. If C<$dies> is set to to true, will
return a code that dies when there is no more item. If C<$dies> is set to false
(the default), will return a coderef that does not die but instead returns
C<undef> when there is no more item. If you have a collection that has an
C<undef> item, you will not be able to tell whether the C<undef> that the
coderef iterator returns is a sign of exhaustion of items or is an actual
C<undef> item.

Basically this method is just a shortcut for:

 if ($dies) {
     return sub { $self->get_next_item };
 } else {
     return sub { $self->has_next_item ? $self->get_next_item :
 }

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Iterator>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-Iterator>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-Iterator>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

This role is loosely based on L<Array::Iterator>, but the method names have been
made with "verb"+"object" naming style to be more verbose and less likely clash
with your other methods. The "StopIteration" name comes from Python.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
