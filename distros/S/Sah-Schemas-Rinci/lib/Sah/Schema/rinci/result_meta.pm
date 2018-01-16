package Sah::Schema::rinci::result_meta;

our $DATE = '2018-01-14'; # DATE
our $VERSION = '1.1.82.3'; # VERSION

use 5.010001;
use strict;
use warnings;

use Sah::Schema::rinci::meta;

our $schema = [hash => {
    summary => 'Rinci envelope result metadata',

    # tmp
    _ver => 1.1,
    _prop => {
        %Sah::Schema::rinci::meta::_dh_props,

        perm_err => {},
        func => {}, # XXX func.*
        cmdline => {}, # XXX cmdline.*
        logs => {},
        prev => {},
        results => {},
        part_start => {},
        part_len => {},
        len => {},
        stream => {},
    },
}, {}];

1;
# ABSTRACT: Rinci envelope result metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::rinci::result_meta - Rinci envelope result metadata

=head1 VERSION

This document describes version 1.1.82.3 of Sah::Schema::rinci::result_meta (from Perl distribution Sah-Schemas-Rinci), released on 2018-01-14.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Rinci>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Rinci>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Rinci>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
