package Regexp::Pattern::Perl::Dist;

use strict;
#use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-30'; # DATE
our $DIST = 'Regexp-Pattern-Perl'; # DIST
our $VERSION = '0.007'; # VERSION

our %RE = (
    perl_distname => {
        pat => '[A-Za-z_][A-Za-z_0-9]*(?:-[A-Za-z_0-9]+)*',
        examples => [
            {str=>'', anchor=>1, matches=>0},
            {str=>'Foo-Bar', anchor=>1, matches=>1},
            {str=>'Foo-0Bar', anchor=>1, matches=>1},
            {str=>'0Foo-Bar', anchor=>1, matches=>0},
            {str=>'Foo::Bar', anchor=>1, matches=>0},
        ],
    },
);

1;
# ABSTRACT: Regexp patterns related to Perl distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Perl::Dist - Regexp patterns related to Perl distribution

=head1 VERSION

This document describes version 0.007 of Regexp::Pattern::Perl::Dist (from Perl distribution Regexp-Pattern-Perl), released on 2022-07-30.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Perl::Dist::perl_distname");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 REGEXP PATTERNS

=over

=item * perl_distname

Examples:

Example #1.

 "" =~ re("Perl::Dist::perl_distname");  # DOESN'T MATCH

Example #2.

 "Foo-Bar" =~ re("Perl::Dist::perl_distname");  # matches

Example #3.

 "Foo-0Bar" =~ re("Perl::Dist::perl_distname");  # matches

Example #4.

 "0Foo-Bar" =~ re("Perl::Dist::perl_distname");  # DOESN'T MATCH

Example #5.

 "Foo::Bar" =~ re("Perl::Dist::perl_distname");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Perl>.

=head1 SEE ALSO

Other C<Regexp::Pattern::Perl::*> modules.

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
