package Sah::Schemas::DataSizeSpeed;

1;
# ABSTRACT: Sah schemas related to data sizes & speeds (filesize, transfer speed, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::DataSizeSpeed - Sah schemas related to data sizes & speeds (filesize, transfer speed, etc)

=head1 VERSION

This document describes version 0.004 of Sah::Schemas::DataSizeSpeed (from Perl distribution Sah-Schemas-DataSizeSpeed), released on 2019-11-29.

=head1 SAH SCHEMAS

=over

=item * L<filesize|Sah::Schema::filesize>

File size.

Float, in bytes.

Can be coerced from string that contains units, e.g.:

 2KB   -> 2048      (kilobyte, 1024-based)
 2mb   -> 2097152   (megabyte, 1024-based)
 1.5K  -> 1536      (kilobyte, 1024-based)
 1.6ki -> 1600      (kibibyte, 1000-based)


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-DataSizeSpeed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-DataSizeSpeed>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-DataSizeSpeed>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
