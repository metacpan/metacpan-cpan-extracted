package Regexp::Pattern::Instagram;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-03-27'; # DATE
our $DIST = 'Regexp-Pattern-Instagram'; # DIST
our $VERSION = '0.001'; # VERSION

our %RE = (
    username => {
        summary => 'Instagram username',
        pat => qr/(?:[A-Za-z0-9_]{1,30}|[A-Za-z0-9_](?:[A-Za-z0-9_]|\.(?!\.)){1,28}[A-Za-z0-9_])/,
        description => <<'MARKDOWN',

Maximum 30 characters. Can contain letters, numbers, underscores, and dots. Dots
cannot appear at the beginning or end, and cannot appear consecutively.

MARKDOWN
        examples => [
            {str=>'perlancar', anchor=>1, matches=>1},
            {str=>'perl ancar', anchor=>1, matches=>0, summary=>"Contains invalid character (space)"},
            {str=>'perl.ancar', anchor=>1, matches=>1},
            {str=>'per.lan.car', anchor=>1, matches=>1},
            {str=>'__perlancar__', anchor=>1, matches=>1},
            {str=>'a234567890b234567890c234567890', anchor=>1, matches=>1},
            {str=>'a234567890b234567890c234567890_', anchor=>1, matches=>0, summary=>"Too long"},
            {str=>'.perlancar', anchor=>1, matches=>0, summary=>"Dot cannot appear at the beginning"},
            {str=>'perlancar.', anchor=>1, matches=>0, summary=>"Dot cannot appear at the end"},
            {str=>'perl..ancar', anchor=>1, matches=>0, summary=>"Dot cannot appear consecutively"},
        ],
    },
);

1;
# ABSTRACT: Regexp patterns related to Instagram

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Instagram - Regexp patterns related to Instagram

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::Instagram (from Perl distribution Regexp-Pattern-Instagram), released on 2025-03-27.

=head1 SYNOPSIS

Using with L<Regexp::Pattern>:
 
 use Regexp::Pattern; # exports re()
 my $re = re("Instagram::username");
 
 # see Regexp::Pattern for more details on how to use with Regexp::Pattern
 
=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 REGEXP PATTERNS

=over

=item * username

Instagram username.

Maximum 30 characters. Can contain letters, numbers, underscores, and dots. Dots
cannot appear at the beginning or end, and cannot appear consecutively.


Examples:

Example #1.

 "perlancar" =~ re("Instagram::username");  # matches

Contains invalid character (space).

 "perl ancar" =~ re("Instagram::username");  # DOESN'T MATCH

Example #3.

 "perl.ancar" =~ re("Instagram::username");  # matches

Example #4.

 "per.lan.car" =~ re("Instagram::username");  # matches

Example #5.

 "__perlancar__" =~ re("Instagram::username");  # matches

Example #6.

 "a234567890b234567890c234567890" =~ re("Instagram::username");  # matches

Too long.

 "a234567890b234567890c234567890_" =~ re("Instagram::username");  # DOESN'T MATCH

Dot cannot appear at the beginning.

 ".perlancar" =~ re("Instagram::username");  # DOESN'T MATCH

Dot cannot appear at the end.

 "perlancar." =~ re("Instagram::username");  # DOESN'T MATCH

Dot cannot appear consecutively.

 "perl..ancar" =~ re("Instagram::username");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Instagram>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Instagram>.

=head1 SEE ALSO

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Instagram>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
