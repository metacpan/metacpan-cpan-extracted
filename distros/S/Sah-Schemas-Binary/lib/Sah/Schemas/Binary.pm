package Sah::Schemas::Binary;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-25'; # DATE
our $DIST = 'Sah-Schemas-Binary'; # DIST
our $VERSION = '0.007'; # VERSION

1;
# ABSTRACT: Sah schemas related to binary data

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Binary - Sah schemas related to binary data

=head1 VERSION

This document describes version 0.007 of Sah::Schemas::Binary (from Perl distribution Sah-Schemas-Binary), released on 2022-09-25.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<hexbuf|Sah::Schema::hexbuf>

Binary data encoded in hexdigits, e.g. "fafafa" or "ca fe 00".

Whitespaces are allowed and will be removed.

Note that this schema does not decode the hex encoding for you.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Binary>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Binary>.

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

This software is copyright (c) 2022, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Binary>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
