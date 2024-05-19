=head1 NAME

StreamFinder::EpochTV - Fetch actual raw streamable video URLs on www.theepochtimes.com

=head1 AUTHOR

This module is Copyright (C) 2024 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::EpochTV;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $video = new StreamFinder::EpochTV($ARGV[0]);

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

	print "Artist=$artist\n"  if ($artist);
	
	my $genre = $video->{'genre'};

	print "Genre=$genre\n"  if ($genre);
	
	my $icon_url = $video->getIconURL();

	if ($icon_url) {   #SAVE THE ICON TO A TEMP. FILE:

		print "Icon URL=$icon_url=\n";

		my ($image_ext, $icon_image) = $video->getIconData();

		if ($icon_image && open IMGOUT, ">/tmp/${videoID}.$image_ext") {

			binmode IMGOUT;

			print IMGOUT $icon_image;

			close IMGOUT;

			print "...Icon image downloaded to (/tmp/${videoID}.$image_ext)\n";

		}

	}

	my $stream_count = $video->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $video->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::EpochTV accepts a valid video/channel ID or URL on 
www.theepochtimes.com and returns the actual stream URL(s), title, and cover 
art icon.  The purpose is that one needs one of these URLs in order to have 
the option to stream the video in one's own choice of media player software 
rather than using their web browser and accepting any / all flash, ads, 
javascript, cookies, trackers, web-bugs, and other crapware that can come with 
that method of play.  The author uses his own custom all-purpose media player 
called "fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
www.theepochtimes.com streams.

One stream URL can be returned for each video.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ]])

Accepts a www.theepochtimes.com video or channel ID or URL and creates and 
returns a a new video object, or I<undef> if the URL is not a valid video, or 
no streams are found.  The URL can be the full URL, ie. 
https://www.theepochtimes.com/epochtv/B<channel_or_video-id>, or just 
B<channel_or_video-id>.  EpochTV can't really distinguish between episode and 
channel IDs except that channel pages do not contain a specific video stream 
URL, so if no stream URL is found, it assumes a channel page, in which case, 
the first (latest) episode is returned (along with the channel's playlist).

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  
If 1 then only secure ("https://") streams will be returned.  Currently, 
all EpochTV streaming URLs are believed to be secure (https).

DEFAULT I<-secure> is 0 (false) - return all streams (http and https).

Additional options:

I<-log> => "I<logfile>"

Specify path to a log file.  If a valid and writable file is specified, A line 
will be appended to this file every time one or more streams is successfully 
fetched for a url.

DEFAULT I<-none-> (no logging).

I<-logfmt> specifies a format string for lines written to the log file.

DEFAULT "I<[time] [url] - [site]: [title] ([total])>".  

The valid field I<[variables]> are:  [stream]: The url of the first/best 
stream found.  
[site]:  The site name (EpochTV).  [url]:  The url searched for streams.  
[time]: Perl timestamp when the line was logged.  [title], [artist], [album], 
[description], [year], [genre], [total], [albumartist]:  The corresponding 
field data returned (or "I<-na->", if no value).

=item $video->B<get>(['playlist'])

Returns an array of strings representing all stream URLs found.
Note:  If an author / channel page url is given, rather than an individual 
video episode's url, get() returns the first (latest?) video episode found, 
and get("playlist") returns an extended m3u playlist containing the urls, 
titles, etc. for all the video episodes found on that page url starting with 
the latest or most popular.

=item $video->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  There currently are no valid I<options>.

=item $video->B<count>()

Returns the number of streams found for the video (will nearly always be 1).

=item $video->B<getID>()

Returns the video's EpochTV ID (default).  EpochTV video and channel IDs 
consist of combinations of lower-case letters, numbers and hyphens, and are 
indestinguishable from each other, except that channel pages don't return 
a specific video streaming URL, but rather fetch and return the first 
(latest) episode video's streaming URL and metadata.

=item $video->B<getTitle>(['desc'])

Returns the video's title, or (long description).  Videos 
on EpochTV can have separate descriptions, but for videos, 
it is always the video's title.

Note:  EpochTV video descriptions are usually incomplete, ending with a "..", 
since on the page itself there's a "Read More" button to view the rest, and 
"the rest" can only be obtained with Javascript.

=item $video->B<getIconURL>(['artist'])

Returns the URL for the video's "cover art" icon image, if any.
If B<'artist'> is specified, the channel artist's icon url is returned, 
if any.

=item $video->B<getIconData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.
If B<'artist'> is specified, the channel artist's icon data is returned, 
if any.

=item $video->B<getImageURL>(['artist'])

Returns the URL for the video's "cover art" (usually larger) 
banner image.  If B<'artist'> is specified, the channel artist's image URL 
is returned, if any.


=item $video->B<getImageData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual video's banner image (binary data).
If B<'artist'> is specified, the channel artist's image data is returned, 
if any.  Individual artists on epochtv.com often do have their own 
separate larger banner image.

=item $video->B<getType>()

Returns the video's type ("EpochTV").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/EpochTV/config

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

Options specified here override any specified in I<~/.config/StreamFinder/config>.

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

epochtv

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-iheartradio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-EpochTV>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::EpochTV

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-EpochTV>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-EpochTV>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-EpochTV>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-EpochTV/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Jim Turner.

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

package StreamFinder::EpochTV;

use strict;
use warnings;
use URI::Escape;
use HTML::Entities ();
use LWP::UserAgent ();
use parent 'StreamFinder::_Class';

my $DEBUG = 0;

sub new
{
	my $class = shift;
	my $url = shift;

	return undef  unless ($url);

	my $self = $class->SUPER::new('EpochTV', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});
	$self->{'id'} = '';
	(my $url2fetch = $url);
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $html = '';
	my $response;
	my $isEpisode = 1;
	my $tried = 0;

TRYIT:
	if ($url2fetch =~ /^https?\:/) {
		$self->{'id'} = $1  if ($url =~ m#\/([a-z\-\d]+)\/?$#);
	} else {
		$self->{'id'} = $url;
		$url2fetch = 'https://www.theepochtimes.com/epochtv/' . $url;
	}

	$html = '';
	print STDERR "-0(EpochTV): FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	$response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html);  #STEP 1 FAILED, INVALID EpochTV URL, PUNT!

	my $protocol = $self->{'secure'} ? '' : '?';
	if ($html =~ m#\,\"contentUrl\"\:\"(https${protocol}\:[^\"]+)#s) {
		push (@{$self->{'streams'}}, $1);  #WE'RE AN EPISODE PAGE, CONTINUE:
	} elsif ($tried < 1) {   #NO STREAM URL FOUND, ASSUME WE'RE A CHANNEL PAGE & TRY AGAIN W/IT'S 1ST EPISODE!:
		++$tried;
		$isEpisode = 0;
		if ($html =~ m#\<div\s+class\=\"basis\-1\/6\s+pt\-2\s+sm\:pt\-4\"\>\s*\<a\s+href\=\"([^\"]+)#s) {
			$url2fetch = $1;
			$url2fetch = 'https://www.theepochtimes.com' . $url2fetch  unless ($url2fetch =~ m#^https?\:#);
			print STDERR "i:No stream, perhaps channel page1, so fetch marquee episode URL=$url2fetch=\n"  if ($DEBUG);
			goto TRYIT;
		} elsif ($html =~ m#\<div\s+class\="relative\s+lg\:order\-first\"\>\s*\<a\s+href\=\"([^\"]+)#s) {
			$url2fetch = $1;
			$url2fetch = 'https://www.theepochtimes.com' . $url2fetch  unless ($url2fetch =~ m#^https?\:#);
			print STDERR "i:No stream, perhaps channel page2, so fetch marquee episode URL=$url2fetch=\n"  if ($DEBUG);
			goto TRYIT;
		}
	}

	$self->{'genre'} = 'Video';  #www.theepochtimes.com DOES NOT CURRENTLY INCLUDE A GENRE/CATEGORY.
	print STDERR "---ID=".$self->{'id'}."=\n"  if ($DEBUG);
	$self->{'title'} = $1  if ($html =~ m#\<meta\s+(?:name|property)\=\"(?:og|twitter)\:title\"\s+content\=\"([^\"]+)\"\s*\/\>#s);
	$self->{'title'} ||= $1  if ($html =~ m#\"VideoObject\"\,\"name\"\:\"([^\"]+)#s);
	$self->{'title'} ||= $1  if ($html =~ m#\<title\>(.+?)\<\/title\>#si);
	$self->{'iconurl'} = $1  if ($html =~ m#\<meta\s+(?:name|property)\=\"(?:og|twitter)\:image\"\s+content\=\"([^\"]+)#s);
	$self->{'iconurl'} ||= $1  if ($html =~ m#data\-thumbnail\=\"([^\"]+)#s);
	$self->{'imageurl'} = $1  if ($html =~ m#\,\"thumbnailUrl\"\:\"([^\"]+)#s);
	$self->{'albumartist'} = $url2fetch;
	$self->{'album'} = ($html =~ m#\bmd\:text\-lg\"\>([^\<]+)#s) ? $1 : '';
	if ($html =~ m#\<a\s+href\=\"([^\"]+)\"><div class="(?:h-\d+\s+w-\d+|size\-\d+)">(.+?)\<\/div\>#s) {
		$self->{'albumartist'} = $1;
		my $channeldata = $2;
		if ($self->{'albumartist'}) {
			$self->{'albumartist'} = 'https://www.theepochtimes.com' . $self->{'albumartist'}
					unless ($self->{'albumartist'} =~ m#^https?\:#);
		}
		if ($channeldata =~ m#\burl\=([^\"]+)#s) {
			$self->{'articonurl'} = $1;
			$self->{'articonurl'} = HTML::Entities::decode_entities($self->{'iconurl'});
			$self->{'articonurl'} = uri_unescape($self->{'iconurl'});
			$self->{'articonurl'} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egso;
			$self->{'articonurl'} =~ s#\&.*$##;
		}
	}
	$self->{'artist'} = $1  if ($html =~ m#\\\"authors\\\"\:\[\{\\\"name\\\"\:\\\"([^\\]+)#s);
	$self->{'articonurl'} = $1  if ($html =~ m#\\\"termIcon\\\"\:\\\"([^\\]+)#s);
	$self->{'artimageurl'} = $1  if ($html =~ m#\\\"termPoster\\\"\:\\\"([^\\]+)#s);
	if ($html =~ m#\\\"avatar\\\"\:\\\"([^\\]+)#s) {
		$self->{'articonurl'} ||= $1;
		$self->{'artimageurl'} ||= $1;
		print STDERR "i:Individual artist avatar found($$self{'articonurl'}).\n"  if ($DEBUG);
	} else {
		print STDERR "i:No individual artist avatar found, using category page icon ($$self{'articonurl'}).\n"  if ($DEBUG);
	}
	$self->{'articonurl'} ||= $self->{'articonurl'};
	$self->{'description'} = $1  if ($html =~ m#\bwhitespace\-break\-spaces\"\>([^\<]+)#s);
	$self->{'description'} ||= $1  if ($html =~ m#\<meta\s+name\=\"description\"\s+content\=\"([^\"]+)#s);
	$self->{'description'} ||= $1  if ($html =~ m#\<meta\s+property\=\"og\:description\"\s+content\=\"([^\"]+)#s);
	$self->{'created'} = $1  if ($html =~ m#\"uploadDate\"\:\"([^\"]+)#s);
	$self->{'created'} ||= $1  if ($html =~ m#\<div\s+class\=\"whitespace\-nowrap]s+text\-sm\s+text\-\[\#707070\]\"\>([^\<]+)#s);
	$self->{'year'} = ($self->{'created'} =~ /(\d\d\d\d)/) ? $1 : '';
	$self->{'imageurl'} ||= $self->{'iconurl'};

	$self->{'cnt'} = scalar @{$self->{'streams'}};
	$self->{'Url'} = ($self->{'cnt'} > 0) ? $self->{'streams'}->[0] : '';

	#NOW GET PLAYLIST DATA:

	my (%epiHash, %epiTitlesSorted);
	my $epiCnt = $self->{'cnt'};
	if ($self->{'cnt'} > 0) {
		$epiHash{$self->{'title'}} = $self->{'Url'}; 
		print STDERR "--0:EPISODE($epiCnt): T=$$self{'title'}= S=$epiHash{$$self{'title'}}=\n"  if ($DEBUG);
		$epiTitlesSorted{sprintf('%3.3d', $epiCnt++)} = $self->{'title'};
	}
	unless ($isEpisode) {
		while ($html =~ s#^.+?\\\"video\\\"\:\{\\\"id\\\"\:\\\"##so) {
			if ($html =~ m#\\\"url\\\"\:\\\"(https${protocol}\:[^\\]+)#s) {
				my $epiStream = $1;
				if ($epiStream =~ /\.(?:m3u8|mp4)$/ && $html =~ m#\d\d\,\\\"(?:title|caption)\\\"\:\\\"([^\\]+)#s) {
					my $epiTitle = $1;
					unless (defined $epiHash{$epiTitle}) {
						$epiHash{$epiTitle} = $epiStream;
						$epiTitlesSorted{sprintf('%3.3d', $epiCnt++)} = $epiTitle;
					}
				}
			}
		}
	}

	$self->{'playlist'} = "#EXTM3U\n";
	$self->{'playlist_cnt'} = 0;
	foreach my $x (sort keys %epiTitlesSorted) {
		$self->{'playlist'} .= "#EXTINF:-1, " . $epiTitlesSorted{$x} . "\n";
		$self->{'playlist'} .= "#EXTART:" . $self->{'artist'} . "\n"
				if ($self->{'artist'});
		$self->{'playlist'} .= "#EXTALB:" . $self->{'album'} . "\n"
				if ($self->{'album'});
		$self->{'playlist'} .= "#EXTGENRE:" . $self->{'genre'} . "\n"
				if ($self->{'genre'});
		$self->{'playlist'} .= $epiHash{$epiTitlesSorted{$x}} . "\n";
		++$self->{'playlist_cnt'};
	}
	$self->{'total'} = $self->{'cnt'} = scalar @{$self->{'streams'}};


	if ($DEBUG) {
		foreach my $f (sort keys %{$self}) {
			print STDERR "--KEY=$f= VAL=$$self{$f}=\n";
		}
		print STDERR "-SUCCESS: 1st stream=".$self->{'Url'}."=\n";
	}


	return undef  unless ($self->{'cnt'} > 0);

	$self->_log($url);     #LOG IT.

	bless $self, $class;   #BLESS IT!

	return $self;
}

1
