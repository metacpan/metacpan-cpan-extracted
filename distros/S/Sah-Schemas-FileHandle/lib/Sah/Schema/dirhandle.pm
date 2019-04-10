package Sah::Schema::dirhandle;

our $DATE = '2019-04-09'; # DATE
our $VERSION = '0.002'; # VERSION

our $schema = ['any', {
    summary => 'Dirhandle',
    'x.perl.coerce_rules' => [
        'validate_dirhandle',
    ],
}, {}];

1;
# ABSTRACT: Dirhandle

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::dirhandle - Dirhandle

=head1 VERSION

This document describes version 0.002 of Sah::Schema::dirhandle (from Perl distribution Sah-Schemas-FileHandle), released on 2019-04-09.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-FileHandle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-FileHandle>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-FileHandle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
