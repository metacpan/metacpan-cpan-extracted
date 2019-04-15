package Sah::Schema::rinci::meta;

our $DATE = '2019-04-15'; # DATE
our $VERSION = '1.1.88.0'; # VERSION

use 5.010001;
use strict;
use warnings;

our %_dh_props = (
    v => {},
    defhash_v => {},
    name => {},
    caption => {},
    summary => {},
    description => {},
    tags => {},
    default_lang => {},
    x => {},
);

our $schema = [hash => {
    summary => 'Rinci metadata',
    # tmp
    _ver => 1.1, # this has the effect of version checking
    _prop => {
        %_dh_props,

        entity_v => {},
        entity_date => {},
        links => {
            _elem_prop => {
                %_dh_props,

                url => {},
            },
        },
    },
}, {}];

1;
# ABSTRACT: Rinci metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::rinci::meta - Rinci metadata

=head1 VERSION

This document describes version 1.1.88.0 of Sah::Schema::rinci::meta (from Perl distribution Sah-Schemas-Rinci), released on 2019-04-15.

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

This software is copyright (c) 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
