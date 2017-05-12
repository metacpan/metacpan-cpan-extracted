package Sah::Schema::tabledef::table_def;

use strict;
use warnings;

our $schema = [hash => { # XXX should be 'defhash' later
    summary => 'Table definition',

    # tmp
    _prop => {
        # from defhash
        v => {},
        defhash_v => {},
        name => {},
        summary => {},
        description => {},
        tags => {},
        x => {},

        fields => {},
        pk => {},
    },

    keys => {

        # XXX from defhash
        summary   => [
            'str',
        ],

        # XXX from defhash
        description => [
            'str',
        ],

        # XXX from defhash
        tags => [
            'array',
        ],

        # XXX from defhash
        x => [
            'any',
        ],

        fields => [
            'array*',
            of => ['field_def', {req=>1}, {}],
        ],

        pk => [
            'any*' => {of => ['str*', 'array*']},
            # XXX how to check that if string, is one of fields' key?
            # XXX how to check that if array, its element must all be in fields' keys?
        ],
    },
    'keys.restrict' => 0,

    req_keys => [qw/fields pk/],

    # XXX from defhash
    'allowed_keys_re' => qr/\A\w+(\.\w+)*\z/,
}, {}];

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::tabledef::table_def

=head1 VERSION

This document describes version 1.0.8 of Sah::Schema::tabledef::table_def (from Perl distribution TableDef), released on 2017-03-10.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableDef>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-TableDef>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableDef>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
