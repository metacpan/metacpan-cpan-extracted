package Role::TinyCommons::Tree::Node;

use strict;
use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-07'; # DATE
our $DIST = 'RoleBundle-TinyCommons-Tree'; # DIST
our $VERSION = '0.129'; # VERSION

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

This document describes version 0.129 of Role::TinyCommons::Tree::Node (from Perl distribution RoleBundle-TinyCommons-Tree), released on 2021-10-07.

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

Please visit the project's homepage at L<https://metacpan.org/release/RoleBundle-TinyCommons-Tree>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-RoleBundle-TinyCommons-Tree>.

=head1 SEE ALSO

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
