package Regexp::Pattern::Filename::Ebook;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-30'; # DATE
our $DIST = 'Regexp-Pattern-Filename-Ebook'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
#use utf8;

use Filename::Ebook ();

our %RE;

my $re = join '|', map {quotemeta} sort keys %Filename::Ebook::SUFFIXES;
$re = qr((?:$re)\z)i;

$RE{filename_ebook} = {
    summary => 'Ebook filename',
    pat => $re,
    tags => ['anchored'],
    examples => [
        {str=>'foo', matches=>0, summary=>'No extension'},
        {str=>'pdf', matches=>0, summary=>'Not an extension'},
        {str=>'foo.pdf', matches=>1},
        {str=>'foo bar.RTF', matches=>1, summary=>'Case insensitive'},
        {str=>'foo.doc is the file', matches=>0, summary=>'Regex is anchored'},
        {str=>'foo.jpg', matches=>0},
    ],
};

1;
# ABSTRACT: Ebook filename

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Filename::Ebook - Ebook filename

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::Filename::Ebook (from Perl distribution Regexp-Pattern-Filename-Ebook), released on 2020-05-30.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Filename::Ebook::filename_ebook");

=head1 DESCRIPTION

This is a L<Regexp::Pattern> wrapper for L<Filename::Ebook>.

=head1 PATTERNS

=over

=item * filename_ebook

Ebook filename.

Examples:

No extension.

 "foo" =~ re("Filename::Ebook::filename_ebook");  # doesn't match

Not an extension.

 "pdf" =~ re("Filename::Ebook::filename_ebook");  # doesn't match

 "foo.pdf" =~ re("Filename::Ebook::filename_ebook");  # matches

Case insensitive.

 "foo bar.RTF" =~ re("Filename::Ebook::filename_ebook");  # matches

Regex is anchored.

 "foo.doc is the file" =~ re("Filename::Ebook::filename_ebook");  # doesn't match

 "foo.jpg" =~ re("Filename::Ebook::filename_ebook");  # doesn't match

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Filename-Ebook>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Filename-Ebook>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Filename-Ebook>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Filename::Ebook>

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
