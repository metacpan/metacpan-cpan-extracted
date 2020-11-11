package Regexp::Pattern::Filename::Media;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-31'; # DATE
our $DIST = 'Regexp-Pattern-Filename-Media'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
#use utf8;

use Filename::Media ();

our %RE;

$RE{filename_media} = {
    summary => 'Media (image/audio/video) filename',
    pat => $Filename::Media::RE,
    tags => ['anchored'],
    examples => [
        {str=>'foo', matches=>0, summary=>'No extension'},
        {str=>'mp4', matches=>0, summary=>'Not an extension'},
        {str=>'foo.jpg', matches=>1},
        {str=>'foo.mp3', matches=>1},
        {str=>'foo.mp4', matches=>1},
        {str=>'foo bar.MKV', matches=>1, summary=>'Case insensitive'},
        {str=>'foo.MKV is the file', matches=>0, summary=>'Regex is anchored'},
        {str=>'foo.txt', matches=>0},
    ],
};

1;
# ABSTRACT: Media (image/audio/video) filename

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Filename::Media - Media (image/audio/video) filename

=head1 VERSION

This document describes version 0.002 of Regexp::Pattern::Filename::Media (from Perl distribution Regexp-Pattern-Filename-Media), released on 2020-05-31.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Filename::Media::filename_media");

=head1 DESCRIPTION

This is a L<Regexp::Pattern> wrapper for L<Filename::Media>.

=head1 PATTERNS

=over

=item * filename_media

Media (imageE<sol>audioE<sol>video) filename.

Examples:

No extension.

 "foo" =~ re("Filename::Media::filename_media");  # DOESN'T MATCH

Not an extension.

 "mp4" =~ re("Filename::Media::filename_media");  # DOESN'T MATCH

Example #3.

 "foo.jpg" =~ re("Filename::Media::filename_media");  # matches

Example #4.

 "foo.mp3" =~ re("Filename::Media::filename_media");  # matches

Example #5.

 "foo.mp4" =~ re("Filename::Media::filename_media");  # matches

Case insensitive.

 "foo bar.MKV" =~ re("Filename::Media::filename_media");  # matches

Regex is anchored.

 "foo.MKV is the file" =~ re("Filename::Media::filename_media");  # DOESN'T MATCH

Example #8.

 "foo.txt" =~ re("Filename::Media::filename_media");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Filename-Media>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Filename-Media>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Filename-Media>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Filename::Media>

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
