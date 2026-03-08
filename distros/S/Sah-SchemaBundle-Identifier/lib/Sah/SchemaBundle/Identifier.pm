package Sah::SchemaBundle::Identifier;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-11-11'; # DATE
our $DIST = 'Sah-SchemaBundle-Identifier'; # DIST
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: Sah schemas related to identifiers

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::Identifier - Sah schemas related to identifiers

=head1 VERSION

This document describes version 0.002 of Sah::SchemaBundle::Identifier (from Perl distribution Sah-SchemaBundle-Identifier), released on 2025-11-11.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<identifier|Sah::Schema::identifier>

A string that starts with [A-Za-z_] followed by zero of more [A-Za-z0-9_].

Identifier is an often-used definition for relatively safe names you can put
into file name, tack onto variable name, and so on.


=item * L<identifier127|Sah::Schema::identifier127>

Identifier with a maximum length of 127 characters.

Just like C<identifier>, but limited to 127 characters.


=item * L<identifier15|Sah::Schema::identifier15>

Identifier with a maximum length of 15 characters.

Just like C<identifier>, but limited to 15 characters.


=item * L<identifier255|Sah::Schema::identifier255>

Identifier with a maximum length of 255 characters.

Just like C<identifier>, but limited to 255 characters. Can be used, e.g. for
file names in Unix filesystem.


=item * L<identifier31|Sah::Schema::identifier31>

Identifier with a maximum length of 31 characters.

Just like C<identifier>, but limited to 31 characters.


=item * L<identifier63|Sah::Schema::identifier63>

Identifier with a maximum length of 63 characters.

Just like C<identifier>, but limited to 63 characters.


=item * L<identifier::lc|Sah::Schema::identifier::lc>

A string that starts with [a-z_] followed by zero of more [a-z0-9_].

Just like C<identifier>, but must contain lowercase [a-z] only.


=item * L<identifier::lc127|Sah::Schema::identifier::lc127>

Lowercase Identifier with a maximum length of 127 characters.

Just like C<identifier::lc>, but limited to 127 characters.


=item * L<identifier::lc15|Sah::Schema::identifier::lc15>

Lowercase Identifier with a maximum length of 15 characters.

Just like C<identifier::lc>, but limited to 15 characters.


=item * L<identifier::lc255|Sah::Schema::identifier::lc255>

Lowercase Identifier with a maximum length of 255 characters.

Just like C<identifier::lc>, but limited to 255 characters.


=item * L<identifier::lc31|Sah::Schema::identifier::lc31>

Lowercase Identifier with a maximum length of 31 characters.

Just like C<identifier::lc>, but limited to 31 characters.


=item * L<identifier::lc63|Sah::Schema::identifier::lc63>

Lowercase Identifier with a maximum length of 63 characters.

Just like C<identifier::lc>, but limited to 63 characters.


=item * L<identifier::no_u|Sah::Schema::identifier::no_u>

A string that starts with [a-z] followed by zero of more [a-z0-9].

This is a version of C<identifier> that does not allow underscores, everywhere.


=item * L<identifier::no_u_delim|Sah::Schema::identifier::no_u_delim>

A string that starts with [a-z] followed by zero of more [a-z0-9_] and ends with [a-z0-9].

This is a version of C<identifier> that does not allow underscore delimiters.
Underscore is still allowed in the middle.


=item * L<identifier::uc|Sah::Schema::identifier::uc>

A string that starts with [A-Z_] followed by zero of more [A-Z0-9_].

Just like C<identifier>, but must contain uppercase [A-Z] only.


=item * L<identifier::uc127|Sah::Schema::identifier::uc127>

Uppercase Identifier with a maximum length of 127 characters.

Just like C<identifier::uc>, but limited to 127 characters.


=item * L<identifier::uc15|Sah::Schema::identifier::uc15>

Uppercase Identifier with a maximum length of 15 characters.

Just like C<identifier::uc>, but limited to 15 characters.


=item * L<identifier::uc255|Sah::Schema::identifier::uc255>

Uppercase Identifier with a maximum length of 255 characters.

Just like C<identifier::uc>, but limited to 255 characters.


=item * L<identifier::uc31|Sah::Schema::identifier::uc31>

Uppercase Identifier with a maximum length of 31 characters.

Just like C<identifier::uc>, but limited to 63 characters.


=item * L<identifier::uc63|Sah::Schema::identifier::uc63>

Uppercase Identifier with a maximum length of 63 characters.

Just like C<identifier::uc>, but limited to 63 characters.


=back

=head1 DESCRIPTION

"Identifiers" are often used as safe strings for names.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Identifier>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Identifier>.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Identifier>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
