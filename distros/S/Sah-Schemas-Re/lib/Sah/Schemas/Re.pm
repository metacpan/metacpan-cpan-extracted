package Sah::Schemas::Re;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-20'; # DATE
our $DIST = 'Sah-Schemas-Re'; # DIST
our $VERSION = '0.006'; # VERSION

1;
# ABSTRACT: Various regular-expression schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Re - Various regular-expression schemas

=head1 VERSION

This document describes version 0.006 of Sah::Schemas::Re (from Perl distribution Sah-Schemas-Re), released on 2023-12-20.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<obj::re|Sah::Schema::obj::re>

Regexp object.

This schema can be used as a stricter version of the C<re> type. Unlike C<re>,
this schema only accepts C<Regexp> object and not string.


=item * L<re_from_str|Sah::Schema::re_from_str>

Regexp object from string using Regexp::From::String's str_to_re().

This schema accepts Regexp object or string which will be coerced to Regexp object
using L<Regexp::From::String>'s C<str_to_re()> function.

Basically, if string is of the form of C</.../> or C<qr(...)>, then you could
specify metacharacters as if you are writing a literal regexp pattern in Perl.
Otherwise, your string will be C<quotemeta()>-ed first then compiled to Regexp
object. This means in the second case you cannot specify metacharacters.

What's the difference between this schema and C<str_or_re> (from
L<Sah::Schemas::Str>)? Both this schema and C<str_or_re> accept string, but
this schema will still coerce strings not in the form of C</.../> or C<qr(...)> to
regexp object, while C<str_or_re> will leave the string as-is. In other words,
this schema always converts input to Regexp object while C<str_or_re> does not.


=item * L<re_or_code_from_str|Sah::Schema::re_or_code_from_str>

Regex (convertable from string of the form `E<sol>...E<sol>`) or coderef (convertable from string of the form `sub { ... }`).

Either Regexp object or coderef is accepted.

Coercion from string for Regexp is available if string is of the form of C</.../>
or C<qr(...)>; it will be compiled into a Regexp object. If the regex pattern
inside C</.../> or C<qr(...)> is invalid, value will be rejected. Currently,
unlike in normal Perl, for the C<qr(...)> form, only parentheses C<(> and C<)> are
allowed as the delimiter. Currently modifiers C<i>, C<m>, and C<s> after the second
C</> are allowed.

Coercion from string for coderef is available if string matches the regex
C<qr/\Asub\s*\{.*\}\z/s>, then it will be eval'ed into a coderef. If the code
fails to compile, the value will be rejected. Note that this means you accept
arbitrary code from the user to execute! Please make sure first and foremost
that this is acceptable in your case. Currently string is eval'ed in the C<main>
package, without C<use strict> or C<use warnings>.

Unlike the default behavior of the C<re> Sah type, coercion from other string not
in the form of C</.../> or C<qr(...)> is not available. Thus, such values will be
rejected.

This schema is handy if you want to accept regex or coderef from the
command-line.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Re>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Re>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

L<Sah::PSchemas::Re>

L<Sah::Schemas::RegexpPattern>

=head2 Related Sah schemas from L<Sah::Schemas::Str> distribution

L<Sah::Schema::str_or_re>

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

This software is copyright (c) 2023, 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Re>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
