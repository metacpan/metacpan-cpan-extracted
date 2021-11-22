package Module::Features::Dummy;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-05'; # DATE
our $DIST = 'Module-Features-Dummy'; # DIST
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

our %FEATURES_DEF = (
    v => 2,
    summary => 'Dummy feature set, for testing', # XXX: use this for Abstract
    features => {
        feature1 => {
            summary => 'First feature, a bool',
        },
        feature2 => {
            summary => 'Second feature, a bool, required',
            req => 1,
        },
        feature3 => {
            summary => 'Third feature, a string with range of valid values, optional',
            schema => ['str*', in=>['a','b','c']],
        },
    },
);

1;
# ABSTRACT: Dummy feature set, for testing

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Features::Dummy - Dummy feature set, for testing

=head1 VERSION

This document describes version 0.005 of Module::Features::Dummy (from Perl distribution Module-Features-Dummy), released on 2021-07-05.

=head1 DESCRIPTION

=head1 DEFINED FEATURES

Features defined by this module:

=over

=item * feature1

Optional. Type: bool. First feature, a bool. 

=item * feature2

Required. Type: bool. Second feature, a bool, required. 

=item * feature3

Optional. Type: str. Third feature, a string with range of valid values, optional. 

=back

For more details on module features, see L<Module::Features>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Features-Dummy>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Features-Dummy>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Features-Dummy>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Features>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
