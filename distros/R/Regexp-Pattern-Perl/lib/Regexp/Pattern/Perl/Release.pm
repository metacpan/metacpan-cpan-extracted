package Regexp::Pattern::Perl::Release;

use strict;
#use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-30'; # DATE
our $DIST = 'Regexp-Pattern-Perl'; # DIST
our $VERSION = '0.007'; # VERSION

our %RE = (
    perl_release_archive_filename => {
        summary => 'Proper filename of a typical distribution release archive (tarball/zip)',
        pat => qr/([A-Za-z_][A-Za-z0-9_]*(?:-[A-Za-z0-9_][A-Za-z0-9_]*)*)-
                  v?([0-9]+(?:\.[0-9]+){0,4}(?:_[0-9]+|-TRIAL)?)
                  \.(tar|tar\.(?:Z|gz|bz2|xz)|zip|rar)/x,
        tags => ['capturing'],
        examples => [
            {str=>'Acme-CPANModulesBundle-Import-PerlAdvent-2000-0.001.tar.gz', gen_args=>{-anchor=>1}, matches=>1},
            {str=>'Acme-CPANModulesBundle-Import-PerlAdvent-2000-v0.001.tar.gz', gen_args=>{-anchor=>1}, matches=>1, summary=>'v prefix before version number allowed'},
            {str=>'0.001.tar.gz', gen_args=>{-anchor=>1}, matches=>0, summary=>'No distribution name'},
            {str=>'Acme-CPANModulesBundle-Import-PerlAdvent-2000.tar.gz', gen_args=>{-anchor=>1}, matches=>1, summary=>'Unfortunately, numeric namespace name gets mistaken as version number'},
            {str=>'Acme-CPANModulesBundle-Import-PerlAdvent.tar.gz', gen_args=>{-anchor=>1}, matches=>0, summary=>'No version number'},
        ],
    },
);

1;
# ABSTRACT: Regexp patterns related to Perl release

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Perl::Release - Regexp patterns related to Perl release

=head1 VERSION

This document describes version 0.007 of Regexp::Pattern::Perl::Release (from Perl distribution Regexp-Pattern-Perl), released on 2022-07-30.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Perl::Release::perl_release_archive_filename");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 REGEXP PATTERNS

=over

=item * perl_release_archive_filename

Proper filename of a typical distribution release archive (tarballE<sol>zip).

Examples:

Example #1.

 "Acme-CPANModulesBundle-Import-PerlAdvent-2000-0.001.tar.gz" =~ re("Perl::Release::perl_release_archive_filename", {-anchor=>1});  # matches

v prefix before version number allowed.

 "Acme-CPANModulesBundle-Import-PerlAdvent-2000-v0.001.tar.gz" =~ re("Perl::Release::perl_release_archive_filename", {-anchor=>1});  # matches

No distribution name.

 "0.001.tar.gz" =~ re("Perl::Release::perl_release_archive_filename", {-anchor=>1});  # DOESN'T MATCH

Unfortunately, numeric namespace name gets mistaken as version number.

 "Acme-CPANModulesBundle-Import-PerlAdvent-2000.tar.gz" =~ re("Perl::Release::perl_release_archive_filename", {-anchor=>1});  # matches

No version number.

 "Acme-CPANModulesBundle-Import-PerlAdvent.tar.gz" =~ re("Perl::Release::perl_release_archive_filename", {-anchor=>1});  # DOESN'T MATCH

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
