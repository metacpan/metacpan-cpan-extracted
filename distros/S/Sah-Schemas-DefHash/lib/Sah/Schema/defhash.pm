package Sah::Schema::defhash;

our $DATE = '2016-07-25'; # DATE
our $VERSION = '1.0.11.1'; # VERSION

use strict;
use warnings;

our $schema = [hash => {
    summary => 'DefHash',
    keys => {

        v         => ['float', {req=>1, default=>1}, {}],

        defhash_v => ['int', {req=>1, default=>1}, {}],

        name      => ['str', {
            req=>1,
            clset => [
                {
                    match             => '\A\w+\z',
                    'match.err_level' => 'warn',
                    'match.err_msg'   => 'should be a word',
                },
                {
                    max_len             => 32,
                    'max_len.err_level' => 'warn',
                    'max_len.err_msg'   => 'should be short',
                },
            ],
            'clset.op' => 'and',
        }, {}],

        caption   => ['str', {req=>1}, {}],

        summary   => ['str', {
            req => 1,
            clset => [
                {
                    max_len             => 72,
                    'max_len.err_level' => 'warn',
                    'max_len.err_msg'   => 'should be short',
                },
                {
                    'match'           => qr/\n/,
                    'match.op'        => 'not',
                    'match.err_level' => 'warn',
                    'match.err_msg'   => 'should only be a single-line text',
                },
            ],
            'clset.op' => 'and',
        }, {}],

        description => ['str', {
            req => 1,
        }, {}],

        tags => ['array', {
            of => ['any', {
                req => 1,
                of => [
                    ['str', {req=>1}, {}],
                    ['defhash', {req=>1}, {}],
                ],
            }, {}],
        }, {}],

        default_lang => ['str', {
            req => 1,
            match => '\A[a-z]{2}(_[A-Z]{2})?\z',
        }, {}],

        x => ['any', {
        }, {}],
    },
    'keys.restrict' => 0,
    'allowed_keys_re' => '\A(\.\w+(\.\w+)*|\w+(\.\w+)*(\([a-z]{2}(_[A-Z]{2})?\))?)\z',
}, {}];

# XXX check known attributes (.alt, etc)
# XXX check alt.XXX format (e.g. must be alt\.(lang\.\w+|env_lang\.\w+)
# XXX *.alt.*.X should also be of the same type (e.g. description.alt.lang.foo

1;
# ABSTRACT: DefHash

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::defhash - DefHash

=head1 VERSION

This document describes version 1.0.11.1 of Sah::Schema::defhash (from Perl distribution Sah-Schemas-DefHash), released on 2016-07-25.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-DefHash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-DefHash>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-DefHash>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
