package Role::TinyCommons::Tree::FromObjArray;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-06'; # DATE
our $DIST = 'Role-TinyCommons-Tree'; # DIST
our $VERSION = '0.125'; # VERSION

use Role::Tiny;
use Role::Tiny::With;

with 'Role::TinyCommons::Tree::NodeMethods';

BEGIN {
    no strict 'refs';
    require Code::Includable::Tree::FromObjArray;
    for (grep {/\A[a-z]\w+\z/} keys %Code::Includable::Tree::FromObjArray::) {
        *{$_} = \&{"Code::Includable::Tree::FromObjArray::$_"};
    }
}

1;
# ABSTRACT: Role that provides methods to build a tree of objects from a nested array of objects

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Tree::FromObjArray - Role that provides methods to build a tree of objects from a nested array of objects

=head1 VERSION

This document describes version 0.125 of Role::TinyCommons::Tree::FromObjArray (from Perl distribution Role-TinyCommons-Tree), released on 2021-05-06.

=head1 MIXED IN ROLES

L<Role::TinyCommons::Tree::NodeMethods>

=head1 PROVIDED METHODS

=head2 new_from_obj_array($obj_array) => obj

Construct a tree of objects from a nested array of objects C<$obj_array>. The
array must be in format:

 [$root_node_obj]                                     # if there are no children nodes

 [$root_node_obj, [$child1_obj, $child2_obj]]         # if root node has two children

 [$root_node_obj, [
   $child1_obj, [$grandchild1_obj, $grandchild2_obj],
   $child2_obj]]                                      # if first child has two children of its own

A more complex example (C<$ABC>, C<$DEF>, and so on are all objects):

 [$ABC, [
   $DEF, [$GHI, $JKL],
   $MNO, [$PQR, [$STU]],
   $VWX
  ]]

The above tree can be visualized as follow:

 $ABC
   ├─$DEF
   │   ├─$GHI
   │   └─$JKL
   ├─$MNO
   │   └─$PQR
   │       └─$STU
   └─$VWX

The objects will be connected to each other by calling their C<parent()> and
C<children()> methods. See L<Role::TinyCommons::Tree::Node> for more details.

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

L<Code::Includable::Tree::FromStruct> if you want to use the routines in this
module without consuming a role.

L<Role::TinyCommons::Tree::FromObjArray> if you want to build a tree of objects
from a nested array of objects.

L<Role::TinyCommons::Tree::Node>

L<Role::TinyCommons>

The nested array format is inspired by L<Text::Tree::Indented>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
