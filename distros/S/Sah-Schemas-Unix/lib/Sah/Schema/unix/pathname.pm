package Sah::Schema::unix::pathname;

our $DATE = '2020-02-11'; # DATE
our $VERSION = '0.010'; # VERSION

our $schema = ["pathname::unix" => {
    summary => 'Path name (filename or dirname) on a Unix system',
    description => <<'_',

This is just a convenient alias for pathname::unix.

_
}, {}];

1;
# ABSTRACT: Path name (filename or dirname) on a Unix system

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::unix::pathname - Path name (filename or dirname) on a Unix system

=head1 VERSION

This document describes version 0.010 of Sah::Schema::unix::pathname (from Perl distribution Sah-Schemas-Unix), released on 2020-02-11.

=head1 DESCRIPTION

This is just a convenient alias for pathname::unix.

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

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
