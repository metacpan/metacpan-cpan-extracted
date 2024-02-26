package Sah::Schema::hexstr;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-06'; # DATE
our $DIST = 'Sah-Schemas-Str'; # DIST
our $VERSION = '0.018'; # VERSION

our $schema = [str => {
    summary => 'String of bytes in hexadecimal notation, e.g. "ab99" or "CAFE"',
    prefilters => ['Str::remove_whitespace'],
    match => qr/\A(?:[0-9A-Fa-f]{2})*\z/,

    description => <<'_',

Whitespace is allowed and will be removed.

_
    examples => [
        {value=>'', valid=>1},
        {value=>'a0', valid=>1},
        {value=>'A0', valid=>1, summary=>'Uppercase digits are allowed, not coerced to lowercase'},
        {value=>'a0f', valid=>0, summary=>'Odd number of digits (3)'},
        {value=>'a0ff', valid=>1},
        {value=>'a0 ff 61', valid=>1, summary=>'Whitespace will be removed', validated_value=>'a0ff61'},
        {value=>'a0fg', valid=>0, summary=>'Invalid hexdigit (g)'},
        {value=>'a0ff12345678', valid=>1},
    ],

}];

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::hexstr

=head1 VERSION

This document describes version 0.018 of Sah::Schema::hexstr (from Perl distribution Sah-Schemas-Str), released on 2024-02-06.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Str>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Str>.

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
