package Sah::Schemas::Phone;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-23'; # DATE
our $DIST = 'Sah-Schemas-Phone'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Schemas related to phones & phone numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Phone - Schemas related to phones & phone numbers

=head1 VERSION

This document describes version 0.001 of Sah::Schemas::Phone (from Perl distribution Sah-Schemas-Phone), released on 2022-09-23.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<phone::num::idn|Sah::Schema::phone::num::idn>

Indonesian phone number, e.g. +628123456789.

This schema accepts Indonesian phone number e.g. +628123456789. If number does
not contain country code, it will be assumed to be '+62' (Indonesian calling
code). Some formatting characters like dashes and spaces are accepted, as long
as it passes L<Number::Phone> formatting. The number will be formatted using
international phone number formatting by the Number::Phone module, e.g. '+62 812
3456 789'.


=item * L<phone::num::int|Sah::Schema::phone::num::int>

International phone number, e.g. +628123456789.

This schema accepts international phone number e.g. +628123456789. Some
formatting characters like dashes and spaces are accepted, as long as it passes
L<Number::Phone> formatting. The number will be formatted using international
phone number formatting by the Number::Phone module, e.g. '+62 812 3456 789'.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Phone>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Phone>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Phone>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
