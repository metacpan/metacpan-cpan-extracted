# no code
## no critic: TestingAndDebugging::RequireStrict
package Perinci::CmdLine;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-12'; # DATE
our $DIST = 'Perinci-CmdLine'; # DIST
our $VERSION = '2.000.1'; # VERSION

sub new {
    die "Perinci::CmdLine::Lite is empty. Please use of the implementations: Perinci::CmdLine::Plugin, Perinci::CmdLine::Inline, etc";
}

1;
# ABSTRACT: Rinci/Riap-based command-line application framework

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine - Rinci/Riap-based command-line application framework

=head1 VERSION

This document describes version 2.000.1 of Perinci::CmdLine (from Perl distribution Perinci-CmdLine), released on 2024-11-12.

=head1 DESCRIPTION

Perinci::CmdLine is a Rinci/Riap-based command-line application framework. It
has a few implementations; use one depending on your needs.

=over

=item * L<Perinci::CmdLine::Plugin>

=item * L<Perinci::CmdLine::Inline>

=back

Use L<Perinci::CmdLine::Any> to automatically choose one of several
implementations.

=for Pod::Coverage ^(new)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine>.

=head1 SEE ALSO

L<Perinci::CmdLine::Plugin>

L<Perinci::CmdLine::Inline>

L<Perinci::CmdLine::Any>

L<Perinci::CmdLine::Lite> and L<Perinci::CmdLine::Classic>, two older
implementations.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
