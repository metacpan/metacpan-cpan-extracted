package Setup::File::Dir;

use strict;
use Setup::File;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-21'; # DATE
our $DIST = 'Setup-File'; # DIST
our $VERSION = '0.240'; # VERSION

use Exporter qw(import);

our @EXPORT_OK = qw(setup_dir);

# now moved to Setup::File

sub setup_dir {
    [501, "Moved to Setup::File"];
}

1;
# ABSTRACT: Setup directory (existence, mode, permission)

__END__

=pod

=encoding UTF-8

=head1 NAME

Setup::File::Dir - Setup directory (existence, mode, permission)

=head1 VERSION

This document describes version 0.240 of Setup::File::Dir (from Perl distribution Setup-File), released on 2023-11-21.

=for Pod::Coverage ^(setup_dir)$

=head1

Moved to

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Setup-File>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Setup-File>.

=head1 SEE ALSO

L<Setup>

L<Setup::File>

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

This software is copyright (c) 2023, 2017, 2015, 2014, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Setup-File>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
