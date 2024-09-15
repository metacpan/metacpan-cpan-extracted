=head1 NAME

StreamFinder::Youtube - Fetch actual raw streamable URLs from YouTube and others.

=head1 AUTHOR

This module is Copyright (C) 2017-2021 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::Youtube;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $video = new StreamFinder::Youtube($ARGV[0]);

	die "Invalid URL or no streams found!\n"  unless ($video);

	my $firstStream = $video->get();

	print "First Stream URL=$firstStream\n";

	my $url = $video->getURL();

	print "Stream URL=$url\n";

	my $videoTitle = $video->getTitle();
	
	print "Title=$videoTitle\n";
	
	my $videoDescription = $video->getTitle('desc');
	
	print "Description=$videoDescription\n";
	
	my $videoID = $video->getID();

	print "Video ID=$videoID\n";
	
	my $artist = $video->{'artist'};

	print "Artist (channel)=$artist\n"  if ($artist);
	
	my $albumartist = $video->{'albumartist'};

	print "Album Artist (Channel URL)=$albumartist\n"  if ($albumartist);
	
	my $icon_url = $video->getIconURL();

	if ($icon_url) {   #SAVE THE ICON TO A TEMP. FILE:

		my ($image_ext, $icon_image) = $video->getIconData();

		if ($icon_image && open IMGOUT, ">/tmp/${videoID}.$image_ext") {

			binmode IMGOUT;

			print IMGOUT $icon_image;

			close IMGOUT;

		}

	}

	my $stream_count = $video->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $video->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::Youtube accepts a valid full YouTube video ID, or page URL on 
youtube, et. al. that the "yt-dlp" program supports, 
and returns the actual stream URL, title, and cover art icon for that video.  
The purpose is that one needs this URL in order to have the option to 
stream the video in one's own choice of media player software rather 
than using their web browser and accepting any / all flash, ads, 
javascript, cookies, trackers, web-bugs, and other crapware that can 
come with that method of play.  The author uses his own custom all-purpose 
media player called "fauxdacious" (his custom hacked version of the 
open-source "audacious" audio player).  "fauxdacious" incorporates this 
module to decode and play youtube.com videos.  This is a submodule of the 
general StreamFinder module.

NOTE:  This module may return either Youtube or non-Youtube videos and streams 
for non-Youtube sites, including videos embedded in IFRAME tags and even 
Rumble.com videos found in some non-Youtube sites (L<StreamFinder::Rumble> 
required).  See the I<-noiframes> and I<-youtubeonly> flags below for limiting 
this feature.  Also note:  these videos, etc. are handled here and not 
by L<StreamFinder::Anystream>.

NOTE:  Streamfinder now strongly recommends using yt-dlp over youtube-dl for 
extracting streams, and it is now the default app. used.

Depends:  

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>, 
and the separate application program:  yt-dlp, or a compatable program 
such as youtube-dl.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-debug> [ => 0|1|2 ]] 
[, I<-secure> [ => 0|1 ]] 
[, I<-fast> [ => 0|1 ]] 
[, I<-format> => "youtube-dl format specification" ] 
[, I<-format-fallback> => "youtube-dl format specification (2nd try)" ] 
[, I<-formatonly> [ => 0|1 ]] [, I<-noiframes> [ => 0|1 ]] 
[, I<-youtubeonly> [ => 0|1 ]] 
[, I<-user-agent> => "user-agent string"] 
[, I<-userid> => "youtube-user-id", I<-userpw> => "password"] 
[, I<-youtube-dl> => "youtube-dl program"] 
[, I<-youtube-dl-args> => "youtube-dl arguments"] 
[, I<-youtube-dl-add-args> => "youtube-dl additional arguments"])

Accepts a youtube.com video ID, or any full URL that yt-dlp (youtube-dl) 
supports and creates and returns a new video object, or I<undef> if the URL 
is not a youtube-supported video URL or no streams are found.  The URL can 
be the full URL, 
ie. https://www.youtube.com/watch?v=B<video-id>, a user or channel URL, 
ie. https://www.youtube.com/channel/B<channel-id> or 
https://www.youtube.com/user/B<user-id>. or just B<video-id> 
(if the site is www.youtube.com, since YouTube has multiple sites).
If a I<channel-id>, I<user-id>, or a Youtube channel/user URL is 
given, then the first (latest) video uploaded to that channel will be 
returned.  Note:  Some users and channels have a "featured" video (shown 
with a larger thumbnail at the top) or multiple groupings of videos, but 
the "first" video returned will normally be from the "Uploads" group.  
Channels and users' urls must currently be specified as full URLs, as 
just specifying an ID will be interpreted as a specific B<video-id>!

If I<-format> is specified, it should be a valid "I<youtube-dl -f>" format 
string (see the youtube-dl manpage for details).  Examples:  
"I<mp4[height<=720]/best[height<=720]>" which limits videos to 720p, or 
"bestaudio" to download only audio streams.
Default is "B<best>", but if no streams are found, it then tries all, 
unless I<-formatonly> is specified.

If I<-format-fallback> is specified, it should be a valid 
"I<youtube-dl -f>" format string (see the yt-dlp manpage for details), and 
will be used if no streams matching the I<-format> are found.  
Default is "B<bestaudio>".

If I<-formatonly> is specified (set to 1 (true)), then if no streams match 
the specified I<-format> argument (default "I<best>"), then if 
I<-format-fallback> is specified, that will be tried, otherwise, no streams 
will be returned.  Otherwise (if I<-formatonly> is unspecified or false, 
yt-dlp is called again with either the -F I<-format-fallback> 
(if specified) or else, no format (I<-f>) argument (match any stream we 
can find).  Default is 0 (false / unset).

If I<-formats_by_url> is specified, it should be a valid hash-ref. of url 
patterns to match (keys) and valid "I<youtube-dl -f>" format strings.  
This allows for overriding the I<-format> option for URLs (ie. certain 
non-Youtube ones that provide different formats), particularly useful 
when I<-formatonly> is also specified.

If I<-fast> is specified (set to 1 (true)), a separate probe of the 
page to fetch the video's title and artist is skipped.  This is useful 
if you know the video is NOT a YouTube video or you don't care about 
the artist (youtube channel's owner), artist icon, fields, etc.  
Default is 0 (false / unset).

If I<-noiframes> is specified (set to 1 (true)), then only 
process actual video URLs, not search the page for an iframe containing 
a video URL (a new feature with v0.47).  This is used primarily internally 
to prevent possible recursion when StreamFinder::YouTube finds an iframe 
containing a potential video stream URL and creates a new StreamFinder object 
to find any streams in that URL (which can then call StreamFinder::Youtube 
again on that URL to find the stream).  Default is 0 (false / unset) - search 
for StreamFinder-searchable URLs in an iframe, if the page is HTML and not an 
actual video URL.

I<-youtubeonly> - Some non-Youtube pages have embedded Rumble (Rumble.com) 
videos embedded in them and since StreamFinder::Youtube is somewhat of a 
"catchall" (for videos), and we (the Author) prefer the less-woke Rumble to 
Youtube (which has major censorship issues), we search for embedded Rumble 
videos here, as opposed to L<StreamFinder::Rumble> or 
L<StreamFinder::AnyStream>, and, upon finding one, we return that rather than 
continuing the search for Youtube videos.  To NOT do this (consider only 
embedded Youtube videos), specify this / set it to 1 (true).  
Default 0 (false) - accept Rumble (or other non-Youtube) videos, if found 
first.  NOTE:  This option is effectively set (true) if I<-noiframes> is set!

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  
If 1 then only secure ("https://") streams will be returned.  Default for 
I<-secure> is 0 (false) - return all streams (http and https).

The optional I<-user-agent> argument can specify a specific user-agent string 
to send to yt-dlp's optional "I<--user-agent>" argument.  NOTE:  This is 
completely separate from the I<-agent> option used by some other StreamFinder 
modules for fetching pages and streams from their respective sites, as that 
argument is used by LWP::UserAgent (along with some other options), and is NOT 
passed to yt-dlp, though they represent the same kind of user-agent string! 
Default is I<-none-> (yt-dlp or the alternate program may use it's 
own default).

The optional I<-userid> and I<-userpw> arguments allow specifying a Youtube 
login (for fetching videos, ie. paid ones that require one).  
Defaults are I<-none-> (no userid or password specified).

The optional I<-youtube-dl> argument allows specifying an alternate stream-
parser program in lieu of "yt-dlp", such as "youtube-dl" 
(Default:  "I<yt-dlp>").  Note:  StreamFinder recommends sticking with yt-dlp, 
as it has been known to work when youtube-dl fails, and is known for quicker 
fixing of issues, as Youtube continues to throw up additional roadblocks to 
alternate viewing methods.  If the program is not in the user's 
executable I<PATH>, the full path can be included with the program name here.

The optional I<-youtube-dl-args> argument allows you to change the arguments 
to be passed to the external yt-dlp (youtube-dl or , etc.) program.  NOTE:  
Unless this program changes it's valid arguments or you select an alternate 
program that requires slightly different arguments, you should NOT use this 
argument, as the DEFAULT is:  
"I<--get-url --get-format --get-thumbnail --get-title --get-description --get-id>", 
which are the I<currently> required arguments for this module to function 
properly!  Instead, if you wish to include additional arguments, you should 
use the I<-youtube-dl-add-args> option to append them to this required list, 
see below:  Also note that the I<-f format> argument should NOT be specified 
either here or below as the I<-format> option provides this argument!

The optional I<-youtube-dl-add-args> argument allows you to add additional 
arguments to be passed to the external yt-dlp (youtube-dl or , etc.) program.  
See both the I<-youtube-dl-args> argument description and the manpage for 
yt-dlp, youtube-dl or whatever alternative external program you use to extract 
video streams for valid arguments for possible inclusion here.  

DEFAULT I<-none-> (no additional arguments).

The optional I<-youtube-site> argument allows specifying a different default 
Youtube site if only an video-ID is provided or an embedded video in an 
iframe doesn't specify a specific Youtube site.

DEFAULT "I<https://www.youtube.com>".

Additional (general StreamFinder) options:

I<-log> => "I<logfile>"

Specify path to a log file.  If a valid and writable file is specified, A 
line will be appended to this file every time one or more streams is 
successfully fetched for a url.

DEFAULT I<-none-> (no logging).

I<-logfmt> specifies a format string for lines written to the log file.

DEFAULT "I<[time] [url] - [site]: [title] ([total])>".  

The valid field I<[variables]> are:  [stream]: The url of the first/best 
stream found.  [site]:  The site name (Youtube - OR the site name of the 
embedded URL in the first iframe, if found - see I<-noiframes> option above 
to prevent this feature).  [url]:  The url searched for streams.  [time]: Perl 
timestamp when the line was logged.  [title], [artist], [album], 
[description], [year], [genre], [total], [albumartist]:  The corresponding 
field data returned (or "I<-na->", if no value).

=item $video->B<get>()

Returns an array of strings representing all stream URLs found.

=item $video->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  

Current options are:  I<"random">, I<"nopls">, and I<"noplaylists">.  
By default, the first ("best"?) stream is returned.  If I<"random"> is 
specified, then a random one is selected from the list of streams found.  
If I<"nopls"> is specified, and the stream to be returned is a ".pls" playlist, 
it is first fetched and the first entry (or a random entry if I<"random"> is 
specified) is returned.  This is needed by Fauxdacious Mediaplayer.
If I<"noplaylists"> is specified, and the stream to be returned is a 
"playlist" (either .pls or .m3u? extension), it is first fetched and the first 
entry (or a random entry if I<"random"> is specified) in the playlist 
is returned.

=item $video->B<count>()

Returns the number of streams found for the video.

=item $video->B<getID>()

Returns the video's YouTube ID (alphanumeric+some special characters).

=item $video->B<getTitle>(['desc'])

Returns the station's title, or (long description).  

=item $video->B<getIconURL>(['artist'])

Returns the URL for the video's "cover art" icon image, if any.
If B<'artist'> is specified, the channel artist's icon url is returned, 
if any.  NOTE:  The B<'artist'> option will return an empty string if 
the B<-fast> option is used.

=item $video->B<getIconData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.
If B<'artist'> is specified, the channel artist's icon data is returned, 
if any.  NOTE:  The B<'artist'> option will return an empty string if 
the B<-fast> option is used.

=item $video->B<getImageURL>()

Returns the URL for the video's "cover art" banner image, which for 
YouTube videos is always the icon image, as YouTube does not support 
a separate banner image at this time.

=item $video->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual video's banner image (binary data).

=item $video->B<getType>()

Returns the video's type ("Youtube").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/Youtube/config

Optional text file for specifying various configuration options 
for a specific site (submodule).  Each option is specified on a 
separate line in the format below:
NOTE:  Do not follow the lines with a semicolon, comma, or any other 
separator.  Non-numeric I<values> should be surrounded with quotes, either 
single or double.  Blank lines and lines beginning with a "#" sign as 
their first non-blank character are ignored as comments.

'option' => 'value' [,]

and the options are loaded into a hash used only by the specific 
(submodule) specified.  Valid options include 
I<-debug> => [0|1|2] and most of the L<LWP::UserAgent> options.  

Options specified here override any specified in 
I<~/.config/StreamFinder/config>.

=item ~/.config/StreamFinder/config

Optional text file for specifying various configuration options.  
Each option is specified on a separate line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used by all sites 
(submodules) that support them.  Valid options include 
I<-debug> => [0|1|2] and most of the L<LWP::UserAgent> options.

=back

NOTE:  Options specified in the options parameter list of the I<new()> 
function will override those corresponding options specified in these files.

=head1 KEYWORDS

youtube

=head1 DEPENDENCIES

yt-dlp (or youtube-dl, or other compatable program)

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>, youtube-dl

=head1 RECCOMENDS

yt-dlp, wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-youtube at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Youtube>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Youtube

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Youtube>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Youtube>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Youtube>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Youtube/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2021 Jim Turner.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

package StreamFinder::Youtube;

use strict;
use warnings;
use URI::Escape;
use HTML::Entities ();
use LWP::UserAgent ();
use parent 'StreamFinder::_Class';

my $DEBUG = 0;
my $DEFAULTYTSITE = 'https://www.youtube.com';
my $DEFAULTFMT = 'best';
my $DEFAULTFALLBACK = 'bestaudio';

sub new
{
	my $class = shift;
	my $url = shift;

	return undef  unless ($url);

	my $self = $class->SUPER::new('Youtube', @_);

	#SET DEFAULTS FOR FLAGS:
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});
	$self->{'formatonly'} = 0  unless (defined $self->{'formatonly'});
	$self->{'noiframes'} = 0  unless (defined $self->{'noiframes'});
	$self->{'notrim'} = 0;
	$self->{'youtubeonly'} = 0  unless (defined $self->{'youtubeonly'});
	$self->{'youtube-site'} = $DEFAULTYTSITE;
	#DEFAULT YOUTUBE-DL ARGUMENTS:
	$self->{'youtube-dl-args'} = '--get-url --get-format --get-thumbnail --get-title --get-description --get-id'
			unless (defined $self->{'youtube-dl-args'});

	#FETCH ANY PARAMETERS PASSED TO THE new() FUNCTION (OVERRIDE ANY SET IN _class (GENERAL OR CONFIG FILES)):
	while (@_) {
		if ($_[0] =~ /^\-?fast$/o) {
			shift;
			$self->{'fast'} = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
		} elsif ($_[0] =~ /^\-?noiframes$/o) {
			shift;
			$self->{'noiframes'} = (defined $_[0]) ? shift : 1;
		} elsif ($_[0] =~ /^\-?youtubeonly$/o) {
			shift;
			$self->{'youtubeonly'} = (defined $_[0]) ? shift : 1;
		} elsif ($_[0] =~ /^\-?formatonly$/o) {
			shift;
			$self->{'formatonly'} = (defined $_[0]) ? shift : 1;
		} elsif ($_[0] =~ /^\-?notrim$/o) {   #NOT CURRENTLY USED, RESERVED FOR FUTURE USE.
			shift;
			$self->{'notrim'} = (defined $_[0]) ? shift : 1;
		} elsif ($_[0] =~ /^\-?youtube-site$/o) {
			shift;
			$self->{'youtube-site'} = (defined $_[0]) ? shift : $DEFAULTYTSITE;
			$self->{'youtube-site'} = s#\/$##;
			$self->{'youtube-site'} = 'https://' . $self->{'youtube-site'}
					unless ($self->{'youtube-site'} =~ m#^https?\:\/\/#);
		} elsif ($_[0] =~ /^\-?format$/o) {
			shift;
			$self->{'format'} = shift  if (defined $_[0]);
		} elsif ($_[0] =~ /^\-?format\-fallback$/o) {
			shift;
			$self->{'format-fallback'} = shift  if (defined $_[0]);
		} elsif ($_[0] =~ /^\-?user-agent$/o) {
			shift;
			$self->{'user-agent'} = shift  if (defined $_[0]);
		} elsif ($_[0] =~ /^\-?youtube-dl$/o) {
			shift;
			$self->{'youtube-dl'} = shift  if (defined $_[0]);
		} elsif ($_[0] =~ /^\-?youtube-dl-args$/o) {
			shift;
			$self->{'youtube-dl-args'} = shift  if (defined $_[0]);
		} elsif ($_[0] =~ /^\-?youtube-dl-add-args$/o) {
			shift;
			$self->{'youtube-dl-add-args'} = shift  if (defined $_[0]);
		} else {
			shift;  #DISCARD ANY OTHERS.
		}
	}
	$self->{'youtubeonly'} = 1  if ($self->{'noiframes'});  #NO EMBEDDED RUMBLE-SEARCH IF NO IFRAMES ALLOWED!

	$self->{'youtube-dl'} = 'yt-dlp'  unless (defined $self->{'youtube-dl'});

	print STDERR "-0(Youtube): URL=$url=\n"  if ($DEBUG);
	$url =~ s/\?autoplay\=true$//;  #STRIP THIS OFF SO WE DON'T HAVE TO.
	(my $url2fetch = $url);
	$self->{'_isaYtPage'} = 1;
	#DEPRECIATED (STATION-IDS NOW INCLUDE STUFF BEFORE THE DASH: ($self->{'id'} = $url) =~ s#^.*\-([a-z]\d+)\/?$#$1#;
	if ($url2fetch =~ m#^https?\:#) {
		$self->{'_isaYtPage'} = 0  unless ($url2fetch =~ /\b(?:youtube\.|youtu.be|ytimg\.)\b/);
#$url2fetch =~ s/www\.youtube\.com/youtube\.be/;  #WWW.YOUTUBE.COM SEEMS TO NOW BE BLOCKING youtube-dl?! :/
		$self->{'id'} = $1  if ($url2fetch =~ m#\/([^\/]+)\/?$#);
		$self->{'id'} =~ s/^watch\?v\=//;
		$self->{'id'} =~ s/[\?\&].*$//;
		$self->{'id'} = $1  if (!$self->{'_isaYtPage'} && $url2fetch =~ m#id[\=\:\#]?([^\/\s\=\:\#]+)#);
	} else {
		$self->{'id'} = $url;
		$url2fetch = $self->{'youtube-site'} . '/watch?v=' . $url;
	}
	print STDERR "-1 (isYT=$$self{'_isaYtPage'}) FETCHING URL=$url2fetch= VIA $$self{'youtube-dl'}: ID=$$self{'id'}=\n"  if ($DEBUG);
	$self->{'genre'} = 'Video';
	$self->{'albumartist'} = $url2fetch;

	#FIRST, CHECK IF WE'RE A CHANNEL OR USER PAGE, IF SO, FETCH & RETURN LATEST UPLOADED VIDEO (EXCLUDE MARQUEE VIDEO AT TOP):

	if ($self->{'_isaYtPage'} && !$self->{'noiframes'} && ($url2fetch =~ m#\/(?:channel|user|c)\/#
			|| $url2fetch =~ m#$self->{'youtube-site'}\/\@#)) {  #WE'RE A CHANNEL PAGE, GRAB 1ST VIDEO!:
		print STDERR "..1a:We're a channel or user page!...\n"  if ($DEBUG);
		my $embedded_video;
		my $html = '';
		my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
		$ua->timeout($self->{'timeout'});
		$ua->max_size(1024);  #LIMIT FETCH-SIZE TO AVOID INFINITELY DOWNLOADING A STREAM!
		$ua->cookie_jar({});
		$ua->env_proxy;
	 	my $response = $ua->get($url2fetch);
	 	$html = $response->decoded_content  if ($response->is_success);
	 	if ($html =~ /\<\!DOCTYPE\s+(?:html|text)/i) {  #IF WE'RE AN HTML DOC. (NOT A STREAM!), THEN FETCH THE WHOLE THING:
			$ua->max_size(undef);  #(NOW OK TO FETCH THE WHOLE DOCUMENT)
		 	my $response = $ua->get($url2fetch);
		 	$html = $response->decoded_content  if ($response->is_success);
			return undef  unless ($html);

			$html =~ s#^.+\"description\"\:\{\"runs\"\:##s;  #USER PAGES CAN HAVE A BANNER VIDEO, *TRY TO* SKIP THIS!
			if ($html =~ m#\:\{\"url\"\:\"([^\"]+)\"\,\"webPageType\"\:\"WEB\_PAGE\_TYPE\_WATCH\"\,#s) {
				$url2fetch = $1;
				$url2fetch =~ s#^\/\/#https\:\/\/#;  #URL STARTS WITH "//" (PREMPTIVE)
				$url2fetch =~ s#^\/#$self->{'youtube-site'}\/#;  #URL IS JUST "/video-id[?other-junk]" (COMMON)
				$self->{'id'} = $1  if ($url2fetch =~ m#\/([^\/]+)\/?$#);
				$self->{'id'} =~ s/[\?\&].*$//;
				$self->{'id'} =~ s/^watch\?v\=//;
				print STDERR "---FOUND 1ST EPISODE! FETCHING=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
				goto DO_YTDL;   #SKIP NON-YOUTUBE PAGE CHECK (NEXT PARAGRAPH):
			}
		}
		print STDERR "u:DID NOT FIND A VIDEO ON CHANNEL/USER PAGE, PUNT!"  if ($DEBUG);
		return undef;
	}

	#IF NON-YOUTUBE PAGE, LOOK FOR ANYTHING EMBEDDED IN AN IFRAME:

	unless ($self->{'_isaYtPage'} || $self->{'noiframes'}) {
		print STDERR "..1a:See if we have a StreamFinder-supported URL in 1st iframe?...\n"  if ($DEBUG);
		my $embedded_video;
		my $html = '';
		my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
		$ua->timeout($self->{'timeout'});
		$ua->max_size(1024);  #LIMIT FETCH-SIZE TO AVOID INFINITELY DOWNLOADING A STREAM!
		$ua->cookie_jar({});
		$ua->env_proxy;
	 	my $response = $ua->get($url);
	 	$html = $response->decoded_content  if ($response->is_success);
	 	if ($html =~ /\<\!DOCTYPE\s+(?:html|text)/i) {  #IF WE'RE AN HTML DOC. (NOT A STREAM!), THEN FETCH THE WHOLE THING:
			$ua->max_size(undef);  #(NOW OK TO FETCH THE WHOLE DOCUMENT)
		 	my $response = $ua->get($url2fetch);
		 	$html = $response->decoded_content  if ($response->is_success);
			while ($html && $html =~ s#\<iframe([^\>]+)\>##s) {
				my $one = $1;
				my $embeddedURL = ($one =~ m#\"(https?\:\/\/[^\"]+)#s) ? $1 : '';
				if ($embeddedURL) {
					$embeddedURL =~ s/[\?\&].*$//  unless ($self->{'notrim'} || $embeddedURL =~ /watch\?v\=/);
					print STDERR "--embedded IFRAME url=$embeddedURL=\n"  if ($DEBUG);
					my $haveStreamFinder = 0;
					eval { require 'StreamFinder.pm'; $haveStreamFinder = 1; };
					if ($haveStreamFinder) {
						my %globalArgs = (-noiframes => 1, -debug => $DEBUG);
						foreach my $arg (qw(log logfmt)) {
							$globalArgs{$arg} = $self->{$arg}  if (defined($self->{$arg}) && $self->{$arg});
						}
						$embedded_video = new StreamFinder($embeddedURL, %globalArgs);
					}
					last;
				}
			}
			return $embedded_video  if (defined($embedded_video) && $embedded_video->count() > 0);

			unless ($self->{'youtubeonly'}) {
				if ($html =~ /\bRumble\s*\(\"play\"\,\s+\{\"video\"\:\"([a-z0-9\-\_]+)\"/si) {
					#EXTRACT CERTAIN EMBEDDED RUMBLE VIDEOS NOT NECESSARILY IN AN IFRAME:
					my $embeddedURL = 'https://rumble.com/embed/' . $1;
					my $haveRumble = 0;
					print STDERR "---FOUND AN EMBEDDED RUMBLE VIDEO ($embeddedURL), SEE IF WE CAN GO WITH THAT!\n"  if ($DEBUG);
					eval { require 'StreamFinder/Rumble.pm'; $haveRumble = 1; };
					if ($haveRumble) {
						my %globalArgs = (-debug => $DEBUG);
						foreach my $arg (qw(log logfmt)) {
							$globalArgs{$arg} = $self->{$arg}  if (defined($self->{$arg}) && $self->{$arg});
						}
						$embedded_video = new StreamFinder::Rumble($embeddedURL, %globalArgs);
						return $embedded_video  if (defined($embedded_video) && $embedded_video->count() > 0);
					}
				}
			}
		}
	}

	#NEXT:  GET STREAMS, THUMBNAIL, ETC. FROM youtube-dl:

DO_YTDL:
	if (defined $self->{'formats_by_url'}) {
		my %formats_by_url = %{$self->{'formats_by_url'}};
		foreach my $i (keys %formats_by_url) {
			$self->{'format'} = $formats_by_url{$i}  if ($url =~ m#$i#i);
		}
	}
	$self->{'format-fallback'} = $DEFAULTFALLBACK
		if  (!defined($self->{'format-fallback'}) && $self->{'formatonly'});
	my $ytformat = (defined $self->{'format'}) ? $self->{'format'} : $DEFAULTFMT;
	my $ua = (defined $self->{'user-agent'}) ? (' --user-agent "'.$self->{'user-agent'}.'"') : '';
	my $ytdlArgs = $self->{'youtube-dl-args'};
	$ytdlArgs .= $self->{'youtube-dl-add-args'}  if (defined $self->{'youtube-dl-add-args'});
	$ytdlArgs .= $ua;
	$ytdlArgs .= ' -f "' . $ytformat . '" '  unless ($ytformat =~ /^a(?:ny|ll)$/i);
	my $try = 0;
	my (@ytdldata, @ytStreams);

RETRYIT:
	$_ = '';
	my $cmd = '';
	if (defined($self->{'userid'}) && defined($self->{'userpw'})) {  #USER HAS A LOGIN CONFIGURED:
		my $uid = $self->{'userid'};
		my $upw = $self->{'userpw'};
		$cmd = $self->{'youtube-dl'} . '--username "' . $uid . '" --password "' . $upw . '" '
				. $ytdlArgs. ' "' . $url2fetch .'"';
	} else {
		$cmd = $self->{'youtube-dl'} . " $ytdlArgs " . '"' . $url2fetch . '"';
	}
	print STDERR "--TRY($try of 1): youtube-dl: ARGS=$ytdlArgs= FMT=$ytformat=\nYT COMMAND==>$cmd<==\n"  if ($DEBUG);
	$_ = `$cmd`;
	print STDERR "--YT RETURNED DATA===>$_<===\n"  if ($DEBUG);
	@ytdldata = split /\r?\n/s;
	unless ($try || scalar(@ytdldata) > 0) {  #IF NOTHING FOUND, RETRY WITHOUT THE SPECIFIC FILE-FORMAT:
		$try++;
		if (defined $self->{'format-fallback'}) {
			print STDERR "..1:No ($ytformat) streams found, try again with ($$self{'formatonly'})...\n"  if ($DEBUG);
			goto RETRYIT  if ($ytdlArgs =~ s/\-f\s+\"[^\"]+\"/\-f \"$$self{'format-fallback'}\"/);
		}
		unless ($self->{'formatonly'}) {
			print STDERR "..1:No ($ytformat) streams found, try again for any (audio, etc.)...\n"  if ($DEBUG);
			goto RETRYIT  if ($ytdlArgs =~ s/\-f\s+\"[^\"]+\"//);
		}
	}
	return undef unless (scalar(@ytdldata) > 0);

	#NOTE:  ytdldata is ORDERED:  TITLE?, ID, STREAM-URLS, THEN THE ICON URL, THEN DESCRIPTION, LASTLY FORMATS!:
	unless ($ytdldata[0] =~ m#^https?\:\/\/#) {
		$_ = shift(@ytdldata);
		$self->{'title'} ||= $_;
	}
	$self->{'_ytID'} = '';
	if ($ytdlArgs =~ /\-\-get\-id\b/ && $ytdldata[0] !~ /^https?\:/) {  #SHOULD HAVE AN "ID":
		my $get_id = shift(@ytdldata);
		$self->{'_ytID'} = $get_id  if ($get_id =~ /^[a-z0-9\-\_]{11}$/i);
	}
	my $fmtline = ($ytdldata[$#ytdldata] =~ m#^https?\:\/\/#) ? '-none' : pop(@ytdldata);  #LAST LINE IS (USUALLY) THE LIST OF FORMATS RETURNED.
	my @fmtsfound = split(/\+/, $fmtline);
	$self->{'description'} = '';
	@ytStreams = ();
	my $urlcount = 0;
	while (@ytdldata) {
		$_ = shift @ytdldata;
		if ($urlcount <= $#fmtsfound) {
			push @ytStreams, $_  unless ($self->{'secure'} && $_ !~ /^https/o);
		} elsif (m#^https?\:\/\/#o && $ytdlArgs =~ /get-thumbnail/o) {
			if (m#\.(jpe?g|png|gif|com|webp|svg)\b#io) {
				$self->{'iconurl'} = $_;  #WILL ALWAYS BE THE LAST URL!
			} else {
				$self->{'iconurl'} ||= $_;  #(LAST RESORT, AS SOME YOUTUBE IMAGE URLS DON'T HAVE EXTENSIONS!:
			}
		} else {
			$self->{'description'} .= $_ . ' ';
		}
		$urlcount++;
	}
	push @{$self->{'streams'}}, @ytStreams;
	$self->{'cnt'} = scalar @{$self->{'streams'}};
	print STDERR "-STREAM COUNT=".$self->{'cnt'}."= FMTS=".join('|',@fmtsfound)."= ICON=".$self->{'iconurl'}."=\n"  if ($DEBUG);
	unless ($try || $self->{'cnt'} > 0) {  #IF NO STREAMS FOUND, RETRY WITHOUT THE SPECIFIC FILE-FORMAT:
		$try++;
		if (defined $self->{'format-fallback'}) {
			print STDERR "..1:No ($ytformat) streams found, try again with ($$self{'formatonly'})...\n"  if ($DEBUG);
			goto RETRYIT  if ($ytdlArgs =~ s/\-f\s+\"[^\"]+\"/\-f \"$$self{'format-fallback'}\"/);
		}
		unless (defined($self->{'formatonly'}) && $self->{'formatonly'}) {
			print STDERR "..2:No ($ytformat) streams found, try again for any (audio, etc.)...\n"  if ($DEBUG);
			goto RETRYIT  if ($ytdlArgs =~ s/\-f\s+\"[^\"]+\"//);
		}
	}

	#NOW MANUALLY SCRAPE YOUTUBE PAGE TO TRY TO GET artist, description, year, ETC. DIRECTLY FROM PAGE (IF A YOUTUBE SITE):

	unless ($self->{'fast'}) {  #(FAST MEANS SKIP SCRAPING YOUTUBE PAGE FOR ADDTL. METADATA)
		$try = 0;
RETRYPAGE:
		print STDERR "----(try2=$try= FETCHURL=$url2fetch= isYT?=".$self->{'_isaYtPage'}."=\n"  if ($DEBUG);
		if ($self->{'_isaYtPage'}) {  #WE'RE A YOUTUBE PAGE, FETCH METADATA:
			#CONVERT "embedded" YT PAGES TO ACTUAL PAGE (EMBEDDED PAGES DON'T HAVE THE METADATA WE'RE SEEKING!:
			if ($url2fetch =~ m#^(.+?)\/embed\/([a-z0-9\-\_]{11})#i) {  #TRY FETCHING YOUTUBE SITE FROM THE EMBEDDED URL:
				$url2fetch = $1.'/watch?v='.$2;
			} elsif ($url2fetch =~ m#^\/embed\/([a-z0-9\-\_]{11})#i) {  #IF FAIL, TRY www.youtube.com:
				$url2fetch = $self->{'youtube-site'} . '/watch?v=' .$1;
			}
			print STDERR "-2 (TRY=$try) FETCHING SCREEN URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
			my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
			$ua->timeout($self->{'timeout'});
			$ua->cookie_jar({});
			$ua->env_proxy;
			my $html = '';
			my $response = $ua->get($url2fetch);
			if ($response->is_success) {
				$html = $response->decoded_content;
			} else {
				print STDERR $response->status_line  if ($DEBUG);
				my $no_wget = system('wget','-V');
				unless ($no_wget) {
					print STDERR "\n..trying wget...\n"  if ($DEBUG);
					$html = `wget -t 2 -T 20 -O- -o /dev/null \"$url2fetch\" 2>/dev/null `;
				}
			}
			$html =~ s/\\\"/\&quot\;/gs;
			$self->{'genre'} = $1  if ($html =~ m#\"category\"\:\"([^\"]+)#s);
			if ($html =~ s#\]\}\,\"title\"\:\{\"runs\"\:\[\{\"text\"\:\"([^\"]+)\"\,\"navigationEndpoint\"\:([^\}]+)##s) {
				my $two = $2;
				$self->{'artist'} = $1;
				$self->{'albumartist'} = $self->{'youtube-site'} . $1  if ($two =~ m#\"url\"\:\"([^\"]+)#);
			}
			if ($html =~ s#\"videoDetails\"\:\{\"videoId\"\:\"([^\"]+)\"([^\}]+)##s) {
				my $two = $2;
				$self->{'id'} = $1;
				$self->{'title'} = $1  if ($two =~ m#\"title\"\:\"([^\"]+)#);
				$self->{'iconurl'} = $1  if ($two =~ m#\"thumbnails\"\:\[\{\"url\"\:\"([^\"]+)#);
				$self->{'iconurl'} =~ s/\?.*$//;
			}
			if ($html =~ m#\"dateText\"\:\{([^\}]+)\}#s) {
				my $one = $1;
				$self->{'year'} = $1  if ($one =~ /(\d\d\d\d)/);
			}
			$self->{'articonurl'} = $1  if ($html =~ m#(?:\"CHANNEL\"\,\"image\"|\"videoOwnerRenderer\")\:\{\"thumbnails"\:\[\{\"url\"\:\"([^\"]+)#s);
			print  "--YT:2 CHANNEL ICON URL1=".$self->{'articonurl'}."=\n"  if ($DEBUG);
			unless ($self->{'articonurl'}) {
				my $ownerstuff = ($html =~ m#\"videoOwnerRenderer\"\:\{([^\}]+)#s) ? $1 : '';
				$self->{'articonurl'} = $1  if ($ownerstuff =~ /\"url\"\:\"([^\"]+)/);
			}
			print  "--YT:2 CHANNEL ICON URL2=".$self->{'articonurl'}."=\n"  if ($DEBUG);
		} elsif (!$try && $self->{'_ytID'}) { #WE'RE NOT A YOUTUBE PAGE, BUT WE HAVE THE YT ID, SO TRY TO FETCH IT FOR METADATA:
			print STDERR "--WE ARE NOT A YT PAGE, BUT ytID=".$self->{'_ytID'}."= SO WE WILL TRY AGAIN!\n"  if ($DEBUG);
			++$try;
			++$self->{'_isaYtPage'};
			$url2fetch = $self->{'youtube-site'} . '/watch?v=' . $self->{'_ytID'};
			goto RETRYPAGE;
		}
	}
	$self->{'total'} = $self->{'cnt'};
	$self->{'imageurl'} = $self->{'iconurl'};
	$self->{'Url'} = ($self->{'cnt'} > 0) ? $self->{'streams'}->[0] : '';
	print STDERR "-count=".$self->{'cnt'}."= iconurl=".$self->{'iconurl'}."=\n"  if ($DEBUG);
	print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"
			if ($DEBUG && $self->{'cnt'} > 0);
	if ($self->{'description'} =~ /\w/) {
		$self->{'description'} =~ s/\s+$//;
	} else {
		$self->{'description'} = $self->{'title'};
	}
	foreach my $i (qw(title artist albumartist description genre)) {
		$self->{$i} = HTML::Entities::decode_entities($self->{$i});
		$self->{$i} = uri_unescape($self->{$i});
		$self->{$i} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egso;
	}
	print STDERR "-2: title=".$self->{'title'}."= id=".$self->{'id'}."= artist=".$self->{'artist'}."= year(Published)=".$self->{'year'}."=\n"  if ($DEBUG);
	if ($DEBUG) {
		foreach my $i (sort keys %{$self}) {
			print STDERR "--KEY=$i= VAL=".$self->{$i}."=\n";
		}
	}
	$self->_log($url2fetch);

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub getImageData
{
	my $self = shift;
	return $self->getIconData();
}

1
