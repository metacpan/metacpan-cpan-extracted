package Sah::Schema::percent_str;

use strict;

use Regexp::Pattern::Float;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-06'; # DATE
our $DIST = 'Sah-Schemas-Str'; # DIST
our $VERSION = '0.018'; # VERSION

our $schema = [str => {
    summary => 'A number in percent form, e.g. "10.5%"',
    match => qr/\A$Regexp::Pattern::Float::RE{float_decimal}{pat}%\z/,

    description => <<'_',

This schema accepts floating number followed by percent sign. Unlike the
`percent` schema from <pm:Sah::Schemas::Float>, The percent sign will not be
removed nor the number be converted to decimal (e.g. 50% to 0.5).

_
    examples => [
        {value=>'', valid=>0, summary=>'No percent sign'},
        {value=>'1', valid=>0, summary=>'No percent sign'},
        {value=>'1%', valid=>1},
        {value=>'1 %', valid=>0, summary=>'Whitespace before percent sign is currently not allowed'},
        {value=>'-1.23%', valid=>1},
        {value=>'%', valid=>0, summary=>'Percent sign only'},
    ],

}];

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::percent_str

=head1 VERSION

This document describes version 0.018 of Sah::Schema::percent_str (from Perl distribution Sah-Schemas-Str), released on 2024-02-06.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Str>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Str>.

=head1 SEE ALSO

L<Sah::Schema::percent>

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
