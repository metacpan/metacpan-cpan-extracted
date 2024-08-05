package Sah::SchemaBundle::DataSizeSpeed;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-03'; # DATE
our $DIST = 'Sah-SchemaBundle-DataSizeSpeed'; # DIST
our $VERSION = '0.010'; # VERSION

1;
# ABSTRACT: Sah schemas related to data sizes & speeds (filesize, transfer speed, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::DataSizeSpeed - Sah schemas related to data sizes & speeds (filesize, transfer speed, etc)

=head1 VERSION

This document describes version 0.010 of Sah::SchemaBundle::DataSizeSpeed (from Perl distribution Sah-SchemaBundle-DataSizeSpeed), released on 2024-08-03.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<bandwidth|Sah::Schema::bandwidth>

Data transfer speed.

=item * L<dataquota|Sah::Schema::dataquota>

Data transfer quota.

=item * L<datasize|Sah::Schema::datasize>

Data size.

Float, in bytes.

Can be coerced from string that contains units, e.g.:

 2KB   -> 2048      (kilobyte, 1024-based)
 2mb   -> 2097152   (megabyte, 1024-based)
 1.5K  -> 1536      (kilobyte, 1024-based)
 1.6ki -> 1600      (kibibyte, 1000-based)


=item * L<dataspeed|Sah::Schema::dataspeed>

Data transfer speed.

Float, in bytes/second.

Can be coerced from string that contains units, e.g.:

 1000kbps -> 128000 (kilobits per second, 1024-based)
 2.5 mbit -> 327680 (megabit per second, 1024-based)
 128KB/s  -> 131072 (kilobyte per second, 1024-based)


=item * L<filesize|Sah::Schema::filesize>

File size.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-DataSizeSpeed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-DataSizeSpeed>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-DataSizeSpeed>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
