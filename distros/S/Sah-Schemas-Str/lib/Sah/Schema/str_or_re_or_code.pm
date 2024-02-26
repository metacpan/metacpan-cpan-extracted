package Sah::Schema::str_or_re_or_code;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-06'; # DATE
our $DIST = 'Sah-Schemas-Str'; # DIST
our $VERSION = '0.018'; # VERSION

our $schema = [any => {
    summary => 'String, or regex (if string is of the form `/.../`), or coderef (if string is in the form of `sub { ... }`)',
    description => <<'_',

Either string, Regexp object, or coderef is accepted.

If string is of the form of `/.../` or `qr(...)`, then it will be compiled into
a Regexp object. If the regex pattern inside `/.../` or `qr(...)` is invalid,
value will be rejected. Currently, unlike in normal Perl, for the `qr(...)`
form, only parentheses `(` and `)` are allowed as the delimiter. Currently
modifiers `i`, `m`, and `s` after the second `/` are allowed.

If string matches the regex `qr/\Asub\s*\{.*\}\z/s`, then it will be eval'ed
into a coderef. If the code fails to compile, the value will be rejected. Note
that this means you accept arbitrary code from the user to execute! Please make
sure first and foremost that this is acceptable in your case. Currently string
is eval'ed in the `main` package, without `use strict` or `use warnings`.

This schema is handy if you want to accept string or regex or coderef from the
command-line.

_
    of => [
        ['str'],
        ['re'],
        ['code'],
    ],

    prefilters => [
        'Str::maybe_convert_to_re',
        'Str::maybe_eval',
    ],

    examples => [
        {value=>'', valid=>1},
        {value=>'a', valid=>1},
        {value=>{}, valid=>0, summary=>'Not a string'},

        # re
        {value=>'//', valid=>1, validated_value=>qr//},
        {value=>'/foo', valid=>1, summary=>'Becomes a string'},
        {value=>'qr(foo', valid=>1, summary=>'Becomes a string'},
        {value=>'qr(foo(', valid=>1, summary=>'Becomes a string'},
        {value=>'qr/foo/', valid=>1, summary=>'Becomes a string'},

        {value=>'/foo.*/', valid=>1, validated_value=>qr/foo.*/},
        {value=>'qr(foo.*)', valid=>1, validated_value=>qr/foo.*/},
        {value=>'/foo/is', valid=>1, validated_value=>qr/foo/is},
        {value=>'qr(foo)is', valid=>1, validated_value=>qr/foo/is},

        {value=>'/foo[/', valid=>0, summary=>'Invalid regex'},

        # code
        {value=>'sub {}', valid=>1, code_validate=>sub { ref($_[0]) eq 'CODE' & !defined($_[0]->()) }},
        {value=>'sub{"foo"}', valid=>1, code_validate=>sub { ref($_[0]) eq 'CODE' && $_[0]->() eq 'foo' }},
        {value=>'sub {', valid=>1, summary=>'Becomes a string'},

        {value=>'sub {1=2}', valid=>0, summary=>'Code does not compile'},
    ],

}];

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::str_or_re_or_code

=head1 VERSION

This document describes version 0.018 of Sah::Schema::str_or_re_or_code (from Perl distribution Sah-Schemas-Str), released on 2024-02-06.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Str>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Str>.

=head1 SEE ALSO

L<Sah::Schema::str_or_re>

L<Sah::Schema::str_or_code>

L<Sah::PSchema::re_from_str>

L<Sah::PSchema::code_from_str>

L<Sah::Schema::re_from_str>

L<Sah::Schema::code_from_str>

L<Regexp::From::String>

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
