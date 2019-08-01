package Sah::Schema::filesize;

our $DATE = '2019-07-25'; # DATE
our $VERSION = '0.002'; # VERSION

our $schema = ['float' => {
    summary => 'File size',
    description => <<'_',

Float, in bytes.

Can be coerced from string that contains units, e.g.:

    2KB   -> 2048      (kilobyte, 1024-based)
    2mb   -> 2097152   (megabyte, 1024-based)
    1.5K  -> 1536      (kilobyte, 1024-based)
    1.6ki -> 1600      (kibibyte, 1000-based)

_
    min => 0,
    'x.perl.coerce_rules' => ['str_suffix_filesize'],
}, {}];

1;

# ABSTRACT: File size

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::filesize - File size

=head1 VERSION

This document describes version 0.002 of Sah::Schema::filesize (from Perl distribution Sah-Schemas-DataSizeSpeed), released on 2019-07-25.

=head1 DESCRIPTION

Float, in bytes.

Can be coerced from string that contains units, e.g.:

 2KB   -> 2048      (kilobyte, 1024-based)
 2mb   -> 2097152   (megabyte, 1024-based)
 1.5K  -> 1536      (kilobyte, 1024-based)
 1.6ki -> 1600      (kibibyte, 1000-based)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-DataSizeSpeed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-DataSizeSpeed>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-DataSizeSpeed>

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
