package Sah::Schema::filename;

our $DATE = '2018-06-04'; # DATE
our $VERSION = '0.005'; # VERSION

our $schema = [str => {
    summary => 'Filesystem file name',
    'x.perl.coerce_rules' => [
        'str_strip_trailing_slash',
    ],
    'x.completion' => ['filename'],
}, {}];

1;
# ABSTRACT: Filesystem file name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::filename - Filesystem file name

=head1 VERSION

This document describes version 0.005 of Sah::Schema::filename (from Perl distribution Sah-Schemas-Path), released on 2018-06-04.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Path>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Path>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Path>

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
