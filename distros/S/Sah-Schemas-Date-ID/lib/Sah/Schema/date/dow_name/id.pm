package Sah::Schema::date::dow_name::id;

our $DATE = '2019-06-28'; # DATE
our $VERSION = '0.001'; # VERSION

our $schema = [cistr => {
    summary => 'Day-of-week name (abbreviated or full, in Indonesian)',
    in => [
        qw/mg sn sl rb km jm sb/,
        qw/min sen sel rab kam jum sab/,
        qw/minggu senin selasa rabu kamis jumat sabtu/,
    ],
}, {}];

1;

# ABSTRACT: Day-of-week name (abbreviated or full, in Indonesian)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::dow_name::id - Day-of-week name (abbreviated or full, in Indonesian)

=head1 VERSION

This document describes version 0.001 of Sah::Schema::date::dow_name::id (from Perl distribution Sah-Schemas-Date-ID), released on 2019-06-28.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date-ID>

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
