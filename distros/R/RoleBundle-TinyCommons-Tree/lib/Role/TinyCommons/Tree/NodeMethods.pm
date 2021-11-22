package Role::TinyCommons::Tree::NodeMethods;

use strict;
use Role::Tiny;
use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-07'; # DATE
our $DIST = 'RoleBundle-TinyCommons-Tree'; # DIST
our $VERSION = '0.129'; # VERSION

with 'Role::TinyCommons::Tree::Node';

BEGIN {
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    require Code::Includable::Tree::NodeMethods;
    for (grep {/\A[a-z]\w+\z/} keys %Code::Includable::Tree::NodeMethods::) {
        *{$_} = \&{"Code::Includable::Tree::NodeMethods::$_"};
    }
}

1;
# ABSTRACT: Role that provides tree node methods

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Tree::NodeMethods - Role that provides tree node methods

=head1 VERSION

This document describes version 0.129 of Role::TinyCommons::Tree::NodeMethods (from Perl distribution RoleBundle-TinyCommons-Tree), released on 2021-10-07.

=head1 DESCRIPTION

=head1 REQUIRED ROLES

L<Role::TinyCommons::Tree::Node>

=head1 PROVIDED METHODS

=head2 ancestors

Return a list of ancestors, from the direct parent upwards to the root.

=head2 retrieve_parent

Return direct parent. Basically a standard way to call "get parent" method, as
the latter can be customized.

=head2 check

Usage:

 $node->check(\%opts)

Check references in a tree: that all children refers back to the parent.
Options:

=over

=item * recurse => bool

=item * check_root => bool

If set to true, will also check that parent is undef (meaning this node is a
root node).

=back

=head2 descendants

Return a list of descendents, from the direct children, to their children's
children, and so on until all the leaf nodes.

For example, for this tree:

 A
 |-- B
 |   |-- D
 |   |-- E
 |   `-- F
 `-- C
     |-- G
     |   `-- I
     `-- H

the nodes returned for C<< descendants(A) >> would be:

 B C D E F G H I

=head2 descendants_depth_first

Like L</descendants>, except will return in depth-first order. For example,
using the same object in the L</descendants> example, C<<
descendants_depth_first(A) >> will return:

 B D E F C G I H

=head2 first_node

Usage:

 $node->first_node($coderef)

Much like L<List::Util>'s C<first>. Will L</walk> the descendant nodes until the
first coderef returns true, and return that.

=head2 is_first_child

=head2 is_first_child_of_type

=head2 is_last_child

=head2 is_last_child_of_type

=head2 is_nth_child

=head2 is_nth_child_of_type

=head2 is_nth_last_child

=head2 is_nth_last_child_of_type

=head2 is_only_child

=head2 is_only_child_of_type

=head2 next_sibling

Return the sibling node directly after this node.

=head2 next_siblings

Return all the next siblings of this node, from the one directly after to the
last.

=head2 prev_sibling

Return the sibling node directly before this node.

=head2 prev_siblings

Return all the previous siblings of this node, from the first to the one
directly before.

=head2 is_root

=head2 has_min_children(m)

Only select nodes that have at least I<m> direct children.

=head2 has_max_children(n)

Only select nodes that have at most I<n> direct children.

=head2 has_children_between(m, n)

Only select nodes that have between I<m> and I<n> direct children.

=head2 remove

Detach this node from its parent. Also set the parent of this node to undef.

=head2 walk

Usage:

 $node->walk($coderef);

Call C<$coderef> for all descendants (this means the self node is not included).
$coderef will be passed the node.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/RoleBundle-TinyCommons-Tree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-RoleBundle-TinyCommons-Tree>.

=head1 SEE ALSO

L<Code::Includable::Tree::NodeMethods> if you want to use the routines in this
module without consuming a role.

L<Role::TinyCommons::Tree::Node>

L<Role::TinyCommons>

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
