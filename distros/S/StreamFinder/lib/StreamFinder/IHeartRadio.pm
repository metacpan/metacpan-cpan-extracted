=head1 NAME

StreamFinder::IHeartRadio - Fetch actual raw streamable URLs from radio-station websites on IHeart.com

=head1 AUTHOR

This module is Copyright (C) 2017-2023 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::IHeartRadio;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $station = new StreamFinder::IHeartRadio($ARGV[0], -keep => 
			{'secure_shoutcast', 'secure', 'any'}, -skip => 'rtmp');

	die "Invalid URL or no streams found!\n"  unless ($station);

	my $firstStream = $station->get();

	print "First Stream URL=$firstStream\n";

	my $url = $station->getURL();

	print "Stream URL=$url\n";

	my $stationTitle = $station->getTitle();
	
	print "Title=$stationTitle\n";
	
	my $stationDescription = $station->getTitle('desc');
	
	print "Description=$stationDescription\n";
	
	my $stationID = $station->getID();

	print "Station ID=$stationID\n";
	
	my $artist = $station->{'artist'};

	print "Artist=$artist\n"  if ($artist);
	
	my $genre = $station->{'genre'};

	print "Genre=$genre\n"  if ($genre);
	
	my $icon_url = $station->getIconURL();

	if ($icon_url) {   #SAVE THE ICON TO A TEMP. FILE:

		my ($image_ext, $icon_image) = $station->getIconData();

		if ($icon_image && open IMGOUT, ">/tmp/${stationID}.$image_ext") {

			binmode IMGOUT;

			print IMGOUT $icon_image;

			close IMGOUT;

		}

	}

	my $stream_count = $station->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $station->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::IHeartRadio accepts a valid radio station or podcast ID or URL on 
IHeart.com (formerly known as IHeartRadio.com) and returns the actual stream 
URL(s), title, and cover art icon.  The purpose is that one needs one of these 
URLs in order to have the option to stream the station in one's own choice of 
media player software rather than using their web browser and accepting 
any / all flash, ads, javascript, cookies, trackers, web-bugs, and other 
crapware that can come with that method of play.  The author uses his own 
custom all-purpose media player called "fauxdacious" (his custom hacked version 
of the open-source "audacious" audio player).  "fauxdacious" can incorporate 
this module to decode and play IHeart.com streams.

One or more stream URLs can be returned for each station or podcast.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-keep|-skip> => I<streamtypes>] 
[, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ] ... ])

Accepts an iheart.com station / podcast ID or URL and creates and returns 
a new station (or podcast) object, or I<undef> if the URL is not a valid IHeart 
station or podcast, or no streams are found.  The URL can be the full URL, 
ie. https://www.iheart.com/live/B<station-id>, 
https://B<station-id>.iheart.com, 
https://www.iheart.com/podcast/B<podcast-id>/episode/B<episode-id>, 
https://www.iheart.com/podcast/B<podcast-id>, or just 
B<station-id>, or B<podcast-id/episode-id>.  NOTE:  For podcasts, you must 
include the I<episode-id> if not specifying a full URL, otherwise, the 
I<podcast-id> will be interpreted as a I<station-id> (and you likely won't get 
any streams), but if specifying a full URL and no I<episode-id> is specified, 
the first (latest) episode for the podcast channel is returned.

I<-keep> and I<-skip> specify a list of one or more I<streamtypes> to either 
include or skip respectively.  The list for each can be either a 
comma-separated string or an array reference ([...]) of stream types, in the 
order they should be returned.  Each stream type in the list can be one of:  
any, secure, secure_pls, pls, secure_hls, hls, secure_shortcast, shortcast, 
secure_rtmp, rtmp, (I<ext>, ie. mp4) etc.  NOTE:  If you specify the I<-secure> 
option, described below, as 1 (true), and only non-secure* options above for 
I<-keep>, you won't get any streams!

DEFAULT I<-keep> list is 'secure_shoutcast, shoutcast, secure, any', meaning 
that all secure_shoutcast (https:) streams followed by any other shoutcast 
streams, then all other secure (https:) streams, followed by any remaining 
(http:) streams (.m3u8, etc.).  More than one value can be specified to 
control order of search.

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  
If 1 then only secure ("https://") streams will be returned.

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
stream found.  [site]:  The site name (IHeartRadio).  [url]:  The url 
searched for streams.  [time]: Perl timestamp when the line was logged.  
[title], [artist], [album], [description], [year], [genre], [total], 
[albumartist]:  The corresponding field data returned (or "I<-na->", 
if no value).

=item $station->B<get>()

Returns an array of strings representing all stream URLs found.

=item $station->B<getURL>([I<options>])

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

=item $station->B<count>()

Returns the number of streams found for the station / podcast episode.

=item $station->B<getID>(['fccid'])

Returns the station's IHeartRadio ID (default) or station's FCC 
call-letters ("fccid").  For stations, the IHeartRadio ID is a single value.  
For individual podcast episodes it's two values separated by a slash ("/").

=item $station->B<getTitle>(['desc'])

Returns the station's title, or (long description).  Podcasts 
on IHeartRadio can have separate descriptions, but for stations, 
it is always the station's title.

=item $station->B<getIconURL>(['artist'])

Returns the URL for the station's "cover art" icon image, if any.
If B<'artist'> is specified, the podcast channel artist's icon url 
is returned, if any.  NOTE:  The B<'artist'> option will return an 
empty string unless the station is a podcast.

=item $station->B<getIconData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.
If B<'artist'> is specified, the podcast channel artist's icon data 
is returned, if any.  NOTE:  The B<'artist'> option will return an 
empty string unless the station is a podcast.

=item $station->B<getImageURL>(['artist'])

Returns the URL for the station's "cover art" (usually larger) 
banner image.  NOTE:  For IHeart podcasts, this will be the same as the 
icon url.
If B<'artist'> is specified, the podcast channel artist's image url 
is returned, if any.  NOTE:  The B<'artist'> option will return an 
empty string unless the station is a podcast.

=item $station->B<getImageData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual station's banner image (binary data).
NOTE:  For IHeart podcasts, this will be the same as the icon url.
If B<'artist'> is specified, the podcast channel artist's image data 
is returned, if any.  NOTE:  The B<'artist'> option will return an 
empty string unless the station is a podcast.

=item $station->B<getType>()

Returns the station's type ("IHeartRadio").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/IHeartRadio/config

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

Among options valid for IHeartRadio streams are the I<-keep> and 
I<-skip> options described in the B<new()> function.

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

iheartradio

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-streamFinder-iheartradio at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-IHeartRadio>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::IHeartRadio

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-IHeartRadio>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-IHeartRadio>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-IHeartRadio>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-IHeartRadio/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2023 Jim Turner.

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

package StreamFinder::IHeartRadio;

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

	my $self = $class->SUPER::new('IHeartRadio', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});

	my (@okStreams, @skipStreams);
	while (@_) {
		if ($_[0] =~ /^\-?keep$/o) {
			shift;
			if (defined $_[0]) {
				my $keeporder = shift;
				@okStreams = (ref($keeporder) =~ /ARRAY/) ? @{$keeporder} : split(/\,\s*/, $keeporder);
			}
		} elsif ($_[0] =~ /^\-?skip$/o) {
			shift;
			if (defined $_[0]) {
				my $skiporder = shift;
				@skipStreams = (ref($skiporder) =~ /ARRAY/) ? @{$skiporder} : split(/\,\s*/, $skiporder);
			}
		} else {
			shift;
		}
	}
	if (!defined($okStreams[0]) && defined($self->{'keep'})) {
		@okStreams = (ref($self->{'keep'}) =~ /ARRAY/) ? @{$self->{'keep'}} : split(/\,\s*/, $self->{'keep'});
	}
	if (!defined($skipStreams[0]) && defined($self->{'skip'})) {
		@skipStreams = (ref($self->{'skip'}) =~ /ARRAY/) ? @{$self->{'skip'}} : split(/\,\s*/, $self->{'skip'});
	}
	@okStreams = (qw(secure_shoutcast shoutcast secure any))  unless (defined $okStreams[0]);  # one of:  {secure_pls | pls | stw}

	print STDERR "-0(IHeartRadio): URL=$url= KEEP=(",join('|',@okStreams).") SKIP=(",join('|',@skipStreams).")\n"  if ($DEBUG);

	my $url2fetch = $url;
	if ($url =~ /^https?\:/) {
		$self->{'id'} = $1  if ($url2fetch =~ m#\/([^\/]+)\/?$#);
		if ($url2fetch =~ m#\/episode\/#) {
			my $id = $1  if ($url2fetch =~ m#([^\/]+)\/episode\/#);
			$self->{'id'} = $id . '/' . $self->{'id'}  if ($id);
		}
	} else {
		$self->{'id'} = $url2fetch;
		my ($id, $podcastid) = split(m#\/#, $url2fetch);
		$url2fetch = $podcastid ? "https://www.iheart.com/podcast/$id" : "https://${id}.iheart.com/";
		$url2fetch .= '/episode/' . $podcastid  if ($podcastid);
	}
	return undef  unless ($self->{'id'});  #STEP 1 FAILED, INVALID STATION URL, PUNT!

	my $html = '';
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	my $response;

	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	print STDERR "-1 FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	if ($url2fetch =~ m#\.iheart\.com\/?$#) { #URL FORMAT:  https://station.iheart.com (SEE CPAN BUG# 133982):
		$response = $ua->get($url2fetch);
		if ($response->is_success) {
			$html = $response->decoded_content;
		} else {
			print STDERR $response->status_line  if ($DEBUG);
		}
		$url2fetch = '';
		print STDERR "-1a: html=$html=\n"  if ($DEBUG > 1);
		if ($html && $html =~ m#\<div\s+class\=\"play\-icon\"\>([^\>]+)#s) {
			my $playHtml = $1;
			if ($playHtml =~ m#href\=\"([^\"]+)#s) {
				my $playlink = $1;
				if ($playlink =~ m#\/live\/([a-z0-9\-]+)#) {
					$self->{'id'} = $1;
					$url2fetch = $playlink;
					print STDERR "-1a FETCHING REDIRECTED URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
				}
			}
		}
		#IF NO REDIRECT FOUND, RESET TO CONVENTIONAL "live" URL AND TRY THAT:
		$url2fetch ||= 'https://www.iheart.com/live/' . $self->{'id'};
	}

	print STDERR "-1: FINAL FETCH URL=$url2fetch=\n"  if ($DEBUG);
	my $tryit = 0;
TRYIT:
	$response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html && $self->{'id'});  #STEP 1 FAILED, INVALID STATION URL, PUNT!

	my $html2 = '';
	my $streamhtml0 = ($html =~ /\"streams\"\s*\:\s*\{([^\}]+)\}/) ? $1 : '';
	print STDERR "-2: streamhtml=$streamhtml0=\n"  if ($DEBUG);
	unless ($streamhtml0) {  #NO STREAMS (PODCAST?) - LOOK FOR MEDIAURL:
		while ($html =~ s#\"mediaUrl\"\:\"([^\"]+)\"##gso) {
			my $one = $1;
			unless ($self->{'secure'} && $one !~ /^https/o) {
				push @{$self->{'streams'}}, $one;
				$self->{'cnt'}++;
			}
		}
		unless ($tryit || $self->{'cnt'} > 0) {
			print "--no streams found, ID=".$self->{'id'}."= url=$url2fetch= PODCAST PAGE, MAYBE?\n"  if ($DEBUG);
			my $episodeID = '';
			my $episodeList = '';
			my $firstEpisode = ($html =~ m#\"episodes\"\:\{\"([\d]+)\"\:#s) ? $1 : '';
			if ($html =~ m#\"\,\"url\"\:\"\/podcast\/$self->{'id'}\/?\"\,\"episodeIds\"\:\[([^\]]+)\]#s) {
				$episodeList = $1;
				if ($firstEpisode && $episodeList =~ /\b$firstEpisode$/) {  #THE EPISODE LIST IS IN REVERSE ORDER!:
					($episodeID = $episodeList) =~ s/\D.*$//;  #WE WANT THE FIRST ONE.
				} elsif ($episodeList =~ /(\d+)$/) {
					$episodeID = $1;
				}
			} elsif ($firstEpisode) {
				while ($html =~ s#\"episodeIds\"\:\[([^\]]+)\]##s) {
					$episodeList = $1;
					if ($episodeList =~ /\b$firstEpisode$/) {  #THE EPISODE LIST IS IN REVERSE ORDER!:
						($episodeID = $episodeList) =~ s/\D.*$//;  #WE WANT THE FIRST ONE.
						last;
					}
				}
			}
			$episodeID ||= $firstEpisode;
			if ($episodeID) {
				if ($html =~ m#\<h1[^\>]*\>([^\<]+)#si) {
					$self->{'artist'} = $1;
					while ($html =~ s#\<img([^\>]+)\>##si) {
						my $imgdata = $1;
						if ($imgdata =~ m#\balt\=\"$self->{'artist'}\"#
								&& $imgdata =~ m#\bsrc\=\"([^\"]+)#) {
							$self->{'artimageurl'} = $self->{'articonurl'} = $1;
							$self->{'articonurl'} =~ s/\?.*$//;
							last;
						}
					}
				}
				$url2fetch =~ s#\/$##;
				$url2fetch .= "/episode/$episodeID";
				$self->{'id'} .= "/$episodeID";
				print STDERR "----TRY AGAIN w/($url2fetch) ID=".$self->{'id'}."=\n"  if ($DEBUG);
				++$tryit;
				goto TRYIT;
			}
		}
		return undef  unless ($self->{'cnt'} > 0);

		unless ($self->{'articonurl'}) {
			if ($html =~ m#\"image\"\:\"([^\"]+)\"\,\"url\"\:#s) {
				$self->{'artimageurl'} = $self->{'articonurl'} = $1;
				$self->{'articonurl'} =~ s/\?.*$//;
				print STDERR "--found channel art url=".$self->{'articonurl'}."=\n"  if ($DEBUG);
			}
		}
		my $id = $url;
		$id =~ s#\/$##;
		$id = $1  if ($id =~ m#([^\/]+)\/episode\/#);
		my $seedID = ($id =~ /(\d+)$/) ? $1 : '';  #NUMERIC PART
		$self->{'title'} = $1  if ($html =~ s# rel\=\"alternate\"\s+title\=\"([^\"]+)\"##s);
		$self->{'title'} ||= ($html =~ s#\<title[^\>]+\>([^\<]+)\<\/title\>##s) ? $1 : '';
		if ($html =~ m#\bitemProp\=\"podcastDescription\"\>(.+?)\<\/div\>#s) {
			$self->{'description'} = $1;
		}
		$self->{'description'} ||= $1  if ($html =~ s#\"description\"\:\"([^\"]+)##s);
		$self->{'description'} ||= $1  if ($html =~ s#\"podcastDescription\"\>\<p\>(.+?)\<\/p\>##s);
#		$self->{'description'} ||= ($html =~ s#\"podcastDescription\"\>(?:\<[^\>]+\>)?([^\<]+)##s) ? $1 : $self->{'title'};
		$self->{'description'} ||= $self->{'title'};
		$self->{'description'} = HTML::Entities::decode_entities($self->{'description'});
		$self->{'description'} = uri_unescape($self->{'description'});
		($self->{'albumartist'} = $url) =~ s#\/episode.+$##;
		if ($seedID) {
			my $albumHtml = $1  if ($html =~ m#\"seedShowId\"\:$seedID([^\}]+)#);
			if ($albumHtml) {
				$self->{'artist'} = $1  if ($albumHtml =~ m#\"title\"\:\"([^\"]+)#);
			}
		}
		if ($html =~ m#\<span class\=\"css\-\w+ \w+\"\>\<span\>([^\<]+)\<\/span\>\<\/span\>\<\/a\>\</div\>\<span\>\<div class\=\"css\-\w+ \w+\"\>([^\<]+)\<\!\-\- \-\-\>#) {
			$self->{'title'} = $1;
			$self->{'created'} = $2;
			$self->{'year'} = ($self->{'created'} =~ /(\d\d\d\d)/) ? $1 : '';
			print STDERR "i:Found better title (".$self->{'title'}."), year (".$self->{'year'}.").\n"  if ($DEBUG);
		}
		$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
		$self->{'title'} = uri_unescape($self->{'title'});
		if ($html =~ m#\<h1[^\>]*\>([^\<]+)#s) {
			$self->{'artist'} = $1;
			$self->{'artist'} = HTML::Entities::decode_entities($self->{'artist'});
			$self->{'artist'} = uri_unescape($self->{'artist'});
			print STDERR "i:Found artist name (".$self->{'artist'}.").\n"  if ($DEBUG);
		}
		$self->{'year'} = ($html =~ m#\<p\>.*?\xa9\s*(\d\d\d\d)#s) ? $1 : '';
		$self->{'year'} ||= $1  if ($html =~ m#(\d\d\d\d)\<\!\-\-#s);
		$self->{'genre'} = 'Podcast';
		$self->{'imageurl'} = ($html =~ s#\"imageUrl\"\:\"([^\"]+)\"##s) ? $1 : '';
		$self->{'iconurl'} = $self->{'imageurl'};
		$self->{'total'} = $self->{'cnt'};
		if ($DEBUG) {
			foreach my $i (sort keys %{$self}) {
				print STDERR "--KEY=$i= VAL=".$self->{$i}."=\n";
			}
			print STDERR "-SUCCESS2: 1st stream=".$self->{'Url'}."=\n";
		}

		$self->_log($url);

		bless $self, $class;   #BLESS IT!

		return $self;
	}

	$self->{'fccid'} = ($html =~ m#\"callLetters\"\s*\:\s*\"([^\"]+)\"#is) ? $1 : '';
	$self->{'title'} = ($html =~ m#\"stationName\"\s*\:\s*\"([^\"]+)\"#s) ? $1 : $url;
	$self->{'title'} = $1  if ($html =~ m#\"broadcastDisplayName\"\s*\:\s*\"([^\"]+)\"#s);
	$self->{'title'} =~ s#http[s]?\:\/\/www\.iheart\.com\/live\/##;
	$self->{'description'} = ($html =~ m#\"description\"\s*\:\s*\"([^\"]+)\"#s) ? $1 : $self->{'title'};
	$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
	$self->{'title'} = uri_unescape($self->{'title'});
	$self->{'description'} = HTML::Entities::decode_entities($self->{'description'});
	$self->{'description'} = uri_unescape($self->{'description'});
	$self->{'imageurl'} = ($html =~ m#\"image_src\"\s+href=\"([^\"]+)\"#s) ? $1 : '';
	$self->{'iconurl'} = ($html =~ m#\,\"logo\"\:\"([^\"]+)\"\,\"freq\"\:#s) ? $1 : '';
	$self->{'imageurl'} ||= $self->{'iconurl'};
	$self->{'genre'} = $1  if ($html =~ m#\"Genre\"\s+name\=\"twitter\:label1\"\/\>\<meta\s+data\-react\-helmet\=\"[^\"]*\"\s+content\=\"([^\"]+)\"#s);
	if ($self->{'genre'}) {
		$self->{'genre'} = HTML::Entities::decode_entities($self->{'genre'});
		$self->{'genre'} = uri_unescape($self->{'genre'});
	}

	my ($streamhtml, $streampattern);
	my %streams = ();
	my $weight = 999;

	# OUTTERMOST LOOP TO TRY EACH STREAM-TYPE: (CONSTRAINED IF USER SPECIFIES STREAMTYPES AS EXTRA ARGS TO new())
	foreach my $streamtype (@okStreams) {
		print STDERR "--OUTTER: type=$streamtype=\n"  if ($DEBUG);
		$streamhtml = $streamhtml0;
		$streampattern = $streamtype;
		if ($streamtype eq 'secure') {
			$streampattern = '\"secure_\w+';
		} elsif ($streamtype eq 'any') {
			$streampattern = '\"\w+';
		} else {
			$streampattern = '\"' . $streamtype;
		}
		$self->{'cnt'} = 0;
		# INNER LOOP: MATCH STREAM URLS BY TYPE PATTEREN REGEX UNTIL WE FIND ONE THAT'S ACCEPTABLE (NOT EXCLUDED TYPE):
		print STDERR "-3: PATTERN=${streampattern}_stream=\n"  if ($DEBUG);
INNER:  while ($streamhtml =~ s#(${streampattern}_stream)\"\s*\:\s*\"([^\"]+)\"##)
		{
			print STDERR "----INNER: type=$streampattern=\n"  if ($DEBUG);
			$self->{'streamtype'} = substr($1, 1);
			$self->{'streamurl'} = $2;
			foreach my $xp (@skipStreams) {
				next INNER  if ($self->{'streamtype'} =~ /$xp/);  #REJECTED STREAM-TYPE.
			}

			# WE NOW HAVE A STREAM THAT MATCHES OUR CONSTRAINTS:
			# IF IT'S A ".pls" (PLAYLIST) STREAM, WE NEED TO FETCH THE LIST OF ACTUAL STREAMS:
			# streamurl WILL STILL CONTAIN THE PLAYLIST STREAM ITSELF!
			if ($self->{'streamurl'} && $self->{'streamtype'} =~ /pls/) {
				$self->{'plsid'} = $1  if ($self->{'streamurl'} =~ m#\/([^\/]+)\.pls$#i);
				print STDERR "---4: PLS stream id=".$self->{'plsid'}."= URL=".$self->{'streamurl'}."\n"  if ($DEBUG);
				$response = $ua->get($self->{'streamurl'});
				if ($response->is_success) {
					$html = $response->decoded_content;
				} else {
					$html = '';
					print STDERR $response->status_line  if ($DEBUG);
				}
				while ($html =~ s#File\d+\=(\S+)##) {
					$streams{$1} = $weight  unless (defined $streams{$1});
					print STDERR "-----5: Adding PLS stream ($1) ($weight)!\n"  if ($DEBUG);
					++$self->{'cnt'};
					--$weight;
				}
			}
			else  #NON-pls STREAM, WE'LL HAVE A LIST CONTAINING A SINGLE STREAM:
			{
				$streams{$self->{'streamurl'}} = $weight  unless (defined $streams{$self->{'streamurl'}});
				print STDERR "-----6: Adding ".$self->{'streamtype'}." stream (".$self->{'streamurl'}.") ($weight)!\n"  if ($DEBUG);
				++$self->{'cnt'};
				--$weight
			}
		}
		last  if ($streamtype eq 'any');  #"any" SHOULD ALWAYS BE THE LAST ONE TO TRY!
		$weight -= 100;
	}
	return undef  unless ($self->{'cnt'});   #STEP 2 FAILED - NO PLAYABLE STREAMS FOUND, PUNT!

	#$self->{'streams'} = \@streams;  #WE'LL HAVE A LIST OF 'EM TO RANDOMLY CHOOSE ONE FROM:
	#$self->{'total'} = $self->{'cnt'};
	$self->{'total'} = 0;
	foreach my $s (sort {$streams{$b} <=> $streams{$a}} keys %streams) {
		unless ($self->{'secure'} && $s !~ /^https/o) {
			push @{$self->{'streams'}}, $s;
			print STDERR "++++ ADDING STREAM(".$streams{$s}."): $s\n"  if ($DEBUG);
			++$self->{'total'};
		}
	}
	$self->{'Url'} = ($self->{'total'} > 0) ? $self->{'streams'}->[0] : '';
	if ($DEBUG) {
		foreach my $i (sort keys %{$self}) {
			print STDERR "--KEY=$i= VAL=".$self->{$i}."=\n";
		}
		print STDERR "-SUCCESS: 1st stream=".$self->{'Url'}."=\n";
	}

	$self->_log($url);

	bless $self, $class;   #BLESS IT!

	return $self;
}

1
