package Sah::Schemas::Str;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-23'; # DATE
our $DIST = 'Sah-Schemas-Str'; # DIST
our $VERSION = '0.013'; # VERSION

1;
# ABSTRACT: Various string schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Str - Various string schemas

=head1 VERSION

This document describes version 0.013 of Sah::Schemas::Str (from Perl distribution Sah-Schemas-Str), released on 2022-09-23.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<hexstr|Sah::Schema::hexstr>

String of bytes in hexadecimal notation, e.g. "ab99" or "CAFE".

Whitespace is allowed and will be removed.


=item * L<latin_alpha|Sah::Schema::latin_alpha>

String containing only zero or more Latin letters, i.e. A-Z or a-z.

=item * L<latin_alphanum|Sah::Schema::latin_alphanum>

String containing only zero or more Latin lettersE<sol>digits, i.e. A-Za-z0-9.

=item * L<latin_letter|Sah::Schema::latin_letter>

A single latin letter, i.e. A-Z or a-z.

=item * L<latin_lowercase_alpha|Sah::Schema::latin_lowercase_alpha>

String containing only zero or more lowercases Latin letters, i.e. a-z.

Uppercase letters will be coerced to lowercase.


=item * L<latin_lowercase_letter|Sah::Schema::latin_lowercase_letter>

A single latin lowercase letter, i.e. a-z.

=item * L<latin_uppercase_alpha|Sah::Schema::latin_uppercase_alpha>

String containing only zero or more uppercase Latin letters, i.e. A-Z.

Uppercase letters will be coerced to lowercase.


=item * L<latin_uppercase_letter|Sah::Schema::latin_uppercase_letter>

A single latin uppercase letter, i.e. A-Z.

=item * L<non_empty_str|Sah::Schema::non_empty_str>

A non-empty string (length E<gt>= 1) (alias for str1).

=item * L<percent_str|Sah::Schema::percent_str>

A number in percent form, e.g. "10.5%".

This schema accepts floating number followed by percent sign. Unlike the
C<percent> schema from L<Sah::Schemas::Float>, The percent sign will not be
removed nor the number be converted to decimal (e.g. 50% to 0.5).


=item * L<str1|Sah::Schema::str1>

A non-empty string (length E<gt>= 1).

=item * L<str_or_aos|Sah::Schema::str_or_aos>

String or array (0+ length) of (defined) string.

=item * L<str_or_aos1|Sah::Schema::str_or_aos1>

String or array (1+ length) of (defined) string.

=item * L<str_or_re|Sah::Schema::str_or_re>

String or regex (if string is of the form `E<sol>...E<sol>`).

Either string or Regexp object is accepted.

If string is of the form of C</.../> or C<qr(...)>, then it will be compiled into
a Regexp object. If the regex pattern inside C</.../> or C<qr(...)> is invalid,
value will be rejected.

Currently, unlike in normal Perl, for the C<qr(...)> form, only parentheses C<(>
and C<)> are allowed as the delimiter.

Currently modifiers C<i>, C<m>, and C<s> after the second C</> are allowed.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Str>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Str>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Str>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
