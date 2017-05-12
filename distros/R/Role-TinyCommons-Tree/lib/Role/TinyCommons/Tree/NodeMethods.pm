package Role::TinyCommons::Tree::NodeMethods;

our $DATE = '2016-11-23'; # DATE
our $VERSION = '0.11'; # VERSION

use Role::Tiny;
use Role::Tiny::With;

with 'Role::TinyCommons::Tree::Node';

BEGIN {
    no strict 'refs';
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

This document describes version 0.11 of Role::TinyCommons::Tree::NodeMethods (from Perl distribution Role-TinyCommons-Tree), released on 2016-11-23.

=head1 DESCRIPTION

=head1 REQUIRED ROLES

L<Role::TinyCommons::Tree::Node>

=head1 PROVIDED METHODS

=head2 descendants => list

Return children and their children, recursively. See also: C<ancestors>.

=head2 ancestors => list

Return parent and parent's parent, recursively. See also: C<descendants>.

=head2 walk($code)

=head2 first_node($code) => obj|undef

=head2 is_first_child => bool

Return true if node is the first child of its parent.

=head2 is_last_child => bool

Return true if node is the last child of its parent.

=head2 is_only_child => bool

Return true if node is the only child of its parent.

=head2 is_nth_child($n) => bool

Return true if node is the I<n>th child of its parent (starts from 1 not 0, so
C<is_first_child> is equivalent to C<is_nth_child(1)>).

=head2 is_nth_last_child($n) => bool

Return true if node is the I<n>th last child of its parent.

=head2 is_first_child_of_type => bool

Return true if node is the first child (of its type) of its parent. For example,
if the parent's children are ():

 node1(T1) node2(T2) node3(T1) node4(T2)

Both C<node1> and C<node2> are first children of their respective type.

=head2 is_last_child_of_type => bool

=head2 is_only_child_of_type => bool

=head2 is_nth_child_of_type($n) => bool

=head2 is_nth_last_child_of_type($n) => bool

=head2 prev_sibling => obj

=head2 prev_siblings => list

=head2 next_sibling => obj

=head2 next_siblings => list

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Tree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-TreeNode>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Role-TinyCommons-Tree>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Code::Includable::Tree::FromStruct> if you want to use the routines in this
module without consuming a role.

L<Role::TinyCommons::Tree::Node>

L<Role::TinyCommons>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
