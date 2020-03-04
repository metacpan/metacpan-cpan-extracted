package Sah::Schema::sortsub::spec;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-28'; # DATE
our $DIST = 'Sah-Schemas-SortSub'; # DIST
our $VERSION = '0.003'; # VERSION

our $schema = ['str', {
    summary => 'Sort::Sub specification string (name + optional <i,r>)',
    match => qr/\A\w+(?:<[ir]*>)?\z/,
    'x.completion' => ['sortsub_spec'],
    prefilters => ['Str::replace_dashes_with_underscores'],
}, {}];

1;
# ABSTRACT: Sort::Sub specification string (name + optional <i,r>)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::sortsub::spec - Sort::Sub specification string (name + optional <i,r>)

=head1 VERSION

This document describes version 0.003 of Sah::Schema::sortsub::spec (from Perl distribution Sah-Schemas-SortSub), released on 2020-02-28.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-SortSub>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-SortSub>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-SortSub>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
