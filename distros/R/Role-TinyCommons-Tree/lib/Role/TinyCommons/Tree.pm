package Role::TinyCommons::Tree;

our $DATE = '2020-02-24'; # DATE
our $VERSION = '0.122'; # VERSION

1;
# ABSTRACT: Roles related to object tree

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Tree - Roles related to object tree

=head1 VERSION

This document describes version 0.122 of Role::TinyCommons::Tree (from Perl distribution Role-TinyCommons-Tree), released on 2020-02-24.

=head1 DESCRIPTION

This distribution provides several roles you can use to create a tree class. The
roles are designed for maximum reusability and minimum clashes with your
existing class.

To create a tree class, all you need to do is apply the
L<Role::TinyCommons::Tree::Node> role:

 use Role::Tiny::With;
 with 'Role::TinyCommons::Tree::Node';

The Tree::Node common role just requires you to have two methods: C<parent>
(which should return parent node object) and C<children> (which should return a
list or arrayref of children node objects).

Utility methods such as C<descendants>, C<walk>, C<is_first_child> and so on are
separated to L<Role::TinyCommons::Tree::NodeMethods> which you can apply if you
want.

The actual methods in Role::TinyCommons::Tree::NodeMethods are actually
implemented in L<Code::Includable::Tree::NodeMethods>, so you can import them to
your class manually or just call the routines as a normal function call if you
do not want to involve L<Role::Tiny>. See an example of this usage in
L<Data::CSel>.

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

There are some other general purpose tree modules CPAN, for example
L<Tree::Simple> or L<Data::Tree>, but at the time of this writing there isn't a
tree role.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
