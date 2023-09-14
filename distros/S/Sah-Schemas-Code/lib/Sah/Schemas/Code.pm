package Sah::Schemas::Code;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-03'; # DATE
our $DIST = 'Sah-Schemas-Code'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Various schemas related to 'code' type and coderefs

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Code - Various schemas related to 'code' type and coderefs

=head1 VERSION

This document describes version 0.001 of Sah::Schemas::Code (from Perl distribution Sah-Schemas-Code), released on 2023-09-03.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<code_from_str|Sah::Schema::code_from_str>

Coderef from eval\`ed string.

This schema accepts coderef or string which will be eval'ed to coderef. Note
that this means allowing your user to provide arbitrary Perl code for you to
execute! Make sure first and foremost that security-wise this is acceptable in
your case.

By default C<eval()> is performed in the C<main> namespace and without stricture
or warnings. See the parameterized version L<Sah::PSchema::code_from_str> if
you want to customize the C<eval()>.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Code>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Code>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

L<Sah::PSchemas::Code>

=head2 Related Sah schemas from L<Sah::Schemas::Str> distribution

L<Sah::Schema::str_or_code>

L<Sah::Schema::str_or_re_or_code>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Code>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
