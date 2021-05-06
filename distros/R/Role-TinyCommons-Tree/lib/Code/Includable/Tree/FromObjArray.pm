package Code::Includable::Tree::FromObjArray;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-06'; # DATE
our $DIST = 'Role-TinyCommons-Tree'; # DIST
our $VERSION = '0.125'; # VERSION

use strict;
our $GET_PARENT_METHOD = 'parent';
our $GET_CHILDREN_METHOD = 'children';
our $SET_PARENT_METHOD = 'parent';
our $SET_CHILDREN_METHOD = 'children';

sub __build_subtree {
    my ($parent_node, @obj_array) = ($_[0], @{$_[1] // []});

    my @children;
    while (@obj_array) {
        my $child_node = shift @obj_array;

        # connect child node to its parent
        $child_node->$SET_PARENT_METHOD($parent_node);
        push @children, $child_node;

        # the child has its own children, recurse
        if (@obj_array && ref $obj_array[0] eq 'ARRAY') {
            __build_subtree($child_node, shift(@obj_array));
        }
    }

    # connect parent node to its children
    $parent_node->$SET_CHILDREN_METHOD(\@children);

    # return something useful
    $parent_node;
}

sub new_from_obj_array {
    my $class = shift;
    my $obj_array = shift;

    die "Object array must be a one- or two-element array"
        unless ref $obj_array eq 'ARRAY' && (@$obj_array == 1 || @$obj_array == 2);
    __build_subtree(@$obj_array);
}

1;
# ABSTRACT: Routine to build a tree of objects from a nested array of objects

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Includable::Tree::FromObjArray - Routine to build a tree of objects from a nested array of objects

=head1 VERSION

This document describes version 0.125 of Code::Includable::Tree::FromObjArray (from Perl distribution Role-TinyCommons-Tree), released on 2021-05-06.

=for Pod::Coverage .+

The routines in this module can be imported manually to your tree class/role.
The only requirement is that your tree class supports C<parent> and C<children>
methods as described in L<Role::TinyCommons::Tree::Node>.

The full documentation about the routines is in
L<Role::TinyCommons::Tree::FromObjArray>.

=head1 VARIABLES

=head2 $SET_PARENT_METHOD => str (default: parent)

The method name C<parent> to set parent can actually be customized by (locally)
setting this variable.

=head2 $SET_CHILDREN_METHOD => str (default: children)

The method name C<children> to set children can actually be customized by
(locally) setting this variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Tree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-TreeNode>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Role-TinyCommons-TreeNode/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Tree::FromObjArray> if you want to use the routines in this
module via consuming role.

L<Code::Includable::Tree::FromStruct> if you want to build a tree of objects
from a (nested hash) data structure.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
