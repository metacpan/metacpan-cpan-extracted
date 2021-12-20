package Regexp::Pattern::Perl::Dist;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-27'; # DATE
our $DIST = 'Regexp-Pattern-Perl'; # DIST
our $VERSION = '0.006'; # VERSION

use strict;
#use warnings;

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

This document describes version 0.006 of Regexp::Pattern::Perl::Dist (from Perl distribution Regexp-Pattern-Perl), released on 2021-07-27.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<Regexp::Pattern::Perl::*> modules.

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
