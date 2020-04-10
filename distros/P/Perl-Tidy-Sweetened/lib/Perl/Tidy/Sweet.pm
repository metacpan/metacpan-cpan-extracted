package Perl::Tidy::Sweet;

# ABSTRACT: Tweaks to Perl::Tidy to support some syntactic sugar

use strict;
use warnings;
use base 'Perl::Tidy::Sweetened';

our $VERSION = '1.16';

1;

__END__

=pod

=head1 NAME

Perl::Tidy::Sweet - Tweaks to Perl::Tidy to support some syntactic sugar

=head1 VERSION

version 1.16

=head1 STATUS

=for html <a href="https://travis-ci.org/mvgrimes/Perl-Tidy-Sweetened"><img src="https://travis-ci.org/mvgrimes/Perl-Tidy-Sweetened.svg?branch=master" alt="Build Status"></a>
<a href="https://metacpan.org/pod/Perl::Tidy::Sweetened"><img alt="CPAN version" src="https://badge.fury.io/pl/Perl-Tidy-Sweetened.svg" /></a>

=head1 DESCRIPTION

There are a number of modules on CPAN that allow users to write their classes
with a more "modern" syntax. These tools eliminate the need to shift off
C<$self>, can support type checking and offer other improvements.
Unfortunately, they can break the support tools that the Perl community has
come to rely on. This module attempts to work around those issues.

The module uses
L<Perl::Tidy>'s C<prefilter> and C<postfilter> hooks to support C<method> and
C<func> keywords, including the (possibly multi-line) parameter lists. This is
quite an ugly hack, but it is the recommended method of supporting these new
keywords (see the 2010-12-17 entry in the Perl::Tidy
L<CHANGES|https://metacpan.org/source/SHANCOCK/Perl-Tidy-20120714/CHANGES>
file). B<The resulting formatted code will leave the parameter lists untouched.>

C<Perl::Tidy::Sweetened> attempts to support the syntax outlined in the
following modules, but most of the new syntax styles should work:

=over

=item * p5-mop

=item * Method::Signatures::Simple

=item * MooseX::Method::Signatures

=item * MooseX::Declare

=item * Moops

=item * perl 5.20 signatures

=item * Kavorka

=back

=head1 SEE ALSO

L<Perl::Tidy>

=head1 AUTHOR

Mark Grimes E<lt>mgrimes@cpan.orgE<gt>

=head1 SOURCE

Source repository is at L<https://github.com/mvgrimes/Perl-Tidy-Sweetened>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<http://github.com/mvgrimes/Perl-Tidy-Sweetened/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Mark Grimes E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
