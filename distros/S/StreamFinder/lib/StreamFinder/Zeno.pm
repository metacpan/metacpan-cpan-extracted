=head1 NAME

StreamFinder::Zeno - Fetch actual raw streamable URLs from radio-station websites on zeno.fm

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

	use StreamFinder::Zeno;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $station = new StreamFinder::Zeno($ARGV[0]);

	die "Invalid URL or no streams found!\n"  unless ($station);

	my $firstStream = $station->get();

	print "First Stream URL=$firstStream\n";

	my $url = $station->getURL();

	print "Stream URL=$url\n";

	my $stationTitle = $station->getTitle();
	
	print "Title=$stationTitle\n";
	
	my $stationDescription = $station->getTitle('desc');
	
	print "Title=$stationDescription\n";
	
	my $stationID = $station->getID();

	print "Station ID=$stationID\n";
	
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

StreamFinder::Zeno accepts a valid radio station or podcast ID or URL on 
Zeno.fm and returns the actual stream URL(s), title, and cover art icon for 
that station.  The purpose is that one needs one of these URLs in order to 
have the option to stream the station in one's own choice of media player 
software rather than using their web browser and accepting any / all flash, 
ads, javascript, cookies, trackers, web-bugs, and other crapware that can come 
with that method of play.  The author uses his own custom all-purpose media 
player called "fauxdacious" (his custom hacked version of the open-source 
"audacious" audio player).  "fauxdacious" can incorporate this module to 
decode and play Zeno.fm streams.

Generally, only one stream will be returned for each station.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-notrim> [ => 0|1 ]] [, I<-secure> [ => 0|1 ]] 
[, I<-debug> [ => 0|1|2 ]])

Accepts a Zeno.fm station ID or URL and creates and returns a new station 
object, or I<undef> if the URL is not a valid Zeno.fm station or no 
streams are found.  The URL can be the full URL, 
ie. https://www.zeno.fm/radio/B<station-id>, or just I<station-id>, 
https://www.zeno.fm/podcast/B<podcast-id>/episodes/B<episode-id> or just 
I<podcast-id>/I<episode-id>.  If a podcast URL is specified without the 
episode-id part, then the first episode will be returned.

The optional I<-notrim> argument can be either 0 or 1 (I<false> or I<true>).  
If 0 (I<false>) then stream URLs are trimmed of excess "ad" parameters 
(everything after the first "?" character, ie. "?ads.cust_params=premium" is 
removed, including the "?".  Otherwise, the stream URLs are returned as-is.  

DEFAULT I<-notrim> (if not given) is 0 (I<false>) and URLs are trimmed.  If 
I<-notrim> is specified without argument, the default is 1 (I<true>).  Try 
using I<-notrim> if stream will not play without the extra arguments.

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
stream found.  [site]:  The site name (Zeno).  [url]:  The url searched 
for streams.  
[time]: Perl timestamp when the line was logged.  [title], [artist], [album], 
[description], [year], [genre], [total], [albumartist]:  The corresponding 
field data returned (or "I<-na->", if no value).

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

Returns the number of streams found for the station or podcasts 
(almost always 1 for Zeno.fm).

=item $station->B<getID>()

Returns the station's or podcast's Zeno.fm ID (alphanumeric).

=item $station->B<getTitle>(['desc'])

Returns the station's or podcast's title, or (long description).  

=item $station->B<getIconURL>()

Returns the URL for the station's or podcast's "cover art" icon image, if any.

=item $station->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.

=item $station->B<getImageURL>()

Returns the URL for the station's "cover art" (usually larger) 
banner image.  Zeno.fm Podcasts do not have a separate banner image.

=item $station->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual station's banner image (binary data).  
Zeno.fm Podcasts do not have a separate banner image.

=item $station->B<getType>()

Returns the station's / podcast's type ("Zeno").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/Zeno/config

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

Among options valid for Zeno streams is the I<-notrim> described in the 
B<new()> function.  

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

Zeno

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-Zeno at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Zeno>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Zeno

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Zeno>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Zeno>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Zeno>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Zeno/>

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

package StreamFinder::Zeno;

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

	my $self = $class->SUPER::new('Zeno', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});
	$self->{'notrim'} = 0;
	while (@_) {
		if ($_[0] =~ /^\-?notrim$/o) {
			shift;
			$self->{'notrim'} = (defined $_[0]) ? shift : 1;
		} else {
			shift;
		}
	}

	my $isStation;
	my $isPodcastPage;
	my @epiStreams = ();
	my @epiTitles = ();
	my $tryit = 0;

TRYIT:
	(my $url2fetch = $url) =~ s#\/$##;
	if ($url =~ /^https?\:/) {
		$self->{'id'} = ($url =~ m#\/([^\/]+)\/episodes?\/([^\/]+)#)
				? "$1/$2" : '';
		$isStation = ($url =~ m#\/radio\/#) ? 1 : 0;
		$self->{'id'} ||= $1  if ($url2fetch =~ m#\/([^\/]+)\/?$#);
	} elsif ($url =~ m#\/#) {
		my ($pcid, $epid) = split(m#\/#);
		$self->{'id'} = "$pcid/$epid";
		$url2fetch = "https://www.zeno.fm/podcast/$pcid/episodes/$epid";
		$isStation = 0;
	} else {
		$self->{'id'} = $url;
		$url2fetch = 'https://www.zeno.fm/radio/' . $url;
		$isStation = 1;
	}
	$isPodcastPage = ($isStation || $self->{'id'} =~ m#\/#) ? 0 : 1;
	$self->{'cnt'} = 0;
	my $html = '';
	print STDERR "-0(Zeno): URL=$url2fetch=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html);  #STEP 1 FAILED, INVALID STATION URL, PUNT!

	my $json = '';
	$json = $1  if ($html =~ s#\btype\=\"application\/json\"\>\{(.+)##s);
	if ($json) {
		print STDERR "..JSON data found, fetching data we can here first.\n"  if ($DEBUG);
		my $have1stepisode = 0;
		if ($isPodcastPage) {   #WE'RE A PODCAST PAGE (NOT SPECIFIC EPISODE), GATHER PLAYLIST DATA:
			print STDERR "..Podcast PAGE, extract episodes for playlist, then return 1st episode:\n"  if ($DEBUG);
			my $podcastdata = ($json =~ s#^(.+?)\"episodes\"\:##s) ? $1 : '';
			while ($json =~ s#^.+?\"title\"\:\"([^\"]+)\"##so) {
				my $epititle = $1;
				my $epistream = ($json =~ m#\"file\_url\"\:\"([^\"]+)\"#so) ? $1 : '';
				next  unless ($epititle && $epistream);
				next  if ($self->{'secure'} && $epistream !~ /^https/o);

				if ($json =~ m#\"url\"\:\"([^\"]+)\"#so) {
					$have1stepisode ||= $1;
					$epistream =~ s/\.(mp3|m3u8|pls)\?.*$/\.$1/  unless ($self->{'notrim'});   #STRIP OFF EXTRA GARBAGE PARMS, COMMENT OUT IF STARTS FAILING!
					push @epiStreams, $epistream;
					push @epiTitles, $epititle;
				}
			}
			$json = $podcastdata  if ($podcastdata);
		}

		$json =~ s#\"CardSupportDonations\"\:.+##s;
		$self->{'articonurl'} = (!$isStation && $json =~ s#\"logo\"\:\"([^\"]+)\"##s) ? $1 : '';
		$self->{'iconurl'} = ($json =~ s#\"logo\"\:\"([^\"]+)\"##s) ? $1 : $self->{'articonurl'};
		$self->{'imageurl'} = ($json =~ m#\"background\"\:\"([^\"]+)\"#s) ? $1 : '';
		$self->{'description'} = ($json =~ s#\"description\"\:\"([^\"]+)\"##s) ? $1 : '';
		$self->{'albumartist'} = ($json =~ m#\"url\"\:\"([^\"]+)\"#s) ? $1 : '';
		if ($isStation) {   #WE'RE A RADIO-STATION:
			$self->{'genre'} = ($json =~ m#\"genre\"\:\"([^\"]+)\"#s) ? $1 : '';
			while ($json =~ s#\"streamURL\"\:\"([^\"]+)\"##si) {
				my $one = $1;
				unless ($self->{'secure'} && $one !~ /^https/o) {
					$one =~ s/\.(mp3|m3u8|pls)\?.*$/\.$1/  unless ($self->{'notrim'});   #STRIP OFF EXTRA GARBAGE PARMS, COMMENT OUT IF STARTS FAILING!
					push @{$self->{'streams'}}, $one;
					$self->{'cnt'}++;
				}
			}
		} else {   #WE'RE A PODCAST OR PODCAST EPISODE PAGE:
			$self->{'album'} = $1  if ($json =~ s#\"title\"\:\"([^\"]+)\"##);
			$self->{'artist'} = $1  if ($json =~ m#\"author\"\:\"([^\"]+)\"#);
			if ($json =~ m#\"categories\"\:\[([^\]]+)\]#) {
				($self->{'genre'} = $1) =~ s/\"//g;
				$self->{'genre'} =~ s/\,(\S)/\, $1/g;
			} elsif ($json =~ m#\"categories\"\:\"([^\"]+)\"#) {
				$self->{'genre'} = $1;
			} else {
				$self->{'genre'} = 'Podcast';
			}
			if ($isPodcastPage && $have1stepisode && !$tryit) {
				$url = $have1stepisode;
				++$tryit;
				print STDERR "--Podcast PAGE: loopback & fetch 1st episode ($url)\n"  if ($DEBUG);
				goto TRYIT;  #PODCAST PAGE: LOOP BACK TO FETCH 1ST EPISODE:
			}

			#IF HERE, WE'RE EITHER A RADIO STATION OR HAVE A SPECIFIC PODCAST EPISODE:
			#NOW GATHER DATA WE CAN FROM JSON:
			print STDERR "--We have an EPISODE page!\n"  if ($DEBUG);
			$self->{'description'} = ($json =~ m#\"description\"\:\"([^\"]+)\"#s) ? $1 : '';
			if ($json =~ m#\"published\_at\"\:\"([^\"]+)\"#) {
				$self->{'created'} = $1;
				$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
			}
			if ($json =~ m#\"file\_url\"\:\"([^\"]+)\"#si) {  #FETCH THE STREAM:
				my $one = $1;
				unless ($self->{'secure'} && $one !~ /^https/o) {
					$one =~ s/\.(mp3|m3u8|pls)\?.*$/\.$1/  unless ($self->{'notrim'});   #STRIP OFF EXTRA GARBAGE PARMS, COMMENT OUT IF STARTS FAILING!
					push @{$self->{'streams'}}, $one;
					$self->{'cnt'}++;
				}
			}
			#IF WAS ORIGINALLY A PODCAST PAGE (NOW 1ST EPISODE), BUILD THE PLAYLIST:
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
		}
	}
	#TRY TO SCOOP UP ANY DATA NOT FOUND IN JSON:
	$self->{'title'} = $1  if ($html =~ m#\<title\>(.+?)\<\/title\>#si);
	$self->{'title'} ||= $1  if ($html =~ m#\<meta\s+property="og\:title\"\s+content\=\"([^\"]+)\"#s);
	$self->{'title'} ||= $1  if ($html =~ m#\<meta\s+name\=\"twitter\:title\"\s+content\=\"([^\"]+)\"#s);
	$self->{'albumartist'} ||= $1  if ($html =~ m#\<meta\s+property\=\"og\:url\"\s+content\=\"([^\"]+)\"#s);
	$self->{'iconurl'} ||= ($html =~ m#\"og\:image\"\s+content\=\"([^\"]+)\"#s) ? $1 : '';
	$self->{'iconurl'} ||= ($html =~ m#\"twitter\:image\"\s+content\=\"([^\"]+)\"#s) ? $1 : '';
	if ($html =~ m#\<img\s+([^\<]+)#s) {
		my $firstimg = $1;
		$self->{'title'} ||= $1  if ($firstimg =~ s#\balt\=\"([^\"]+)\"##s);
		my $srcset = ($firstimg =~ s#\bsrcSet\=\"([^\"]+)\"##) ? $1 : '';
		$self->{'imageurl'} ||= HTML::Entities::decode_entities($1)
				if ($srcset && $srcset =~ m#\?url\=([^\s\;]+)#);
	}			
	$self->{'imageurl'} ||= $self->{'iconurl'};
	$self->{'iconurl'} ||= $self->{'imageurl'};
	$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
	$self->{'title'} = uri_unescape($self->{'title'});
	$self->{'title'} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
	$self->{'title'} =~ s/^\s*Listen to\s+//i;  #TIDY UP TITLE A BIT.
	$self->{'title'} =~ s/\s*\|\s*Zeno.FM//;  #TIDY UP TITLE A BIT.
	$self->{'description'} = HTML::Entities::decode_entities($self->{'description'});
	$self->{'description'} = uri_unescape($self->{'description'});
	$self->{'description'} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
	$self->{'description'} =~ s/\<(?:br|p>)[^\>]*\>/\n/gs;
	unless ($self->{'cnt'} > 0) {
		if ($html =~ m#\<meta\s+name\=\"twitter\:player\:stream\"\s+content\=\"([^\"]+)\"#s) {
			my $one = $1;
			unless ($self->{'secure'} && $one !~ /^https/o) {
				push @{$self->{'streams'}}, $one;
				$self->{'cnt'}++;
			}
		}
	}

	$self->{'total'} = $self->{'cnt'};
	$self->{'Url'} = ($self->{'total'} > 0) ? $self->{'streams'}->[0] : '';
	if ($DEBUG) {
		foreach my $x (sort keys %{$self}) {
			print STDERR "--KEY=$x= VAL=".$self->{$x}."=\n";
		}
		print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"
				if ($self->{'cnt'} > 0);
	}

	$self->_log($url);

	bless $self, $class;   #BLESS IT!

	return $self;
}

1
