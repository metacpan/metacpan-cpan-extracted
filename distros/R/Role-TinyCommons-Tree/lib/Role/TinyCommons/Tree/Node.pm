package Role::TinyCommons::Tree::Node;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-06'; # DATE
our $DIST = 'Role-TinyCommons-Tree'; # DIST
our $VERSION = '0.125'; # VERSION

use Role::Tiny;

requires 'parent';
requires 'children';

1;
# ABSTRACT: Role for a tree node object

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Tree::Node - Role for a tree node object

=head1 VERSION

This document describes version 0.125 of Role::TinyCommons::Tree::Node (from Perl distribution Role-TinyCommons-Tree), released on 2021-05-06.

=head1 DESCRIPTION

To minimize clash, utility methods are separated into a separate role
L<Role::TinyCommons::Tree::NodeMethods>.

=head1 REQUIRED METHODS

=head2 parent => obj

If you need to build a tree or connect nodes, then the method must accept an
optional argument to set value:

 $obj->parent($parent)

=head2 children => list of obj|arrayref of obj

If you need to build a tree or connect nodes, then the method must accept an
optional argument to set value:

 $obj->children(\@children)

For flexibility, it is allowed to return arrayref or list of children nodes.

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

L<Role::TinyCommons>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
