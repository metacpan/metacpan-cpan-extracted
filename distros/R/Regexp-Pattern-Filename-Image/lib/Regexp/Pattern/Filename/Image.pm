package Regexp::Pattern::Filename::Image;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-31'; # DATE
our $DIST = 'Regexp-Pattern-Filename-Image'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
#use utf8;

use Filename::Image ();

our %RE;

$RE{filename_image} = {
    summary => 'Image filename',
    pat => $Filename::Image::RE,
    tags => ['anchored'],
    examples => [
        {str=>'foo', matches=>0, summary=>'No extension'},
        {str=>'jpg', matches=>0, summary=>'Not an extension'},
        {str=>'foo.jpg', matches=>1},
        {str=>'foo bar.GIF', matches=>1, summary=>'Case insensitive'},
        {str=>'foo.GIF is the file', matches=>0, summary=>'Regex is anchored'},
        {str=>'foo.mp3', matches=>0},
    ],
};

1;
# ABSTRACT: Image filename

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Filename::Image - Image filename

=head1 VERSION

This document describes version 0.002 of Regexp::Pattern::Filename::Image (from Perl distribution Regexp-Pattern-Filename-Image), released on 2020-05-31.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Filename::Image::filename_image");

=head1 DESCRIPTION

This is a L<Regexp::Pattern> wrapper for L<Filename::Image>.

=head1 PATTERNS

=over

=item * filename_image

Image filename.

Examples:

No extension.

 "foo" =~ re("Filename::Image::filename_image");  # DOESN'T MATCH

Not an extension.

 "jpg" =~ re("Filename::Image::filename_image");  # DOESN'T MATCH

Example #3.

 "foo.jpg" =~ re("Filename::Image::filename_image");  # matches

Case insensitive.

 "foo bar.GIF" =~ re("Filename::Image::filename_image");  # matches

Regex is anchored.

 "foo.GIF is the file" =~ re("Filename::Image::filename_image");  # DOESN'T MATCH

Example #6.

 "foo.mp3" =~ re("Filename::Image::filename_image");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Filename-Image>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Filename-Image>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Filename-Image>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Filename::Image>

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
