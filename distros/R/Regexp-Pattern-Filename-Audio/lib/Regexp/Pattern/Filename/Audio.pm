package Regexp::Pattern::Filename::Audio;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-01'; # DATE
our $DIST = 'Regexp-Pattern-Filename-Audio'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
#use utf8;

use Filename::Audio ();

our %RE;

$RE{filename_audio} = {
    summary => 'Audio filename',
    pat => $Filename::Audio::RE,
    tags => ['anchored'],
    examples => [
        {str=>'foo', matches=>0, summary=>'No extension'},
        {str=>'mp3', matches=>0, summary=>'Not an extension'},
        {str=>'foo.mp3', matches=>1},
        {str=>'foo bar.WAV', matches=>1, summary=>'Case insensitive'},
        {str=>'foo.mp3 is the file', matches=>0, summary=>'Regex is anchored'},
        {str=>'foo.mp4', matches=>0},
    ],
};

1;
# ABSTRACT: Audio filename

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Filename::Audio - Audio filename

=head1 VERSION

This document describes version 0.001 of Regexp::Pattern::Filename::Audio (from Perl distribution Regexp-Pattern-Filename-Audio), released on 2020-04-01.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("Filename::Audio::filename_audio");

=head1 DESCRIPTION

This is a L<Regexp::Pattern> wrapper for L<Filename::Audio>.

=head1 PATTERNS

=over

=item * filename_audio

Audio filename.

Examples:

No extension.

 "foo" =~ re("Filename::Audio::filename_audio");  # doesn't match

Not an extension.

 "mp3" =~ re("Filename::Audio::filename_audio");  # doesn't match

 "foo.mp3" =~ re("Filename::Audio::filename_audio");  # matches

Case insensitive.

 "foo bar.WAV" =~ re("Filename::Audio::filename_audio");  # matches

Regex is anchored.

 "foo.mp3 is the file" =~ re("Filename::Audio::filename_audio");  # doesn't match

 "foo.mp4" =~ re("Filename::Audio::filename_audio");  # doesn't match

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Filename-Audio>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Filename-Audio>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Filename-Audio>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern>

L<Filename::Audio>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
