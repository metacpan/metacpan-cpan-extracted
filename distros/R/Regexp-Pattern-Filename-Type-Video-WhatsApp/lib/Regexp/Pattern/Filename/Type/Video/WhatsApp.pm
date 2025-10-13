package Regexp::Pattern::Filename::Type::Video::WhatsApp;

use 5.010001;
use strict;
use warnings;
#use utf8;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-21'; # DATE
our $DIST = 'Regexp-Pattern-Filename-Type-Video-WhatsApp'; # DIST
our $VERSION = '0.004'; # VERSION

our %RE;

$RE{filename_type_video_whatsapp} = {
    summary => 'Video filename saved by WhatsApp',
    pat => qr/\AVID-[0-9]{8}-WA[0-9]{4,}\.(?:MP4|mp4)\z/,
    tags => ['anchored'],
    examples => [
        {str=>'foo.mp4', matches=>0, summary=>'No pattern'},
        {str=>'IMG-20210922-WA0001.jpg', matches=>0, summary=>'Image, not video'},
        {str=>'VID-20210922-WA0001.mp4', matches=>1},
        {str=>'VID-20210922-WA0001.jpg', matches=>0, summary=>'Wrong extension'},
    ],
};

1;
# ABSTRACT: Video filename saved by WhatsApp

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Filename::Type::Video::WhatsApp - Video filename saved by WhatsApp

=head1 VERSION

This document describes version 0.004 of Regexp::Pattern::Filename::Type::Video::WhatsApp (from Perl distribution Regexp-Pattern-Filename-Type-Video-WhatsApp), released on 2024-12-21.

=head1 SYNOPSIS

Using with L<Regexp::Pattern>:
 
 use Regexp::Pattern; # exports re()
 my $re = re("Filename::Type::Video::WhatsApp::filename_type_video_whatsapp");
 
 # see Regexp::Pattern for more details on how to use with Regexp::Pattern
 
=head1 DESCRIPTION

=head1 REGEXP PATTERNS

=over

=item * filename_type_video_whatsapp

Tags: anchored

Video filename saved by WhatsApp.

Examples:

No pattern.

 "foo.mp4" =~ re("Filename::Type::Video::WhatsApp::filename_type_video_whatsapp");  # DOESN'T MATCH

Image, not video.

 "IMG-20210922-WA0001.jpg" =~ re("Filename::Type::Video::WhatsApp::filename_type_video_whatsapp");  # DOESN'T MATCH

Example #3.

 "VID-20210922-WA0001.mp4" =~ re("Filename::Type::Video::WhatsApp::filename_type_video_whatsapp");  # matches

Wrong extension.

 "VID-20210922-WA0001.jpg" =~ re("Filename::Type::Video::WhatsApp::filename_type_video_whatsapp");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Filename-Type-Video-WhatsApp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Filename-Type-Video-WhatsApp>.

=head1 SEE ALSO

L<Regexp::Pattern::Filename::Type::Image::WhatsApp>

L<Regexp::Pattern::Filename::Type::Media::WhatsApp>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Filename-Type-Video-WhatsApp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
