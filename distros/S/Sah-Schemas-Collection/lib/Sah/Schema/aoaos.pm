package Sah::Schema::aoaos;

our $DATE = '2016-12-09'; # DATE
our $VERSION = '0.001'; # VERSION

our $schema = [array => {
    summary => 'Array of array-of-strings',
    description => <<'_',

Note that for flexibility, the strings are allowed to be undefs.

_
    of => ['aos', {req=>1}, {}],
}, {}];

1;
# ABSTRACT: Array of array-of-strings

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::aoaos - Array of array-of-strings

=head1 VERSION

This document describes version 0.001 of Sah::Schema::aoaos (from Perl distribution Sah-Schemas-Collection), released on 2016-12-09.

=head1 DESCRIPTION

Note that for flexibility, the strings are allowed to be undefs.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Collection>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Collection>

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
