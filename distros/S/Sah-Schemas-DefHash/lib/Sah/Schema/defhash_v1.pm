package Sah::Schema::defhash_v1;

our $DATE = '2016-07-25'; # DATE
our $VERSION = '1.0.11.1'; # VERSION

our $schema = ['defhash', {
    summary => 'DefHash v1',
    keys => {
        defhash_v => ['int', {req=>1, is=>1}, {}],
    },
}, {}];

1;
# ABSTRACT: DefHash v1

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::defhash_v1 - DefHash v1

=head1 VERSION

This document describes version 1.0.11.1 of Sah::Schema::defhash_v1 (from Perl distribution Sah-Schemas-DefHash), released on 2016-07-25.

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
