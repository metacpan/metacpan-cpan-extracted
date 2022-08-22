package Sah::Schemas::Re;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-20'; # DATE
our $DIST = 'Sah-Schemas-Re'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Various regular-expression schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Re - Various regular-expression schemas

=head1 VERSION

This document describes version 0.001 of Sah::Schemas::Re (from Perl distribution Sah-Schemas-Re), released on 2022-08-20.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<re_from_str|Sah::Schema::re_from_str>

Regexp object from string using Regexp::From::String's str_to_re().

This schema accepts Regexp object or string which will be coerced to Regexp object
using L<Regexp::From::String>'s C<str_to_re()> function.

Basically, if string is of the form of C</.../> or C<qr(...)>, then you could
specify metacharacters as if you are writing a literal regexp pattern in Perl.
Otherwise, your string will be C<quotemeta()>-ed first then compiled to Regexp
object. This means in the second case you cannot specify metacharacters.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Re>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Re>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

L<Sah::PSchemas::Re>

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Re>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
