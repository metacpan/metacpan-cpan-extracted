=head1 NAME

StreamFinder::SermonAudio - Fetch actual raw streamable URLs on sermonaudio.com

=head1 AUTHOR

This module is Copyright (C) 2021-2024 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::SermonAudio;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $podcast = new StreamFinder::SermonAudio($ARGV[0]);

	die "Invalid URL or no streams found!\n"  unless ($podcast);

	my $firstStream = $podcast->get();

	print "First Stream URL=$firstStream\n";

	my $url = $podcast->getURL();

	print "Stream URL=$url\n";

	my $podcastTitle = $podcast->getTitle();
	
	print "Title=$podcastTitle\n";
	
	my $podcastDescription = $podcast->getTitle('desc');
	
	print "Description=$podcastDescription\n";
	
	my $podcastID = $podcast->getID();

	print "Podcast ID=$podcastID\n";
	
	my $icon_url = $podcast->getIconURL();

	if ($icon_url) {   #SAVE THE ICON TO A TEMP. FILE:

		print "Icon URL=$icon_url=\n";

		my ($image_ext, $icon_image) = $podcast->getIconData();

		if ($icon_image && open IMGOUT, ">/tmp/${podcastID}.$image_ext") {

			binmode IMGOUT;

			print IMGOUT $icon_image;

			close IMGOUT;

			print "...Icon image downloaded to (/tmp/${podcastID}.$image_ext)\n";

		}

	}

	my $stream_count = $podcast->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $podcast->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::SermonAudio accepts a valid podcast (sermon) ID or URL on 
SermonAudio.com and returns the actual stream URL(s), title, and cover art icon.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the podcast in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of play.  The author uses his own custom all-purpose media player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
SermonAudio.com streams.

One or more stream URLs can be returned for each podcast.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-quality> => audio|any ] 
[, I<-speakericon> [ => 0|1 ]] [, I<-secure> [ => 0|1 ]] 
[, I<-nowebp> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ]])

Accepts a www.sermonaudio.com podcast (sermon) ID or URL and creates and 
returns a a new podcast object, or I<undef> if the URL is not a valid podcast, 
or no streams are found.  The URL can be the full URL, ie. 
https://www.sermonaudio.com/sermons/B<sermon-id>,
https://www.sermonaudio.com/speakers/B<speaker-id>,
https://www.sermonaudio.com/broadcasters/B<church-id>,
https://www.sermonaudio.com/series/B<series-id>,
https://www.sermonaudio.com/sermoninfo.asp?SID=B<id>, 
https://www.sermonaudio.com/source_detail.asp?sourceid=B<source-id>, 
or just I<sermon-id> (>8 digits), I<speaker-id> (5 digits), 
I<series-id> (6 digits), or I<church-id> (alphanumeric).

The optional I<-quality> argument, can be set to either "audio", 
or "any".  "audio" means only accept audio streams, "any" or "all" 
(any other value) means accept both video and audio streams found 
(subject to the I<-secure> argument, if specified).  Unless "audio" is 
specified, and any video stream is accepted (subject to the above limitations), 
then the "best" stream returned will be video (video streams are by default 
favored over audio).  Note:  "high" and "low" are no longer used in v2.41+, 
as now only a single video stream is returned in HLS format (users should 
use "hls_bitrate" config file option to limit video stream bandwidth.

DEFAULT I<-quality> is "I<any>":  (accept both video and audio streams).

The optional I<-speakericon> argument can be set to reverse the artist 
(channel) icon and artist image, usually resulting in the artist icon being a 
photo of the preacher, instead of his church's thumbnail icon.

DEFAULT zero (I<false>): Don't reverse the artist icon and image.

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  
If 1 then only secure ("https://") streams will be returned.

DEFAULT I<-secure> is 0 (false) - return all streams (http and https).

The optional I<-nowebp> argument can be either 0 or 1 (I<false> or I<true>).  
If 1 then image files specified as "img.{png|jpg|jpeg|gif}?webp=true" are 
stripped of the "?webp=true" part which causes them to be downloaded in 
their native format instead of webp.  This is needed by the GTK versions 
of Fauxdacious.

DEFAULT zero (I<false>): Download webp images as webp.

Additional options:

I<-log> => "I<logfile>"

Specify path to a log file.  If a valid and writable file is specified, A line 
will be appended to this file every time one or more streams is successfully 
fetched for a url.

DEFAULT I<-none-> (no logging).

I<-logfmt> specifies a format string for lines written to the log file.

DEFAULT "I<[time] [url] - [site]: [title] ([total])>".  

The valid field I<[variables]> are:  [stream]: The url of the first/best stream 
found.  [site]:  The site name (SermonAudio).  [url]:  The url searched for 
streams.  [time]: Perl timestamp when the line was logged.  [title], [artist], 
[album], [description], [year], [genre], [total], [albumartist]:  
The corresponding field data returned (or "I<-na->", if no value).

=item $podcast->B<get>()

Returns an array of strings representing all stream URLs found.

=item $podcast->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  There currently are no valid I<options>.

=item $podcast->B<count>()

Returns the number of streams found for the podcast.

=item $podcast->B<getID>()

Returns the podcast's SermonAudio ID (default).  For podcasts, the SermonAudio 
ID is a single value.  For individual podcast episodes it's two values 
separated by a slash ("/").

=item $podcast->B<getTitle>(['desc'])

Returns the podcast's title, or (long description).  Podcasts 
on SermonAudio can have separate descriptions, but for podcasts, 
it is always the podcast's title.

=item $podcast->B<getIconURL>(['artist'])

Returns the URL for the podcast's "cover art" icon image, if any.

If B<'artist'> is specified, the channel artist's icon url is returned, 
if any.

=item $podcast->B<getIconData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.

If B<'artist'> is specified, the channel artist's icon data is returned, 
if any.

=item $podcast->B<getImageURL>(['artist'])

Returns the URL for the podcast's "cover art" (usually larger) 
banner image.

If B<'artist'> is specified, the channel artist's image url is returned, 
if any.

Note:  SermonAudio sermons (unlike most other podcast sites) often have both 
an artist icon (for the church) AND an artist image for that artist/channel 
(preacher), and the artist's image is usually slightly larger and is a photo 
of the specific preacher.  See also the B<-speakericon> option.

=item $podcast->B<getImageData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual podcast's banner image (binary data).

If B<'artist'> is specified, the channel artist's icon data is returned, 
if any.

=item $podcast->B<getType>()

Returns the podcast's type ("SermonAudio").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/SermonAudio/config

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

sermonaudio

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-iheartradio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-SermonAudio>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::SermonAudio

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-SermonAudio>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-SermonAudio>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-SermonAudio>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-SermonAudio/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2021-2024 Jim Turner.

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

package StreamFinder::SermonAudio;

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

	my $self = $class->SUPER::new('SermonAudio', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});

	while (@_) {
		if ($_[0] =~ /^\-?debug$/o) {
			shift;
			$DEBUG = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
		} elsif ($_[0] =~ /^\-?secure$/o) {
			shift;
			$self->{'secure'} = (defined $_[0]) ? shift : 1;
		} elsif ($_[0] =~ /^\-?quality$/o) {
			shift;
			$self->{'quality'} = (defined $_[0]) ? shift : 'any';
		} elsif ($_[0] =~ /^\-?speakericon$/o) {
			shift;
			$self->{'speakericon'} = (defined $_[0]) ? shift : 1;
		} elsif ($_[0] =~ /^\-?nowebp$/o) {
			shift;
			$self->{'nowebp'} = (defined $_[0]) ? shift : 1;
		} else {
			shift;
		}
	}
	$self->{'quality'} = 'any'  unless (defined $self->{'quality'});
	$self->{'speakericon'} = 0  unless (defined $self->{'speakericon'});
	$self->{'nowebp'} = 0  unless (defined $self->{'nowebp'});

	my $isEpisode = 1;
	$url =~ s#\\##g;
	(my $url2fetch = $url);
	if ($url =~ /^https?\:/) {  #FULL URL:
		$self->{'id'} = $1  if ($url2fetch =~ m#\?SID\=([\d]+)#);
		unless ($self->{'id'}) {  #WE'RE ONE OF SERMONAUDIO'S ALTERNATE URLS:
			$self->{'id'} = $1  if ($url2fetch =~ /sermonaudio/i && $url2fetch =~ m#([\d]+)\/?$#);
			if ($url2fetch =~ m#\/speakers?\/#) {
				$isEpisode = 0;  #ASSUME WE'RE AN AUTHOR/PREACHER PAGE.
			} elsif ($url2fetch =~ m#\/series\/#) {
				$isEpisode = 0;  #ASSUME WE'RE A SERIES (SERMON GROUP) PAGE.
			} elsif ($url2fetch =~ m#\/broadcasters?\/([a-zA-Z0-9]+)#) {
				$self->{'id'} = $1;
				$isEpisode = 0;  #ASSUME WE'RE A CHURCH PAGE.
			} elsif ($self->{'id'}) {
				$url2fetch = 'https://www.sermonaudio.com/sermoninfo.asp?SID='.$self->{'id'};
			} elsif ($url2fetch =~ m#\bsourceid\=([^\?\&]+)$#) {
				$self->{'id'} = $1;
				$isEpisode = 0;  #ASSUME WE'RE NOT AN EPISODE PAGE.
			} elsif ($url2fetch =~ m#https://www.sermonaudio.com\/[a-z]+\/([^\?\&]+)$#) {
				$self->{'id'} = $1;
				$isEpisode = 0;  #ASSUME WE'RE AN AUTHOR/PREACHER PAGE.
			} else {
				$self->{'id'} = 'sermonaudio';
				$isEpisode = 0;  #ASSUME WE'RE A SEARCH/FOUND PAGE.
			}
		}
	} elsif ($url =~ /^\d\d\d\d\d\d\d\d+$/) {     #(URL=###########)
		$self->{'id'} = $url;
		$url2fetch = "https://www.sermonaudio.com/sermoninfo.asp?SID=$url";
	} elsif ($url =~ /^\d\d\d\d\d$/) {     #5-DIGIT ID (AUTHOR/PREACHER PAGE)
		$self->{'id'} = $url;
		$isEpisode = 0;  #WE'RE AN AUTHOR/PREACHER PAGE.
		$url2fetch = "https://www.sermonaudio.com/speakers/$url";
	} elsif ($url =~ /^\d\d\d\d\d\d$/) {     #6-DIGIT ID (SERIES PAGE)
		$self->{'id'} = $url;
		$url2fetch = "https://www.sermonaudio.com/series/$url";
	} elsif ($url =~ /^[a-z]+$/i) {  #ALPHANUMERIC ID (CHURCH PAGE)
		$self->{'id'} = $url;
		$url2fetch = "https://www.sermonaudio.com/broadcasters/$url";
		$isEpisode = 0;
	} elsif ($url =~ m#\/#) {        #KEYWORD/ID
		$self->{'id'} = $url;
		$url2fetch = "https://www.sermonaudio.com/$url";
		$isEpisode = 0;
	}
	return undef  unless ($self->{'id'});

	my $html = '';
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $response;
	my $tried = 0;

TRYIT:
	print STDERR "-${tried}(SermonAudio): FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);

	$response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	print STDERR "---ID=".$self->{'id'}."= isEpisode=$isEpisode=\n"  if ($DEBUG);
	return undef  unless ($self->{'id'} && $html);

	my $baseURL = ($html =~ m#\bhostname\:\"([^\"]+)#) ? $1 : 'https://www.sermonaudio.com';
	$baseURL =~ s#^\/##;
	$baseURL = 'https://' . $baseURL  unless ($baseURL =~ m#^http#);
	if ($isEpisode) {
		print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
		return undef  unless ($html && $self->{'id'});  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!

		$self->{'genre'} = 'Sermon';
		$self->{'albumartist'} = $url2fetch;
		if ($self->{'quality'} !~ /audio/i && $html =~ s#\<video.+?src\=\"([^\"]+)##s) {
			my $mediaurl = $1;
			unless ($self->{'secure'} && $mediaurl !~ /^https/o) {
				push @{$self->{'streams'}}, $mediaurl;
				print STDERR "--stream found=$mediaurl=\n"  if ($DEBUG);
				$self->{'cnt'}++;
			}
		}
		if ($html =~ s#\<audio.+?src\=\"([^\"]+)##s) {
			my $audiourl = $1;
			unless ($self->{'secure'} && $audiourl !~ /^https/o) {
				push @{$self->{'streams'}}, $audiourl;
				print STDERR "--stream found=$audiourl=\n"  if ($DEBUG);
				$self->{'cnt'}++;
			}
		}
		$self->{'total'} = $self->{'cnt'};
#		return undef  unless ($self->{'cnt'} > 0);

		$html =~ s/\\\"/\&quot\;/gs;
		$self->{'title'} = $1  if ($html =~ m#\<title\>\s*([^\|\<]+)#si);
		$self->{'title'} ||= $1  if ($html =~ m#\"(?:og|twitter)\:title\"\s+content\=\"([^\"]+)#s);
		$self->{'description'}   = $1  if ($html =~ m#subtitle\:I\,moreInfoText\:\"([^\"]+)#s);
		$self->{'description'} ||= $self->{'title'};
		$self->{'genre'} = $1  if ($html =~ m#\>Category\<\/td\>\s*\<td[^\>]*\>(.+?)\<\/td\>#s);
		$self->{'genre'} =~ s/^\s+//s;
		$self->{'genre'} =~ s/\s+$//s;
		if ($html =~ m#\>Date\<\/td\>\s*\<td[^\>]*\>(.+?)\<\/td\>#s) {
			$self->{'created'} = $1;
			$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
		}
		foreach my $field (qw(title description)) {
			$self->{$field} = HTML::Entities::decode_entities($self->{$field});
			$self->{$field} = uri_unescape($self->{$field});
			$self->{$field} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/eg;
		}
		$self->{'iconurl'}   = $1  if ($html =~ m#\"(?:og|twitter)\:image\:secure_url\"\s+content\=\"([^\"]+)#s);
		$self->{'iconurl'} ||= $1  if ($html =~ m#\"(?:og|twitter)\:image(?:\:url)?\"\s+content\=\"([^\"]+)#s);
		if ($html =~ s#\<div\s+class\=\"absolute-fill\s+bg\-black(.+?)\<\/div\>##s) {
			my $data = $1;
			$self->{'imageurl'} = $1  if ($data =~ m#\"background\-image\:url\((http[^\)]+)#s);
		}
		$self->{'imageurl'} ||= $self->{'iconurl'};
		$self->{'articonurl'} = $1  if ($html =~ m#\<span\s+class\=\"bg\-cover.+?style\=\"background\-image\:url\((http[^\)]+)#s);
		$self->{'artimageurl'} = $1  if ($html =~ s#\<img\s+src\=\"(http[^\"]+)##s);
		$self->{'artimageurl'} = 'https:' . $self->{'artimageurl'}  if ($self->{'artimageurl'} =~ m#^\/\/#);
		$self->{'articonurl'} ||= $self->{'artimageurl'};
		
		if ($self->{'speakericon'} && $self->{'artimageurl'}) {  #USE PREACHER'S THUMBNAIL (REVERSE articon AND artimage):
			my $x = $self->{'artimageurl'};
			$self->{'artimageurl'} = $self->{'articonurl'};
			$self->{'articonurl'} = $x;
		}
		if ($html =~ s#\<a\s+href\=\"([^\"]*?\/broadcasters?\/[^\/]+\/)\"\s+class\=\"link\"[^\>]*\>([^\<]+)##s) {
			my ($one, $two) = ($1, $2);
			$one = $baseURL . $one  if ($one =~ m#^\/broadcaster#);
			$self->{'albumartist'} = "$two - $one";
		}
		if ($html =~ s#\<a\s+href\=\"([^\"]*?\/speakers?\/\d+\/)\"\s+class\=\"link\"[^\>]*\>([^\<]+)##s) {
			my ($one, $two) = ($1, $2);
			$one = $baseURL . $one  if ($one =~ m#^\/speaker#);
			$self->{'artist'} = $two;
			if ($self->{'albumartist'} && $self->{'albumartist'} !~ m#$one#) {
				$self->{'artist'} .= " - $one";
			} else {
				$self->{'albumartist'} ||= $one;
			}
		}
		if ($self->{'nowebp'}) {
			foreach my $field (qw(iconurl imageurl articonurl artimageurl)) {
				$self->{$field} =~ s#\.(png|jpe?g|gif)\?webp\=true#\.$1#;
			}
		}
		if (!$self->{'artist'} && $html =~ m#\<meta\s+name\=\"description\"\s+content\=\"([^\"]+)"#s) {
			($self->{'artist'} = $1) =~ s/\s+\|.*$//;
		}
		$self->{'album'} = $1  if ($html =~ m#\<meta\s+name\=\"description\"\s+content\=\"([^\"]+)#s);
		$self->{'album'} ||= $1  if ($html =~ m#\<meta\s+property\=\"og\:description\"\s+content\=\"([^\"]+)#s);
		$self->{'album'} =~ s#$self->{'artist'}\s*\|\s*##  if ($self->{'artist'});
		$self->{'albumartist'} ||= $1  if ($html =~ m#href\=\"([^\"]+)\"\>Web\<\/a\>#s);
		$self->{'Url'} = ($self->{'total'} > 0) ? $self->{'streams'}->[0] : '';
		print STDERR "-(all)count=".$self->{'cnt'}."= iconurl=".$self->{'iconurl'}."= TITLE=".$self->{'title'}."= DESC=".$self->{'description'}."= YEAR=".$self->{'year'}."=\n"  if ($DEBUG);
		print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"
				if ($DEBUG && $self->{'cnt'} > 0);
	} else {
		print STDERR "--NOT EPISODE, tried=$tried=\n"  if ($DEBUG);
		if ($tried < 2) {   #WE'RE A PODCAST PAGE!:
			#NOTE:  SERMONAUDIO PODCAST PAGES DO NOT HAVE STREAMS, ONLY EPISODE-IDS+TITLES, SO
			#WE CAN'T CONSTRUCT A PLAYLIST, BUT ONLY GRAB THE 1ST EPISODE AND TRY AND FETCH THAT: :(
			++$tried;
			$html =~ s#^.+?\<div\s+class\=\"wrapper\-element\s##s;
			if ($html =~ s#\<a\s+href\=\"([^\"]*?\/sermons?\/)(\d+)\/?\"##s) {
				my $one = $1;
				$self->{'id'} = $2;
				$one = $baseURL . $one  if ($one =~ m#^\/sermon#);
				$isEpisode = 1;
				$url2fetch = $one . $self->{'id'};
				print STDERR "-!!!!- RETRY w/1ST EPISODE ID=$url2fetch= TITLE=".$self->{'title'}."=\n"  if ($DEBUG);
				goto TRYIT;
			} elsif ($html =~ s#\<a\s+href\=\"([^\"]*?\/series\/)(\d+)\/?\"##s) {
				my $one = $1;
				$self->{'id'} = $2;
				$one = $baseURL . $one  if ($one =~ m#^\/series#);
				$isEpisode = 0;
				$url2fetch = $one . $self->{'id'};
				print STDERR "-!!!!- RETRY w/1ST SERIES ID=$url2fetch= TITLE=".$self->{'title'}."=\n"  if ($DEBUG);
				goto TRYIT;
			}
		}
		return undef  unless ($self->{'total'} > 0);  #NO VALID PAGE FOUND!
	}

	if ($DEBUG) {
		foreach my $i (sort keys %{$self}) {
			print STDERR "--KEY=$i= VAL=".$self->{$i}."=\n";
		}
		print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"
				if ($self->{'cnt'} > 0);
	}

	$self->_log($url);

	bless $self, $class;   #BLESS IT!

	return $self;
}

1
