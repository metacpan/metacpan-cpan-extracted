=head1 NAME

StreamFinder::PodcastAddict - Fetch actual raw streamable URLs on podcastaddict.com

=head1 AUTHOR

This module is Copyright (C) 2023 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::PodcastAddict;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $podcast = new StreamFinder::PodcastAddict($ARGV[0]);

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
	
	my $artist = $podcast->{'artist'};

	print "Artist=$artist\n"  if ($artist);
	
	my $genre = $podcast->{'genre'};

	print "Genre=$genre\n"  if ($genre);
	
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

StreamFinder::PodcastAddict accepts a valid podcast ID or URL on 
PodcastAddict.com and returns the actual stream URL(s), title, and cover art icon.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the podcast in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of play.  The author uses his own custom all-purpose media player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
PodcastAddict.com streams.

One or more stream URLs can be returned for each podcast.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ]])

Accepts a podcastaddict.com podcast ID or URL and creates and returns a 
a new podcast object, or I<undef> if the URL is not a valid podcast, or no streams 
are found.  The URL can be the full URL, ie. 
https://podcastaddict.com/episode/B<episode-id#>, 
https://podcastaddict.com/podcast/B<podcast-id#>, or just 
I<episode-id#>.

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  If 1 
then only secure ("https://") streams will be returned.

DEFAULT I<-secure> is 0 (false) - return all streams (http and https).

Additional options:

I<-log> => "I<logfile>"

Specify path to a log file.  If a valid and writable file is specified, A line will be 
appended to this file every time one or more streams is successfully fetched for a url.

DEFAULT I<-none-> (no logging).

I<-logfmt> specifies a format string for lines written to the log file.

DEFAULT "I<[time] [url] - [site]: [title] ([total])>".  

The valid field I<[variables]> are:  [stream]: The url of the first/best stream found.  
[site]:  The site name (PodcastAddict).  [url]:  The url searched for streams.  
[time]: Perl timestamp when the line was logged.  [title], [artist], [album], 
[description], [year], [genre], [total], [albumartist]:  The corresponding field data 
returned (or "I<-na->", if no value).

=item $podcast->B<get>(['playlist'])

Returns an array of strings representing all stream URLs found.
If I<"playlist"> is specified, then an extended m3u playlist is returned 
instead of stream url.  NOTE:  If an author / channel page url is given, 
rather than an individual podcast episode's url, get() returns the first 
(latest?) podcast episode found, and get("playlist") returns an extended 
m3u playlist containing the urls, titles, etc. for all the podcast 
episodes found on that page url.

=item $podcast->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  There currently are no valid I<options>.

=item $podcast->B<count>(['playlist'])

Returns the number of streams found for the podcast.
If I<"playlist"> is specified, the number of episodes returned in the 
playlist is returned (the playlist can have more than one item if a 
podcast page URL is specified).

=item $podcast->B<getID>()

Returns the podcast's PodcastAddict ID (default).  For podcasts, the PodcastAddict ID 
is a single value.  For individual podcast episodes it's two values 
separated by a slash ("/").

=item $podcast->B<getTitle>(['desc'])

Returns the podcast's title, or (long description).  Podcasts 
on PodcastAddict can have separate descriptions, but for podcasts, 
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

=item $podcast->B<getImageURL>()

Returns the URL for the podcast's "cover art" (usually larger) 
banner image.

=item $podcast->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual podcast's banner image (binary data).

=item $podcast->B<getType>()

Returns the podcast's type ("PodcastAddict").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/PodcastAddict/config

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

podcastaddict

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-iheartradio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-PodcastAddict>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::PodcastAddict

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-PodcastAddict>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-PodcastAddict>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-PodcastAddict>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-PodcastAddict/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2023 Jim Turner.

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

package StreamFinder::PodcastAddict;

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

	my $self = $class->SUPER::new('PodcastAddict', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});
	$self->{'id'} = '';
	$self->{'_podcast_id'} = '';
	my $url2fetch = $url;
	my $tried = 0;
	my @epiTitles = ();
	my @epiStreams = ();
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $html = '';
	my $response;
	my $isEpisode;

#NOTE:  THE ONLY "EPISODE" URLS NOW USED BY PODCASTADDICT ARE THE URI-ESCAPED ONES CONTAINING
#THE STREAM URL EMBEDDED IN THEIR PODCAST PAGES (WITH NO EPISODE-ID#) AND HAVE THE FORMAT (EXAMPLE):
#"https://podcastaddict.com/episode/https%3A%2F%2Fpscrb.fm%2Frss%2Fp%2Fpdst.fm%2Fe%2Farttrk.com%2Fp%2FABMA5%2Faudioboom.com%2Fposts%2F8280770.mp3%3Fmodified%3D1681401989%26sid%3D2399216%26source%3Drss&podcastId=1719501"
#TO PREVENT USING THE FULL STREAM-URL FOR THE UNIQUE EPISODE-ID#, WE JUST USE THE PODCAST-ID#.
#NO KNOWN WAY EXISTS FOR FETCHING EPISODES VIA JUST A PODCAST AND EPISODE-ID, THEREFORE WE CAN'T
#DETERMINE WHAT THE REAL EPISODE-ID IS, EXCEPT ON PODCAST PAGES STILL USING THE CLASSIC, UNESCAPED
#EPISODE-URLS (format:  "https://podcastaddict.com/episode/<episode-ID-number>")!
#(NOTE ALSO THAT THE "&podcastId=#####" PART OF THE URL IS *NOT* THE SEARCHABLE PODCAST-ID EITHER,
#BUT RATHER THE PODCAST ARTIST'S/CHANNEL ID#)!

TRYIT:
	if ($url2fetch =~ m#^([0-9]+)$#) {  #ASSUME PODCAST-ID, AS EPISODES NO LONGER HAVE DESCERNABLE IDs:
		$self->{'id'} = $1;
		$url2fetch = 'https://podcastaddict.com/podcast/'.$self->{'id'};
		$isEpisode = 0;
		print STDERR "-1- PODCAST ID, ID=".$self->{'id'}."= found ($url2fetch)\n"  if ($DEBUG);
	} elsif ($url2fetch =~ m#\/episode\/https?#) { #(LONG) EPISODE URL (ON PODCAST PAGES, ESCAPED):
		$url2fetch = uri_escape($url2fetch)  unless($url2fetch =~ m#\%3A#);  #PODCASTADDICT EPISODE URLS NOW MUST BE URI-ESCAPED!
		#$self->{'id'} IS NOT EMBEDDED OR DETERMINABLE, WILL SET TO PODCAST-ID LATER!
		$isEpisode = 1;
		print STDERR "-2- EPISODE URL, ID=UNKNOWN= found ($url2fetch)\n"  if ($DEBUG);
	} elsif ($url2fetch =~ m#\/episode\/(\d+)\/?$#) {  #CLASSIC (SHORT) EPISODE URL WITH ID. (DEPRECIATED)
		$self->{'id'} = $1;  #CLASSIC EPISODE URLS HAVE A PROPER EPISODE-ID EMBEDDED!
		$isEpisode = 1;
		print STDERR "-3- CLASSIC EPISODE URL, ID=".$self->{'id'}."= found ($url2fetch)\n"  if ($DEBUG);
	} elsif ($url2fetch =~ m#\/podcast\/#) {  #PODCAST URL
		$self->{'id'} = $1;  #USE UNIQUE NUMBER AS A MADE-UP "EPISODE-ID"
		$isEpisode = 0;
		print STDERR "-4- PODCAST URL, ID=".$self->{'id'}."= found ($url2fetch)\n"  if ($DEBUG);
	} else {
		return undef;  #INVALID ID/URL!
	}

	$html = '';
	print STDERR "-0(PodcastAddict): ($tried) FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	$response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html);  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!

	$self->{'genre'} = 'Podcast';
	print STDERR "---ID=".$self->{'id'}."= tried=$tried=\n"  if ($DEBUG);
	unless ($isEpisode) {   #PODCAST PAGE ID (FETCH XML PAGE):
		print STDERR "-----WE'RE A PODCAST PAGE: ID=".$self->{'id'}."!\n"  if ($DEBUG);

		#FETCH PODCAST-WIDE METADATA HERE!:
		$self->{'albumartist'} = $url2fetch;
		$self->{'albumartist'} = $1  if ($html =~ m#\<meta\s+property\=\"(?:og|twitter)\:url\"\s+content\=\"([^\"]+)\"\>#s);
		$self->{'id'} = $1  if ($self->{'albumartist'} =~ m#(\d+)\/?$#);
		if ($html =~ m#\<div\s+class\=\"headerThumbnail\"\>(.+?)\<\/div\>#s) {
			my $thumbnaildata = $1;
			$self->{'articonurl'} = $1  if ($thumbnaildata =~ m#\<img\s+src\=\"([^\"]+)#s);
			$self->{'iconurl'} = $self->{'articonurl'};
			$self->{'imageurl'} = $self->{'articonurl'};
		}
		$self->{'artist'} = $1  if ($html =~ m#name\=\"author\"\s+class\=\"[\w\-]+\"\s+value\=\"([^\"]+)#);
		$self->{'album'} = $1  if ($html =~ m#\<meta\s+itemprop\=\"name\"\s+content\=\"([^\"]+)#s);

		#WE NEED TO EXTRACT 1ST EPISODE ID, BUT WHILST AT IT, GO AHEAD AND FETCH PLAYLIST DATA HERE TOO!:
		my $ep1id = '';
		while ($html =~ s#^.+?\<div\s+class\=\"cellcontent\"\s+itemscope\>##s) {
			if ($html =~ m#\<a\s+class\=\"clickeableItem\"\s+href\=\"([^\"]+)#) {
				my $streamURL = $1;
				(my $stream = uri_unescape($streamURL)) =~ s#^https?\:\/\/podcastaddict\.\w+\/episode\/##o;
				next  if ($self->{'secure'} && $stream !~ /^https/o);

				$ep1id ||= $streamURL;
				$stream =~ s#\?utm_source=Podcast.*$##o;
				$stream =~ s#[\?\&]from\=PodcastAddict$##o;
				$stream =~ s#\.mp3\?.*$#\.mp3#o;
				if ($html =~ m#\<h5\>(.+?)\<\/h5\>#o) {
					my $title = $1;
					push @epiStreams, $stream;
					push @epiTitles, $title;
				}
			}
		}
		if ($ep1id) {   #WE FOUND AN EPISODE, SO RETRY (TO FETCH THE EPISODE PAGE):
			++$tried;
			$url2fetch = $ep1id;
			print STDERR "-!!!!- RETRY w/1ST EPISODE URL=$url2fetch=\n"  if ($DEBUG);
			goto TRYIT;
		} else {
			print STDERR "e:Podcast ($url2fetch) has no episodes!\n";
		}
	} else {   #EPISODE PAGE ID (NOW GET THE DETAILED EPISODE METADATA & WE'RE DONE):
		print STDERR "-----WE'RE AN EPISODE PAGE: ID=".$self->{'id'}."!\n"  if ($DEBUG);
		if ($html =~ m#\<h1\>(.+?)\<\/h1\>#s) {
			my $h1data = $1;
			if ($h1data =~ m#\<a\s+href\=\"([^\"]+)#s) {
				$self->{'albumartist'} = $1;
				my $channelID = $1  if ($self->{'albumartist'} =~ m#\/(\d+)$#);  #USE PODCAST'S ID FOR ARTIST ICON.
				$self->{'id'} ||= $channelID;  #USE PODCAST'S ID SINCE NEWER (LONG) EPISODES DON'T HAVE ONE.
				$self->{'articonurl'} ||= 'https://podcastaddict.com/cache/artwork/thumb/'.$channelID;
			}
			#NOTE:  podcastaddict DOES NOT INCLUDE THE PODCAST ALBUM'S NAME IN EPISODE PAGES.
			#IF WE ALREADY HAVE (THE CORRECT) ALBUM FIELD, IT MEANS WE FETCHED A PODCAST 
			#PAGE FIRST AND HERE WE'RE FETCHING THE 1ST EPISODE, SO LEAVE 'EM ALONE (THEY'RE CORRECT)!:
			#(FOR REFERENCE, NORMALLY THE "ARTIST" IS THE PODCAST'S ARTIST'S NAME, AND ALBUM IS THE 
			#PODCAST'S NAME (AN ARTIST CAN HAVE MULTIPLE PODCASTS & A PODCAST CAN HAVE MULT. EPISODES)!)
			$self->{'artist'} ||= $1  if ($h1data =~ m#\>(.+?)\<\/a\>#s);
		}
		$self->{'title'} = $1  if ($html =~ m#\<h4\>(.+?)\<\/h4\>#s);
		$self->{'imageurl'} = $1  if ($html =~ m#Artwork\"\s+src\=\"([^\"]+)#s);
		$self->{'imageurl'} ||= $1  if ($html =~ m#\<meta\s+property\=\"og\:image\"\s+content\=\"([^\"]+)#);
		$self->{'iconurl'} = $self->{'imageurl'};
		$self->{'articonurl'} ||= $self->{'imageurl'};
		if ($html =~ m#\<i class\=\"fa fa\-calendar\"\>\<\/i\>(.*?)(\d\d\d\d)\<\/span\>#) {
			$self->{'year'} = $2;
			($self->{'created'} = $1 . $2) =~ s/^\s+//;
		}
		$self->{'description'} = $1  if ($html =~ m#\<meta\s+property\=\"og\:description\"\s+content\=\"(.+?)\"\>#);
		while ($html =~ s#\<video(.+?)</video>##sio) {   #GRAB ANY VIDEO STREAMS (PODCASTADDICT SUPPORTS VIDEO PODCASTS!):
			my $videodata = $1;
			my $stream = $1  if ($videodata =~ m#src\=\"([^\"]+)#s);
			if ($stream) {
				next  if ($self->{'secure'} && $stream !~ /^https/o);

				$stream =~ s#\?utm\_source\=.*$##o;
#				$stream =~ s#\&from\=PodcastAddict##o;
				$stream =~ s#[\?\&]from\=PodcastAddict$##o;
				$stream =~ s#\.mp3\?.*$#\.mp3#o;
				push @{$self->{'streams'}}, $stream;
				$self->{'cnt'}++;
			}
		}
		while ($html =~ s#\<audio(.+?)</audio>##sio) {   #GRAB ANY AUDIO STREAMS:
			my $audiodata = $1;
			my $stream = $1  if ($audiodata =~ m#src\=\"([^\"]+)#s);
			if ($stream) {
				next  if ($self->{'secure'} && $stream !~ /^https/o);

				$stream =~ s#\?utm\_source\=.*$##o;
				$stream =~ s#[\?\&]from\=PodcastAddict$##o;
				$stream =~ s#\.mp3\?.*$#\.mp3#o;
				push @{$self->{'streams'}}, $stream;
				$self->{'cnt'}++;
			}
		}
	}

	$self->{'total'} = $self->{'cnt'};
	$self->{'Url'} = ($self->{'total'} > 0) ? $self->{'streams'}->[0] : '';

	if ($DEBUG) {
		print STDERR "-(all)count=".$self->{'total'}."= ID=".$self->{'id'}."=\n";
		foreach my $f (sort keys %{$self}) {
			print STDERR "--field($f)=".$self->{$f}."=\n";
		}
		foreach my $s (@{$self->{'streams'}}) {
			print STDERR "-----stream=$s=\n";
		}
	}
	return undef  unless ($self->{'cnt'} > 0);

	#GENERATE EXTENDED-M3U PLAYLIST (NOTE: MAY NOT BE ABLE TO UNTIL USER CALLS $podcast->get('playlist')!):

	$self->{'playlist'} = "#EXTM3U\n";
	if ($#epiStreams >= 0) {
		$self->{'playlist_cnt'} = scalar @epiStreams;
		for (my $i=0;$i<=$#epiStreams;$i++) {

			last  if ($i > $#epiTitles);
			$self->{'playlist'} .= "#EXTINF:-1, " . $epiTitles[$i] . "\n";
			$self->{'playlist'} .= "#EXTART:" . $self->{'artist'} . "\n"
					if ($self->{'artist'});
			$self->{'playlist'} .= "#EXTALB:" . $self->{'album'} . "\n"
					if ($self->{'album'});
			$self->{'playlist'} .= "#EXTGENRE:" . $self->{'genre'} . "\n"
					if ($self->{'genre'});
			$self->{'playlist'} .= $epiStreams[$i] . "\n";
		}
	} else {
		$self->{'playlist_cnt'} = 1;
		$self->{'playlist'} .= "#EXTINF:-1, " . $self->{'title'} . "\n";
		$self->{'playlist'} .= "#EXTART:" . $self->{'artist'} . "\n"
				if ($self->{'artist'});
		$self->{'playlist'} .= "#EXTALB:" . $self->{'album'} . "\n"
				if ($self->{'album'});
		$self->{'playlist'} .= "#EXTGENRE:" . $self->{'genre'} . "\n"
				if ($self->{'genre'});
		$self->{'playlist'} .= ${$self->{'streams'}}[0] . "\n";
	}

	$self->_log($url);

	bless $self, $class;   #BLESS IT!

	return $self;
}

1
