package Sah::Schema::unix::filename;

our $DATE = '2019-09-11'; # DATE
our $VERSION = '0.005'; # VERSION

our $schema = ["filename::unix" => {
    summary => 'File name (with optional path) on a Unix system',
    description => <<'_',

This is just a convenient alias for filename::unix.

_
}, {}];

1;
# ABSTRACT: File name (with optional path) on a Unix system

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::unix::filename - File name (with optional path) on a Unix system

=head1 VERSION

This document describes version 0.005 of Sah::Schema::unix::filename (from Perl distribution Sah-Schemas-Unix), released on 2019-09-11.

=head1 DESCRIPTION

This is just a convenient alias for filename::unix.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Unix>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Unix>

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
