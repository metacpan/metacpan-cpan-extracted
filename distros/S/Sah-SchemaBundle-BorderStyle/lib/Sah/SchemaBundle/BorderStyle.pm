package Sah::SchemaBundle::BorderStyle;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-25'; # DATE
our $DIST = 'Sah-SchemaBundle-BorderStyle'; # DIST
our $VERSION = '0.003'; # VERSION

1;
# ABSTRACT: Sah schemas related to BorderStyle

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::BorderStyle - Sah schemas related to BorderStyle

=head1 VERSION

This document describes version 0.003 of Sah::SchemaBundle::BorderStyle (from Perl distribution Sah-SchemaBundle-BorderStyle), released on 2024-02-25.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<perl::borderstyle::modname|Sah::Schema::perl::borderstyle::modname>

Perl module in the BorderStyle::* namespace, without the namespace prefix, e.g. "Test::Labeled".

=item * L<perl::borderstyle::modname_with_optional_args|Sah::Schema::perl::borderstyle::modname_with_optional_args>

Perl module in the BorderStyle::* namespace, without the namespace prefix, with optional args e.g. "Test::CustomChar=char,x".

=back

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-BorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-BorderStyle>.

=head1 SEE ALSO

L<BorderStyle>

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

This software is copyright (c) 2024, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-BorderStyle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
