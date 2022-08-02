package Sah::PSchema::re_from_str;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-09'; # DATE
our $DIST = 'Sah-PSchemas-Re'; # DIST
our $VERSION = '0.001'; # VERSION

sub meta {
    return +{
        v => 1,
        args => {
            always_quote => {
                summary => 'Passed to Regexp::From::String\'s str_to_re()',
                schema => 'bool*',
            },
            case_insensitive => {
                summary => 'Passed to Regexp::From::String\'s str_to_re()',
                schema => 'bool*',
            },
            anchored => {
                summary => 'Passed to Regexp::From::String\'s str_to_re()',
                schema => 'bool*',
            },
        },
    };
}

sub get_schema {
    my ($class, $args, $merge) = @_;
    return [re => {
        summary => 'Regexp object from string using Regexp::From::String\'s str_to_re()',
        description => <<'_',

This schema accepts Regexp object or string which will be coerced to Regexp object
using <pm:Regexp::From::String>'s `str_to_re()` function.

Basically, if string is of the form of `/.../` or `qr(...)`, then you could
specify metacharacters as if you are writing a literal regexp pattern in Perl.
Otherwise, your string will be `quotemeta()`-ed first then compiled to Regexp
object. This means in the second case you cannot specify metacharacters.

_

        prefilters => [ ['Re::re_from_str'=>($args || {})] ],

        examples => [
        ],
        %{ $merge || {} },
    }];
}

1;
# ABSTRACT: Regexp object from string (parameterized)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::PSchema::re_from_str - Regexp object from string (parameterized)

=head1 VERSION

This document describes version 0.001 of Sah::PSchema::re_from_str (from Perl distribution Sah-PSchemas-Re), released on 2022-07-09.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-PSchemas-Re>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-PSchemas-Re>.

=head1 SEE ALSO

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-PSchemas-Re>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
