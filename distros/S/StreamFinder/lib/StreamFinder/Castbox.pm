=head1 NAME

StreamFinder::Castbox - Fetch actual raw streamable podcast URLs on castbox.com

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

	use StreamFinder::Castbox;

	die "..usage:  $0 URL\n"  unless ($ARGV[0]);

	my $podcast = new StreamFinder::Castbox($ARGV[0]);

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

StreamFinder::Castbox accepts a valid podcast ID or URL on 
Castbox.com and returns the actual stream URL(s), title, and cover art icon.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the podcast in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of play.  The author uses his own custom all-purpose media player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
Castbox.com streams.

One or more stream URLs can be returned for each podcast.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ] ... ])

Accepts a www.castbox.com podcast URL and creates and returns a 
a new podcast object, or I<undef> if the URL is not a valid podcast, or no 
streams are found.  The URL MUST be the full URL, ie. 
https://castbox.fm/episode/I<title>-idB<channel-id>-idB<episode-id>, or 
https://castbox.fm/channel/idB<channel-id> 
as I know of no way to look up a podcast on Castbox with just an episode ID.
If no I<episode-id> is specified, the first (latest) episode for the channel 
is returned.

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
[site]:  The site name (Castbox).  [url]:  The url searched for streams.  
[time]: Perl timestamp when the line was logged.  [title], [artist], [album], 
[description], [year], [genre], [total], [albumartist]:  The corresponding field data 
returned (or "I<-na->", if no value).

=item $podcast->B<get>(['playlist'])

Returns an array of strings representing all stream URLs found.
If I<"playlist"> is specified, then an extended m3u playlist is returned 
instead of stream url(s).  NOTE:  If an author / channel page url is given, 
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

Returns the podcast's Castbox ID (default).  For podcasts, the Castbox ID 
is a single value.  For individual podcast episodes it's two values 
separated by a slash ("/").

=item $podcast->B<getTitle>(['desc'])

Returns the podcast's title, or (long description).  Podcasts 
on Castbox can have separate descriptions, but for podcasts, 
it is always the podcast's title.

Note:  Castbox podcasts sometimes contain a transcript text in a "lyrics" 
(.lrc) link, which we download and append to the long description field.  
This is useful in media players like Fauxdacious which display the 
description field for podcasts and videos in the place where song lyrics 
are displayed for songs.  If this is undesirable, one can simply add 
something like "$podcast->{'description'} =~ s#\n\nTranscript:.+$##s;" 
in their code.

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

Returns the podcast's type ("Castbox").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/Castbox/config

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

castbox

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-iheartradio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Castbox>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Castbox

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Castbox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Castbox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Castbox>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Castbox/>

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

package StreamFinder::Castbox;

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

	my $self = $class->SUPER::new('Castbox', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});

	$self->{'id'} = '';
	my $urlroot = '';
	(my $url2fetch = $url);
	if ($url2fetch =~ m#^(https?\:\/\/castbox\.\w+)#) {
		$urlroot = $1;
		$self->{'id'} = ($url =~ m#\-id(\d+)\-id(\d+)#) ? "${1}/$2" : '';
		$self->{'id'} ||= $1  if ($url =~ m#id(\d+)#);   #NO EPISODE SPECIFIED
	} else {
		$self->{'id'} = $url2fetch;
	}
	unless ($self->{'id'}) {  #MUST PROVIDE URL, NO KNOWN WAY TO LOOK UP WITH JUST ID#?!
		print STDERR "w:No ID found - url ($url) is NOT a valid Castbox podcast url!\n"  if ($DEBUG);
		return undef;
	}

	my ($channelID, $episodeID);
	if ($self->{'id'} =~ m#^(\d+)\/(\d+)$#) {  #SPECIFIC EPISODE GIVEN:
		$channelID = $1;
		$episodeID = $2;
		$url2fetch = s#\/episode\/.+$#\/channel\/id$channelID\/#;
	} else {  #PODCAST PAGE ID GIVEN:
		$channelID = $self->{'id'};
	}
	#NOTE:  FOR Castbox PODCASTS & EPISODES, WE SCRAPE ALL NEEDED DATA FROM THE PODCAST CHANNEL PAGE,
	#AS EPISODE PAGES ARE NO LONGER SCRAPABLE:
	$url2fetch = 'https://castbox.fm/channel/id' . $channelID
			unless ($url2fetch =~ m#\/channel\/#);

	my $html = '';
	print STDERR "-0(Castbox): FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $response;
	$self->{'genre'} = 'Podcast';
	$self->{'albumartist'} = $url2fetch;
	my @epiTitles = ();
	my @epiStreams = ();

	$response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html && $self->{'id'});  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!

	#FETCH PODCAST CHANNEL DATA:
	$self->{'album'} = $1  if ($html =~ m#\<h1\s+title\=\"([^\"]+)#);
	$self->{'albumartist'} = $url2fetch;
	$self->{'articonurl'} = ($html =~ s#\<meta\s+property\=\"(?:og|twitter)\:image\"\s+content\=\"([^\"]+)\"\s*\/\>##s) ? $1 : '';
	$self->{'articonurl'} ||= $1  if ($html =~ s#\"\,\"image\"\:\"([^\"]+)\"\}\}\]\}##s);
	$self->{'artimageurl'} ||= $self->{'articonurl'};
	#FETCH ALL EPISODE DATA:
	$html =~ s#^.+?\_\_INITIAL\_STATE\_\_##s;   #EPISODE DATA IS AFTER HERE:
	$html = uri_unescape($html);
	$self->{'genre'} = $1  if ($html =~ m#\"keywords\"\:\[?\"([^\"]+)#);
	unless (defined $episodeID) {
		$episodeID = $1  if ($html =~ /\{\"latest\_eid\"\:(\d+)/);
	}
	my $epiID;
	my $haveit = 0;  #TRUE WHEN WE HAVE DETAILED DATA FOR THE LATEST EPISODE.
	while ($html =~ s#^.+?\{\"website\"\:##s) {
		(my $ephtml = $html) =~ s/\{\"website\"\:.*$//so;
		next  unless ($ephtml =~ /\"eid\"\:(\d+)/so);
		$epiID = $1;
		print STDERR "---NEXT EPISODEID=$epiID= EPISODE=$episodeID=\n"  if ($DEBUG);
		my $stream = '';
		my $title = '';
		if ($ephtml =~ m#\,\"url\"\:\"([^\"]+)\"#so) {
			$stream = $1;
		} elsif ($ephtml =~ m#\,\"urls\"\:\[\"([^\"]+)\"#so) {
			$stream = $1;
		}
		if ($stream && $ephtml =~ s#\"title\"\:\"([^\"]+)\"##s) {
			my $one = $1;
			unless ($self->{'secure'} && $stream !~ /^https/o) {
				push @epiTitles, $one;    #ADD ALL EPISODES TO THE PLAYLIST:
				push @epiStreams, $stream;
				if (!$haveit && (!defined($episodeID) || $episodeID == $epiID)) {
					 #GRAB 1ST/LATEST EPISODE DETAILS:
					$episodeID = $epiID;
					$haveit = 1;
					$self->{'title'} = $one;
					$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
					$self->{'title'} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/eg;
					print STDERR "-----GRABBED THIS EPISODE=$epiID!= TITLE=$$self{'title'}= stream=$stream\n"  if ($DEBUG);
					$self->{'artist'} = $1  if ($ephtml =~ m#\"author\"\:\"([^\"]+)\"#so);
					$self->{'description'} = $1  if ($ephtml =~ m#\"description\"\:\"([^\"]+)\"#so);
					$self->{'description'} = HTML::Entities::decode_entities($self->{'description'});
					$self->{'description'} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/eg;
					$self->{'description'} =~ s#\\$##gs;
					$self->{'iconurl'} = $1  if ($ephtml =~ m#\"cover\_url\"\:\"([^\"]+)\"#so);
					$self->{'iconurl'} ||= $1  if ($ephtml =~ m#\"small\_cover\_url\"\:\"([^\"]+)\"#so);
					$self->{'imageurl'} = $1  if ($ephtml =~ m#\"big\_cover\_url\"\:\"([^\"]+)\"#so);
					$self->{'iconurl'} ||= $self->{'imageurl'};
					$self->{'imageurl'} ||= $self->{'iconurl'};
					$self->{'created'} = $1 if ($ephtml =~ m#\"release\_date\"\:\"([^\"]+)\"#so);
					$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/o);
					push @{$self->{'streams'}}, $stream;
					$self->{'cnt'}++;
					$self->{'lyricURL'} = ($ephtml =~ m#\,\{\"url\"\:\"([^\"]+?\.lrc)\"#) ? $1 : '';
				}
			}
		}
	}
	print STDERR "-(all)count=".$self->{'cnt'}."= iconurl=".$self->{'iconurl'}."= TITLE=".$self->{'title'}."= DESC=".$self->{'description'}."= YEAR=".$self->{'year'}."= artist=".$self->{'artist'}."= albart=".$self->{'albumartist'}."=\n"  if ($DEBUG);
	return undef  unless ($self->{'cnt'} > 0);

	$self->{'total'} = $self->{'cnt'};
	$self->{'Url'} = ($self->{'total'} > 0) ? $self->{'streams'}->[0] : '';
	print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"  if ($DEBUG);
	$self->{'playlist'} = "#EXTM3U\n";
	if ($#epiStreams >= 0) {  #PLAYLIST PAGE SPECIFIED, ADD ALL EPISODES TO PLAYLIST:
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
	} else {  #EPISODE PAGE SPECIFIED, ONLY THAT EPISODE ADDED TO PLAYLIST:
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
	if ($self->{'lyricURL'}) {   #HAVE LYRICS?!:
		$response = $ua->get($self->{'lyricURL'});
		if ($response->is_success) {
			my $lyrics = $response->decoded_content;
			if ($lyrics) {
				print STDERR "--WE HAVE LYRICS!, COOL!\n"  if ($DEBUG);
				$lyrics = HTML::Entities::decode_entities($lyrics);
				$lyrics =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/eg;
				$self->{'description'} .= "\n\nTranscript:  $lyrics";
			}
		} else {
			print STDERR $response->status_line  if ($DEBUG);
		}
	}
	$self->_log($url);
	if ($DEBUG) {
		foreach my $f (sort keys %{$self}) {
			print STDERR "--KEY=$f= VAL=$$self{$f}=\n";
		}
		print STDERR "-SUCCESS: 1st stream=".$self->{'Url'}."=\n"  if ($DEBUG);
	}

	bless $self, $class;   #BLESS IT!

	return $self;
}

1
