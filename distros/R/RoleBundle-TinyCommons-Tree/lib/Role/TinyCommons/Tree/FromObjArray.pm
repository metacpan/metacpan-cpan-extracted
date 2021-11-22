package Role::TinyCommons::Tree::FromObjArray;

use strict;
use Role::Tiny;
use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-07'; # DATE
our $DIST = 'RoleBundle-TinyCommons-Tree'; # DIST
our $VERSION = '0.129'; # VERSION

with 'Role::TinyCommons::Tree::NodeMethods';

BEGIN {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
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

This document describes version 0.129 of Role::TinyCommons::Tree::FromObjArray (from Perl distribution RoleBundle-TinyCommons-Tree), released on 2021-10-07.

=head1 MIXED IN ROLES

L<Role::TinyCommons::Tree::NodeMethods>

=head1 PROVIDED METHODS

=head2 new_from_obj_array($obj_array) => obj

Construct a tree of objects from a nested array of objects C<$obj_array>. The
array must contain the root node object followed by zero or more children node
objects. Each child can be directly followed by an arrayref to specify I<its>
children. Example:

 [$root_node_obj]                                     # if there are no children nodes

 [$root_node_obj, [$child1_obj, $child2_obj]]         # if root node has two children

The above tree can be visualized as follow:

 $root_node_obj
   ├─$child1_obj
   └─$child2_obj

Another example:

 [$root_node_obj, [
   $child1_obj, [$grandchild1_obj, $grandchild2_obj],
   $child2_obj]]                                      # if first child has two children of its own

The above tree can be visualized as follow:

 $root_node_obj
   ├─$child1_obj
   │   ├─$grandchild1_obj
   │   └─$grandchild2_obj
   └─$child2_obj

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

Please visit the project's homepage at L<https://metacpan.org/release/RoleBundle-TinyCommons-Tree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-RoleBundle-TinyCommons-Tree>.

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

This software is copyright (c) 2021, 2020, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=RoleBundle-TinyCommons-Tree>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
