package Regexp::Pattern::Filename::Media::WhatsApp;

use 5.010001;
use strict;
use warnings;
#use utf8;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-09'; # DATE
our $DIST = 'Regexp-Pattern-Filename-Media-WhatsApp'; # DIST
our $VERSION = '0.004'; # VERSION

our %RE;

$RE{filename_video_whatsapp} = {
    summary => 'Media (video, image) filename saved by WhatsApp',
    pat => qr/\A(?:
                  (?:IMG-[0-9]{8}-WA[0-9]{4,}\.(?:JPE?G|jpe?g))|
                  (?:VID-[0-9]{8}-WA[0-9]{4,}\.(?:MP4|mp4))
              )\z/x,
    tags => ['anchored'],
    examples => [
        {str=>'foo.jpg', matches=>0, summary=>'No pattern'},
        {str=>'foo.mp4', matches=>0, summary=>'No pattern'},
        {str=>'IMG-20210922-WA0001.jpg', matches=>1},
        {str=>'IMG-20210922-WA0001.jpeg', matches=>1},
        {str=>'VID-20210922-WA0001.mp4', matches=>1},
        {str=>'IMG-20210922-WA0001.mp4', matches=>0, summary=>'Wrong extension'},
        {str=>'VID-20210922-WA0001.jpg', matches=>0, summary=>'Wrong extension'},
    ],
};

1;
# ABSTRACT: Media (video, image) filename saved by WhatsApp

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::Filename::Media::WhatsApp - Media (video, image) filename saved by WhatsApp

=head1 VERSION

This document describes version 0.004 of Regexp::Pattern::Filename::Media::WhatsApp (from Perl distribution Regexp-Pattern-Filename-Media-WhatsApp), released on 2022-05-09.

=head1 SYNOPSIS

Using with L<Regexp::Pattern>:
 
 use Regexp::Pattern; # exports re()
 my $re = re("Filename::Media::WhatsApp::filename_video_whatsapp");
 
 # see Regexp::Pattern for more details on how to use with Regexp::Pattern
 
=head1 DESCRIPTION

=head1 REGEXP PATTERNS

=over

=item * filename_video_whatsapp

Tags: anchored

Media (video, image) filename saved by WhatsApp.

Examples:

No pattern.

 "foo.jpg" =~ re("Filename::Media::WhatsApp::filename_video_whatsapp");  # DOESN'T MATCH

No pattern.

 "foo.mp4" =~ re("Filename::Media::WhatsApp::filename_video_whatsapp");  # DOESN'T MATCH

Example #3.

 "IMG-20210922-WA0001.jpg" =~ re("Filename::Media::WhatsApp::filename_video_whatsapp");  # matches

Example #4.

 "IMG-20210922-WA0001.jpeg" =~ re("Filename::Media::WhatsApp::filename_video_whatsapp");  # matches

Example #5.

 "VID-20210922-WA0001.mp4" =~ re("Filename::Media::WhatsApp::filename_video_whatsapp");  # matches

Wrong extension.

 "IMG-20210922-WA0001.mp4" =~ re("Filename::Media::WhatsApp::filename_video_whatsapp");  # DOESN'T MATCH

Wrong extension.

 "VID-20210922-WA0001.jpg" =~ re("Filename::Media::WhatsApp::filename_video_whatsapp");  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-Filename-Media-WhatsApp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-Filename-Media-WhatsApp>.

=head1 SEE ALSO

L<Regexp::Pattern::Filename::Image::WhatsApp>

L<Regexp::Pattern::Filename::Video::WhatsApp>

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-Filename-Media-WhatsApp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
