package Regexp::Pattern::YouTube;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-21'; # DATE
our $DIST = 'Regexp-Pattern-YouTube'; # DIST
our $VERSION = '0.005'; # VERSION

our %RE = (
    video_id => {
        summary => 'YouTube video ID',
        pat => qr/[A-Za-z0-9_-]{11}/,
        description => <<'_',

YouTube video ID is an encoding of 64-bit number in a custom base-64 character
set. It's 11 characters long.

Caveats:

* There's no official guarantee that the video ID will always be 11 characters,
  or that the allowed character set will stay the same. From
  <https://groups.google.com/d/msg/youtube-api-gdata/maM-h-zKPZc/PJDlDWv77TEJ>:

  "We don't make any public guarantees about the format for video ids. While
  they're currently 11 character strings that contain letters, numbers and some
  punctuation, I wouldn't recommend hardcoding that into your application
  (unless you have an easy way of changing it in the future)."

* This regex does not check whether a video exists. To do that, you'll need to
  use the YouTube API.

_
        examples => [
            {str=>'aNAtbYSxzuA', gen_args=>{-anchor=>1}, matches=>1},
            {str=>'aNAtbYSxzuA-', gen_args=>{-anchor=>1}, matches=>0, summary=>'Incorrect length'},
            {str=>'aNAtb+SxzuA', gen_args=>{-anchor=>1}, matches=>0, summary=>'Contains invalid character'},
        ],
    },

    channel_id => {
        summary => 'YouTube channel ID',
        pat => qr/[A-Za-z0-9_-]{24}/,
        description => <<'_',

YouTube channel ID is an encoding of 128-bit number using a custom base-64
character set. It's 24 characters long.

Caveats:

* Like with video ID format, there's no official guarantee that the channel ID
  will always be 24 characters, or that the allowed character set will stay the
  same.

* This regex does not check whether a channel exists. To do that, you'll need to
  use the YouTube API.

_
        examples => [
            {str=>'UCq-Fj5jknLsUf-MWSy4_brA', gen_args=>{-anchor=>1}, matches=>1},
            {str=>'UCq-Fj5jknLsUf-MWSy4_brAx', gen_args=>{-anchor=>1}, matches=>0, summary=>'Incorrect length'},
            {str=>'UCq-Fj5jknLsUf+MWSy4_brA', gen_args=>{-anchor=>1}, matches=>0, summary=>'Contains invalid character'},
        ],
    },

    playlist_id => {
        summary => 'YouTube playlist ID',
        pat => qr/[A-Za-z0-9_-]{34}/,
        description => <<'_',

YouTube playlist ID is an encoding of 192-bit number using a custom base-64
character set. It's 34 characters long.

Caveats:

* Like with video and channel ID formats, there's no official guarantee that the
  playlist ID will always be 34 characters, or that the allowed character set
  will stay the same.

* This regex does not check whether a playlist exists. To do that, you'll need
  to use the YouTube API.

_
        examples => [
            {str=>'PL9bw4S5ePsEHQKZ4uTtbNXNQGjjOB8bRk', gen_args=>{-anchor=>1}, matches=>1},
            {str=>'PL9bw4S5ePsEHQKZ4uTtbNXNQGjjOB8bRk-', gen_args=>{-anchor=>1}, matches=>0, summary=>'Incorrect length'},
            {str=>'PL9bw4S5ePsEHQKZ4u+tbNXNQGjjOB8bRk', gen_args=>{-anchor=>1}, matches=>0, summary=>'Contains invalid character'},
        ],
    },
);

1;
# ABSTRACT: Regexp patterns related to YouTube

__END__

=pod

=encoding UTF-8

=head1 NAME

Regexp::Pattern::YouTube - Regexp patterns related to YouTube

=head1 VERSION

This document describes version 0.005 of Regexp::Pattern::YouTube (from Perl distribution Regexp-Pattern-YouTube), released on 2020-08-21.

=head1 SYNOPSIS

 use Regexp::Pattern; # exports re()
 my $re = re("YouTube::channel_id");

=head1 DESCRIPTION

L<Regexp::Pattern> is a convention for organizing reusable regex patterns.

=head1 PATTERNS

=over

=item * channel_id

YouTube channel ID.

YouTube channel ID is an encoding of 128-bit number using a custom base-64
character set. It's 24 characters long.

Caveats:

=over

=item * Like with video ID format, there's no official guarantee that the channel ID
will always be 24 characters, or that the allowed character set will stay the
same.

=item * This regex does not check whether a channel exists. To do that, you'll need to
use the YouTube API.

=back


Examples:

Example #1.

 "UCq-Fj5jknLsUf-MWSy4_brA" =~ re("YouTube::channel_id", {-anchor=>1});  # matches

Incorrect length.

 "UCq-Fj5jknLsUf-MWSy4_brAx" =~ re("YouTube::channel_id", {-anchor=>1});  # DOESN'T MATCH

Contains invalid character.

 "UCq-Fj5jknLsUf+MWSy4_brA" =~ re("YouTube::channel_id", {-anchor=>1});  # DOESN'T MATCH

=item * playlist_id

YouTube playlist ID.

YouTube playlist ID is an encoding of 192-bit number using a custom base-64
character set. It's 34 characters long.

Caveats:

=over

=item * Like with video and channel ID formats, there's no official guarantee that the
playlist ID will always be 34 characters, or that the allowed character set
will stay the same.

=item * This regex does not check whether a playlist exists. To do that, you'll need
to use the YouTube API.

=back


Examples:

Example #1.

 "PL9bw4S5ePsEHQKZ4uTtbNXNQGjjOB8bRk" =~ re("YouTube::playlist_id", {-anchor=>1});  # matches

Incorrect length.

 "PL9bw4S5ePsEHQKZ4uTtbNXNQGjjOB8bRk-" =~ re("YouTube::playlist_id", {-anchor=>1});  # DOESN'T MATCH

Contains invalid character.

 "PL9bw4S5ePsEHQKZ4u+tbNXNQGjjOB8bRk" =~ re("YouTube::playlist_id", {-anchor=>1});  # DOESN'T MATCH

=item * video_id

YouTube video ID.

YouTube video ID is an encoding of 64-bit number in a custom base-64 character
set. It's 11 characters long.

Caveats:

=over

=item * There's no official guarantee that the video ID will always be 11 characters,
or that the allowed character set will stay the same. From
LL<https://groups.google.com/d/msg/youtube-api-gdata/maM-h-zKPZc/PJDlDWv77TEJ>:

"We don't make any public guarantees about the format for video ids. While
they're currently 11 character strings that contain letters, numbers and some
punctuation, I wouldn't recommend hardcoding that into your application
(unless you have an easy way of changing it in the future)."

=item * This regex does not check whether a video exists. To do that, you'll need to
use the YouTube API.

=back


Examples:

Example #1.

 "aNAtbYSxzuA" =~ re("YouTube::video_id", {-anchor=>1});  # matches

Incorrect length.

 "aNAtbYSxzuA-" =~ re("YouTube::video_id", {-anchor=>1});  # DOESN'T MATCH

Contains invalid character.

 "aNAtb+SxzuA" =~ re("YouTube::video_id", {-anchor=>1});  # DOESN'T MATCH

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Regexp-Pattern-YouTube>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Regexp-Pattern-YouTube>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Regexp-Pattern-YouTube>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Regexp::Pattern>

Some utilities related to Regexp::Pattern: L<App::RegexpPatternUtils>, L<rpgrep> from L<App::rpgrep>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
