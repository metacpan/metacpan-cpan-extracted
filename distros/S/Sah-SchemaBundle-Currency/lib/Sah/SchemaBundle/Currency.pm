package Sah::SchemaBundle::Currency;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-26'; # DATE
our $DIST = 'Sah-SchemaBundle-Currency'; # DIST
our $VERSION = '0.009'; # VERSION

1;
# ABSTRACT: Various Sah currency schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::Currency - Various Sah currency schemas

=head1 VERSION

This document describes version 0.009 of Sah::SchemaBundle::Currency (from Perl distribution Sah-SchemaBundle-Currency), released on 2024-06-26.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<currency::code|Sah::Schema::currency::code>

Currency code.

Accept only current (not retired) codes. Code will be converted to uppercase.


=item * L<currency::pair|Sah::Schema::currency::pair>

Fiat currency pair, e.g. USDE<sol>IDR.

Currency pair is string in the form of I<currency1>/I<currency2>, where
I<currency1> is called the base currency while I<currency2> is the quote (or
price) currency. Both must be known currency codes (e.g. USD, or IDR).

Currency code is checked against L<Locale::Codes::Currency_Codes>.

Will be normalized to uppercase.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Currency>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Currency>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

L<Sah::SchemaBundle::CryptoCurrency>

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

This software is copyright (c) 2024, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Currency>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
