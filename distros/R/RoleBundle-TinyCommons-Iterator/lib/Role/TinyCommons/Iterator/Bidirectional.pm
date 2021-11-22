package Role::TinyCommons::Iterator::Bidirectional;

use strict;
use Role::Tiny;
use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-07'; # DATE
our $DIST = 'RoleBundle-TinyCommons-Iterator'; # DIST
our $VERSION = '0.004'; # VERSION

with 'Role::TinyCommons::Iterator::Basic';

### required

requires 'has_prev_item';
requires 'get_prev_item';

### provided

1;
# ABSTRACT: A bidirectional iterator

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Iterator::Bidirectional - A bidirectional iterator

=head1 VERSION

This document describes version 0.004 of Role::TinyCommons::Iterator::Bidirectional (from Perl distribution RoleBundle-TinyCommons-Iterator), released on 2021-10-07.

=head1 DESCRIPTION

A bidirectional iterator is just like a L<basic
iterator|Role::TinyCommons::Iterator::Basic> except that it has
L</get_prev_item> in addition to C<get_next_item> and L</has_prev_item> in
addition to C<get_prev_item>.

=head1 ROLES MIXED IN

L<Role::TinyCommons::Iterator::Basic>

=head1 REQUIRED METHODS

=head2 get_prev_item

=head2 has_prev_item

=head1 PROVIDED METHODS

No additional provided methods.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/RoleBundle-TinyCommons-Iterator>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-RoleBundle-TinyCommons-Iterator>.

=head1 SEE ALSO

L<Role::TinyCommons::Iterator::Basic>

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

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=RoleBundle-TinyCommons-Iterator>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
