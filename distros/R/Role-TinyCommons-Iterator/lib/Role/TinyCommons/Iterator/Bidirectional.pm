package Role::TinyCommons::Iterator::Bidirectional;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-19'; # DATE
our $DIST = 'Role-TinyCommons-Iterator'; # DIST
our $VERSION = '0.002'; # VERSION

use Role::Tiny;
use Role::Tiny::With;

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

This document describes version 0.002 of Role::TinyCommons::Iterator::Bidirectional (from Perl distribution Role-TinyCommons-Iterator), released on 2021-04-19.

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

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Iterator>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-Iterator>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Role-TinyCommons-Iterator/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Iterator::Basic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
