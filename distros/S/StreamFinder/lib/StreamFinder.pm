=head1 NAME

StreamFinder - Fetch actual raw streamable URLs from various radio-station, video & podcast websites.

=head1 INSTALLATION

	To install this module, run the following commands:

	perl Makefile.PL

	make

	make test

	make install

=head1 AUTHOR

This module is Copyright (C) 2017-2026 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder;

	die "..usage:  $0 URL\n"  unless ($ARGV[0]);

	my $station = new StreamFinder($ARGV[0]);

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

		print "Icon URL=$icon_url=\n";

		my ($image_ext, $icon_image) = $station->getIconData();

		if ($icon_image && open IMGOUT, ">/tmp/${stationID}.$image_ext") {

			binmode IMGOUT;

			print IMGOUT $icon_image;

			close IMGOUT;

			print "...Icon image downloaded to (/tmp/${stationID}.$image_ext)\n";

		}

	}

	my $stream_count = $station->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $station->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder accepts a webpage URL for a valid radio station, video, or podcast 
/ episode URL on supported websites and returns the actual stream URL(s), 
title, and cover art icon for that station / podcast / video.  The purpose is 
that one needs one of these URLs in order to have the option to stream the 
station / podcast / video in one's own choice of media player software rather 
than using their web browser and accepting flash, ads, javascript, cookies, 
trackers, web-bugs, and other crapware associated with that method of play.  
The author created and uses his own custom all-purpose media player called 
"Fauxdacious Media Player" (his custom forked version of the open-source 
"Audacious Audio Player).  "Fauxdacious" 
(L<https://wildstar84.wordpress.com/fauxdacious/>) incorporates this module via 
a Perl helper-script to decode and play streams, along with their titles / 
station names, and station / podcast / video icons, artists / channel names, 
genres, and descriptions! 

Please NOTE:  StreamFinder is a module, NOT a standalone application.  It is 
designed to be used by other Perl applications.  To create your own very simple 
application just to fetch stream data manually, simply grab the code in the 
B<SYNOPSIS> section above, save it to an executable text file, ie. 
I<StreamFinder.pl>, and run it from the command line with a supported streaming 
site URL as the argument.  You can then edit it to tailor it to your needs.

The currently-supported websites are:  
podcasts.apple.com podcasts (L<StreamFinder::Apple>), 
bitchute.com videos (L<StreamFinder::Bitchute>), 
blogger.com videos (L<StreamFinder::Blogger>), 
ugetube.com videos (L<StreamFinder::BrandNewTube>), 
brighteon.com videos (L<StreamFinder::Brighteon>), 
castbox.fm podcasts (L<StreamFinder::Castbox>), 
theepochtimes.com/epochtv videos (L<StreamFinder::EpochTV>), 
iheart.com (aka iheartradio.com) radio stations and podcasts 
(L<StreamFinder::IHeartRadio>), 
www.internet-radio.com radio stations (L<StreamFinder::InternetRadio>), 
onlineradiobox.com radio stations (L<StreamFinder::OnlineRadiobox>), 
odysee.com videos (L<StreamFinder::Odysee>), 
podbean.com podcasts (L<StreamFinder::Podbean>), 
podcastaddict.com podcasts (L<StreamFinder::PodcastAddict>) (DEPRECIATED), 
podchaser.com podcasts (L<StreamFinder::Podchaser>), 
radio.net radio stations (L<StreamFinder::RadioNet>), 
rcast.net radio stations (L<StreamFinder::Rcast>), 
rumble.com videos (L<StreamFinder::Rumble>), 
sermonaudio.com sermons: audio and video (L<StreamFinder::SermonAudio>), 
soundcloud.com (non-paywalled) songs (L<StreamFinder::SoundCloud>) 
(DEPRECIATED), spreaker.com podcasts (L<StreamFinder::Spreaker>), 
subsplash.com podcasts (L<StreamFinder::Subsplash>) (EXPERIMENTAL), 
tunein.com (non-paywalled) radio stations and podcasts 
(L<StreamFinder::Tunein>), vimeo.com videos (L<StreamFinder::Vimeo>), 
youtube.com, et. al and other sites that youtube-dl/yt-dlp support 
(L<StreamFinder::Youtube>), 
zeno.fm radio stations and podcasts (L<StreamFinder::Zeno>), 
and L<StreamFinder::Anystream> - search any (other) webpage URL (not supported 
by any of the other submodules) for streams.  

NOTE:  StreamFinder::Google has been removed as Google Podcasts has shut down.

NOTE:  StreamFinder::LinkTV has been removed as that site no longer provides 
streams anymore but only links to the various (and diverse) streaming sites 
that provide their own streams.  Some may possibly work via 
StreamFinder::Youtube or StreamFinder::AnyStream.

NOTE:  StreamFinder::Goodpods has been removed, as that site has redone itself 
in javascript as to no longer be scrapable for streams.

NOTE:  StreamFinder::Podcastaddict is now considered depreciated and may be 
removed in a later StreamFinder release as it now requires a specific valid 
episode page to fetch streams from, as Podcastaddict.com has javascripted up 
their podcast pages now to the point that it is no longer possible to obtain 
a playlist from them via our scripts.  However, it still seems to be able to 
return the first episode data when given a podcast page for now.

NOTE:  Users should also consider StreamFinder::SoundCloud to now be 
depreciated, as they've added cookie and tracker requirements making it 
impossible to search for songs on their site without enabling, but song URLs 
(when known) seem to still work for now, but without channel/artist icons.  
(Privacy-minded individuals should now be cautious while using this site).

NOTE:  For many sites, ie. Youtube, Vimeo, Apple, Spreaker, Castbox, Google, 
etc. the "station" object actually refers to a specific video or podcast 
episode, but functions the same way.  

Each site is supported by a separate subpackage (StreamFinder::I<Package>), 
which is determined and selected based on the URL argument passed to it when 
the StreamFinder object is created.  The methods are overloaded by the selected 
subpackage's methods.  An example would be B<StreamFinder::Youtube>.  

Please see the POD. documentation for each subpackage for important additional 
information on options and features specific to each site / subpackage!

One or more playable streams can be returned for each station / video / 
podcast, along with at least a "title" (station name / video or podcast episode 
title) and an icon image URL ("iconurl" - if found).  Additional information 
that MAY be fetched is a (larger?) banner image ("imageurl"), a (longer?) 
"description", an "artist" / author, a "genre", and / or a "year" (podcasts, 
videos, etc.), an AlbumArtist / channel URL, and possibly a second 
icon image for the channel (podcasts and videos).  Some sites also provide 
radio stations' FCC call letters ("fccid").  For icon and image URLs, 
functions exist (getIconData() and getImageData()) to fetch the actual binary 
data and mime type for downloading to local storage for use by your 
application or preferred media player.  NOTE:  StreamFinder::Anystream is not 
able to return much beyond the stream URLs it finds, but please see it's POD 
documentation for details on what it is able to return.

If you have another streaming site that is not supported, first, make sure 
you have B<youtube-dl> installed and see if B<StreamFinder::Youtube> can 
successfully fetch any streams for it.  If not, then please file a feature 
request via email or the CPAN bug system, or (for faster service), provide a 
Perl patch module / program source that can extract some or all of the 
necessary information for streams on that site and I'll consider it!  The 
easiest way to do this is to take one of the existing submodules, copy it to 
"StreamFinder::I<YOURSITE>.pm", modify it (and the POD docs) to your 
specific site's needs, test it on several of their pages (see the "SYNOPSIS" 
code above), and send it to me (That's what I do when I want to add a 
new site)!

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, I<options> ])

Accepts a URL and creates and returns a new station, video, or 
podcast object, or I<undef> if the URL is not a valid station or 
no streams are found.

NOTE:  Depending on the type of site being queried, the "station 
object" can be either a streaming station, a video, or a podcast, 
but works the same way (method calls, arguments, etc.).

NOTE:  A full URL must be specified here, but if using any of the 
subpackage modules directly instead, then either a full URL OR just 
the station / video / podcast's site ID may be used!  Reason being 
that this function parses the full URL to determine which subpackage 
(site) module to use.

I<options> can vary depending on the type of site that is 
being queried.  One option common to all sites is I<-debug>, which 
turns on debugging output.  A numeric option can follow specifying 
the level (0, 1, or 2).  0 is none, 1 is basic, 2 is detailed.  
Default:  B<1> (if I<-debug> is specified).  Warning: 2 will dump a ton 
of output (mostly the HTML of the web page being parsed!

One specific option (I<-omit>, added as of v1.45) permits omitting 
specific submodules which are currently installed from being considered.  
For example, to NOT handle Youtube videos nor use the fallback 
"Anystream" module, specify:  I<-omit> => I<"Youtube,Anystream">, which 
will cause StreamFinder::Anystream and StreamFinder::Youtube to not be used 
for the stream search.  Default is for all installed submodules to be 
considered.  NOTE:  Omitting a module from being considered when seeking 
to match the correct module by site URL does NOT prevent that 
module from being invoked by a selected module for an embedded link, OR 
in the case of StreamFinder::Youtube being omitted, will still be invoked, 
if required or needed by a non-omitted module initially selected!

Another global option (applicable to all submodules) is the I<-secure> 
option who's argument can be either 0 or 1 (I<false> or I<true>).  If 1,  
then only secure ("https://") streams will be returned.  NOTE, it's 
possible that some sites may only contain insecure ("http://") streams, 
which won't return any streams if this option is specified.  Therefore, 
it may be necessary, if setting this option globally, to set it to 
zero in the config. files for those specific modules, if you determine 
that to be the case (I have not tested all sites for that).  Default: 
I<-secure> is 0 (false) - return all streams (http and https).

Any other options (including I<-debug>) will be passed to the submodule 
(if any) that handles the URL you pass in, but note, submodules accept 
different options and ignore ones they do not recognize.  Valid values 
for some options can also vary across different submodules.  A better 
way to change default options for one or more submodules is to set up 
submodule configuration files for the ones you wish to change.

Additional options:

I<-hls_bandwidth> => "I<number>"

Limit HLS (m3u8) streams that contain a list of other HLS streams of varying 
BANDWIDTH values (in BITS per second) by selecting the highest bitrate stream 
at or below the specified limit when I<$stream>->I<getURL()> is called.

DEFAULT I<-none-> (no limiting by bitrate).

I<-log> => "I<logfile>"

Specify path to a log file.  If a valid and writable file is specified, A line 
will be appended to this file every time one or more streams is successfully 
fetched for a url.

DEFAULT I<-none-> (no logging).

I<-logfmt> specifies a format string for lines written to the log file.

DEFAULT "I<[time] [url] - [site]: [title] ([total])>".  

The valid field I<[variables]> are:  [stream]: The url of the first/best stream 
found.  [site]:  The site (submodule) name matching the webpage url.  
[url]:  The url searched for streams.  [time]: Perl timestamp when the line was 
logged.  [title], [artist], [album], [description], [year], [genre], [total], 
[albumartist]:  The corresponding field data returned (or "I<-na->", 
if no value).

=item $station->B<get>(['playlist'])

Returns an array of strings representing all stream URLs found.
If I<"playlist"> is specified, then an extended m3u playlist is returned 
instead of stream url(s).  NOTE:  For podcast sites, if an author / channel 
page url is given, rather than an individual podcast episode's url, get() 
returns the first (latest?) podcast episode found, and get("playlist") returns 
an extended m3u playlist containing the urls, titles, etc. for all the podcast 
episodes found on that page url from latest to oldest.

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

Returns the number of streams found for the station.

=item $station->B<getStationID>(['fccid'])

Returns the station's site ID (default), or station's FCC 
call-letters ("fccid") for applicable sites and stations.

=item $station->B<getTitle>(['desc'])

Returns the station's title, (or long description, if "desc" specified).  

NOTE:  Some sights do not support a separate long description field, 
so if none found, the standard title field will always be returned.

=item $station->B<getIconURL>(['artist'])

Returns the URL for the station's "cover art" icon image, if any.

Some video and podcast sites will also provide a separate artist/channel 
icon.  If B<'artist'> is specified, this icon url is returned instead, 
if any.

=item $station->B<getIconData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.  
This makes it easy to download the image to local storage for use by 
your preferred media player.

Some video and podcast sites will also provide a separate artist/channel 
icon.  If B<'artist'> is specified, this icon's data is returned instead, 
if any.

=item $station->B<getImageURL>(['artist'])

Returns the URL for the station's "cover art" banner image, if any.

NOTE:  If no "banner image" (usually a larger image) is found, 
the "icon image" URL will be returned.

Some video and podcast sites will also provide a separate artist/channel 
image (usually larger).  If B<'artist'> is specified, this icon url is 
returned instead, if any.

=item $station->B<getImageData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual station's banner image 
(binary data).  This makes it easy to download the image to 
local storage for use by your preferred media player.

NOTE:  If no "banner image" (usually a larger image) is found, 
the "icon image" data, if any, will be returned.

Some video and podcast sites will also provide a separate artist/channel 
image (usually larger).  If B<'artist'> is specified, this icon's data is 
returned instead, if any.

=item $station->B<getType>()

Returns the station / podcast / video's type (I<submodule-name>).  
(one of:  "Anystream", "Apple", "BitChute", "Blogger", "Youtube", etc. - 
depending on the sight that matched the URL).

Some video and podcast sites will also provide a separate artist/channel 
image (usually larger).  If B<'artist'> is specified, this icon url is 
returned instead, if any.

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/config

Optional text file for specifying various configuration options.  
Each option is specified on a separate line in the formats below:  
NOTE:  Do not follow the lines with a semicolon, comma, or any other 
separator.  Non-numeric I<values> should be surrounded with quotes, either 
single or double.  Blank lines and lines beginning with a "#" sign as 
their first non-blank character are ignored as comments.

'option' => 'value' [, ...]

'option' => ['value1', 'value2', ...] [, ...]

'option' => {'key1' => 'value1', 'key2' => 'value2', ...} [, ...]

and the options are loaded into a hash used by all sites 
(submodules) that support them.  Valid options include 
I<-debug> => [0|1|2] and most of the L<LWP::UserAgent> options.  

=item ~/.config/StreamFinder/I<submodule>/config

Optional text file for specifying various configuration options 
for a specific site (submodule, ie. "Youtube" for 
StreamFinder::Youtube).  Each option is specified on a separate 
line in the formats below:

'option' => 'value' [, ...]

'option' => ['value1', 'value2', ...] [, ...]

'option' => {'key1' => 'value1', 'key2' => 'value2', ...} [, ...]

and the options are loaded into a hash used only by the specific 
(submodule) specified.  Valid options include 
I<-debug> => [0|1|2] and most of the L<LWP::UserAgent> options.

NOTE:  Options specified here override any specified in I<~/.config/StreamFinder/config>.

=back

NOTE:  Options specified in the options parameter list of the I<new()> 
function will override those corresponding options specified in these files.

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

youtube-dl, or other compatable program such as yt-dlp, etc. 
(for Youtube, Bitchute, Blogger, Brighteon, Odysee, Vimeo)
NOTE:  Required for Youtube, Odysee, and SoundCloud to work.

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder>.  
I will be notified, and then you'llautomatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder

You can also look for information at:

=head1 SEE ALSO

Fauxdacious media player - (L<https://wildstar84.wordpress.com/fauxdacious>)

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2026 Jim Turner.

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

package StreamFinder;

require 5.001;

use strict;
use warnings;
use vars qw(@ISA @EXPORT $VERSION);

our $VERSION = '2.47';
our $DEBUG = 0;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
my @supported_mods = (qw(Anystream Apple Bitchute Blogger BrandNewTube Brighteon Castbox EpochTV 
		Google IHeartRadio InternetRadio Odysee OnlineRadiobox Podbean PodcastAddict Podchaser 
		RadioNet Rcast Rumble SermonAudio SoundCloud	Spreaker	Tunein Vimeo Youtube Zeno Subsplash));

my %useit;

foreach my $module (@supported_mods)
{
	$useit{$module} = 1;
}

sub new
{
	my $class = shift;
	my $url = shift;

	my $self = {};
	return undef  unless ($url);

	my $arg;
	my @args = ();
	while (@_) {
		$arg = shift(@_);
		if ($arg =~ /^\-?omit$/o) {   #ALLOW USER TO OMIT SPECIFIC INSTALLED SUBMODULE(S):
			my @omitModules = split(/\,\s*/, shift(@_));
			foreach my $omit (@omitModules)
			{
				$useit{$omit} = 0;
			}
		} else {
			push @args, $arg;
		}
	}

	my $haveit = 0;
	push @args, ('-debug', $DEBUG)  if ($DEBUG);
	if ($url =~ m#\b(?:podcasts?|music)\.apple\.com\/# && $useit{'Apple'}) {
		eval { require 'StreamFinder/Apple.pm'; $haveit = 1; };
		return new StreamFinder::Apple($url, @args)  if ($haveit);
	} elsif ($url =~ m#\brumble\.com\/# && $useit{'Rumble'}) {
		eval { require 'StreamFinder/Rumble.pm'; $haveit = 1; };
		return new StreamFinder::Rumble($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bpodcastaddict\.# && $useit{'PodcastAddict'}) {
		eval { require 'StreamFinder/PodcastAddict.pm'; $haveit = 1; };
		return new StreamFinder::PodcastAddict($url, @args)  if ($haveit);
	} elsif ($url =~ m#\b(?:brandnew|uge)tube\.# && $useit{'BrandNewTube'}) { #HANDLES brandnewtube & ugetube!
		eval { require 'StreamFinder/BrandNewTube.pm'; $haveit = 1; };
		return new StreamFinder::BrandNewTube($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bbitchute\.# && $useit{'Bitchute'}) {
		eval { require 'StreamFinder/Bitchute.pm'; $haveit = 1; };
		return new StreamFinder::Bitchute($url, @args)  if ($haveit);
	} elsif ($url =~ m#\biheart(?:radio)?\.#i && $useit{'IHeartRadio'}) {
		eval { require 'StreamFinder/IHeartRadio.pm'; $haveit = 1; };
		return new StreamFinder::IHeartRadio($url, @args)  if ($haveit);
	} elsif ($url =~ m#\btunein\.# && $useit{'Tunein'}) {  #NOTE:ALSO USES youtube-dl!
		eval { require 'StreamFinder/Tunein.pm'; $haveit = 1; };
		return new StreamFinder::Tunein($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bbrighteon\.com\/# && $useit{'Brighteon'}) {  #NOTE:ALSO USES youtube-dl!
		eval { require 'StreamFinder/Brighteon.pm'; $haveit = 1; };
		return new StreamFinder::Brighteon($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bspreaker\.# && $useit{'Spreaker'}) {
		eval { require 'StreamFinder/Spreaker.pm'; $haveit = 1; };
		return new StreamFinder::Spreaker($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bcastbox\.\w+\/# && $useit{'Castbox'}) {
		eval { require 'StreamFinder/Castbox.pm'; $haveit = 1; };
		return new StreamFinder::Castbox($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bradio\.net\/# && $useit{'RadioNet'}) {
		eval { require 'StreamFinder/RadioNet.pm'; $haveit = 1; };
		return new StreamFinder::RadioNet($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bvimeo\.# && $useit{'Vimeo'}) {  #NOTE:ALSO USES youtube-dl!
		eval { require 'StreamFinder/Vimeo.pm'; $haveit = 1; };
		return new StreamFinder::Vimeo($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bblogger\.# && $useit{'Blogger'}) {
		eval { require 'StreamFinder/Blogger.pm'; $haveit = 1; };
		return new StreamFinder::Blogger($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bsermonaudio\.com\/# && $useit{'SermonAudio'}) {
		eval { require 'StreamFinder/SermonAudio.pm'; $haveit = 1; };
		return new StreamFinder::SermonAudio($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bodysee\.com\/# && $useit{'Odysee'}) {
		eval { require 'StreamFinder/Odysee.pm'; $haveit = 1; };
		return new StreamFinder::Odysee($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bpodbean\.com\/# && $useit{'Podbean'}) {
		eval { require 'StreamFinder/Podbean.pm'; $haveit = 1; };
		return new StreamFinder::Podbean($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bonlineradiobox\.# && $useit{'OnlineRadiobox'}) {
		eval { require 'StreamFinder/OnlineRadiobox.pm'; $haveit = 1; };
		return new StreamFinder::OnlineRadiobox($url, @args)  if ($haveit);
	} elsif ($url =~ m#\binternet\-radio\.# && $useit{'InternetRadio'}) {
		eval { require 'StreamFinder/InternetRadio.pm'; $haveit = 1; };
		return new StreamFinder::InternetRadio($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bsoundcloud\.# && $useit{'SoundCloud'}) {
		eval { require 'StreamFinder/SoundCloud.pm'; $haveit = 1; };
		return new StreamFinder::SoundCloud($url, @args)  if ($haveit);
	} elsif ($url =~ m#\brcast\.# && $useit{'Rcast'}) {
		eval { require 'StreamFinder/Rcast.pm'; $haveit = 1; };
		return new StreamFinder::Rcast($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bpodchaser\.# && $useit{'Podchaser'}) {
		eval { require 'StreamFinder/Podchaser.pm'; $haveit = 1; };
		return new StreamFinder::Podchaser($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bzeno\.# && $useit{'Zeno'}) {
		eval { require 'StreamFinder/Zeno.pm'; $haveit = 1; };
		return new StreamFinder::Zeno($url, @args)  if ($haveit);
	} elsif ($url =~ m#\bsubsplash\.# && $useit{'Subsplash'}) {
		eval { require 'StreamFinder/Subsplash.pm'; $haveit = 1; };
		return new StreamFinder::Subsplash($url, @args)  if ($haveit);
	} elsif ($url =~ m#\btheepochtimes\.# && $useit{'EpochTV'}) {
		eval { require 'StreamFinder/EpochTV.pm'; $haveit = 1; };
		return new StreamFinder::EpochTV($url, @args)  if ($haveit);
	} elsif ($url !~ /\.m3u8$/i && $useit{'Youtube'}) {
		#DEFAULT TO youtube-dl (EXCEPT HLS URLS) SINCE SO MANY URLS ARE HANDLED THERE NOW.
		#(WE NOW PASS HLS URLS ON TO Anystream WHICH CHECKS THEM AGAINST ANY BANDWIDTH
		#LIMITS AND, IF A MASTER PLAYLIST, LIMITS TO STREAMS WITHIN THE LIMITS):
		eval { require 'StreamFinder/Youtube.pm'; $haveit = 1; };
		if ($haveit) {
			my $yt = new StreamFinder::Youtube($url, @args);
			return $yt  if (defined($yt) && $yt && $yt->count() > 0);
		}
	}
	if ($useit{'Anystream'}) {  #SITE NOT SUPPORTED, TRY TO FIND ANY STREAM URLS WE CAN:
		$haveit = 0;
		eval { require 'StreamFinder/Anystream.pm'; $haveit = 1; };
		return new StreamFinder::Anystream($url, @args)  if ($haveit);
	}
	return undef;
}

1