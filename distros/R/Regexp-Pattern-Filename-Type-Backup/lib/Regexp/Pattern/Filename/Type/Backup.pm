package Regexp::Pattern::Filename::Type::Backup;

use 5.010001;
use strict;
use warnings;
#use utf8;

use Filename::Type::Backup ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-21'; # DATE
our $DIST = 'Regexp-Pattern-Filename-Type-Backup'; # DIST
our $VERSION = '0.004'; # VERSION

our %RE;

my $re = join '|', map {quotemeta} sort keys %Filename::Type::Backup::SUFFIXES;
$re = qr((?:$re)\z)i;

$RE{filename_type_backup} = {
    summary => 'Backup filename',
    pat => $re,
    tags => ['anchored'],
    examples => [
        {str=>'foo', matches=>0, summary=>'No extension'},
        {str=>'gz', matches=>0, summary=>'Not an extension'},
        {str=>'foo~', matches=>1},
        {str=>'foo bar.BAK', matches=>1, summary=>'Case insensitive'},
        {str=>'foo.old is the file', matches=>0, summary=>'Regex is anchored'},
        {str=>'foo.txt', matches=>0},
    ],
};

1;
# ABSTRACT: Backup filename

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Filename::Type::Backup - Backup filename

=head1 VERSION

This document describes version 0.004 of Regexp::Pattern::Filename::Type::Backup (from Perl distribution Regexp-Pattern-Filename-Type-Backup), released on 2024-12-21.

=head1 SYNOPSIS

Using with L<Regexp::Pattern>:
 
 use Regexp::Pattern; # exports re()
 my $re = re("Filename::Type::Backup::filename_type_backup");
 
 # see Regexp::Pattern for more details on how to use with Regexp::Pattern
 
=head1 DESCRIPTION

This is a L<Regexp::Pattern> wrapper for L<Filename::Type::Backup>.

=head1 REGEXP PATTERNS

=over

=item * filename_type_backup

Tags: anchored

Backup filename.

Examples:

No extension.

 "foo" =~ re("Filename::Type::Backup::filename_type_backup");  # DOESN'T MATCH

Not an extension.

 "gz" =~ re("Filename::Type::Backup::filename_type_backup");  # DOESN'T MATCH

Example #3.

 "foo~" =~ re("Filename::Type::Backup::filename_type_backup");  # matches

Case insensitive.

 "foo bar.BAK" =~ re("Filename::Type::Backup::filename_type_backup");  # matches

Regex is anchored.

 "foo.old is the file" =~ re("Filename::Type::Backup::filename_type_backup");  # DOESN'T MATCH

Example #6.

 "foo.txt" =~ re("Filename::Type::Backup::filename_type_backup");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Filename-Type-Backup>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Filename-Type-Backup>.

=head1 SEE ALSO

L<Filename::Type::Backup>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Filename-Type-Backup>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
