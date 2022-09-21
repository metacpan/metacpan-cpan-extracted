# no code
## no critic: TestingAndDebugging::RequireStrict
package Perinci::Manual;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-22'; # DATE
our $DIST = 'Perinci-Manual'; # DIST
our $VERSION = '0.010'; # VERSION

1;
# ABSTRACT: Extra documentation for Perinci

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Manual - Extra documentation for Perinci

=head1 VERSION

This document describes version 0.010 of Perinci::Manual (from Perl distribution Perinci-Manual), released on 2022-07-22.

=head1 DESCRIPTION

The C<Perinci> namespace contains several separate frameworks (for example:
L<Perinci::Sub::Wrapper>, L<Perinci::CmdLine>), all themed around the L<Rinci>
and L<Riap> specification, and each framework having its own documentation. This
distribution contains additional, mostly cross-framework documentation.

The documentation is organized around the concept of "four types of
documentation". See L<https://documentation.divio.com/> for more details.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Manual>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Manual>.

=head1 SEE ALSO

L<Perinci>

L<Rinci>, L<Riap>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Manual>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
