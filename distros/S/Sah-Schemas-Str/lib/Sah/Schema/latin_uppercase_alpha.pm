package Sah::Schema::latin_uppercase_alpha;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-06'; # DATE
our $DIST = 'Sah-Schemas-Str'; # DIST
our $VERSION = '0.018'; # VERSION

our $schema = [str => {
    summary => 'String containing only zero or more uppercase Latin letters, i.e. A-Z',
    'x.perl.coerce_rules' => ['From_str::to_upper'],
    match => qr/\A[A-Z]*\z/,

    description => <<'_',

Uppercase letters will be coerced to lowercase.

_
    examples => [
        {value=>'', valid=>1},
        {value=>'Abz', valid=>1, validated_value=>'ABZ'},
        {value=>'foo123', valid=>0, summary=>'Contains numbers'},
    ],

}];

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::latin_uppercase_alpha

=head1 VERSION

This document describes version 0.018 of Sah::Schema::latin_uppercase_alpha (from Perl distribution Sah-Schemas-Str), released on 2024-02-06.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Str>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Str>.

=head1 SEE ALSO

L<Sah::Schema::latin_alpha>

L<Sah::Schema::latin_lowercase_alpha>

L<Sah::Schema::lowercase_str>

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

This software is copyright (c) 2024, 2023, 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Str>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
