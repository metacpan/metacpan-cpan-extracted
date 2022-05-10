=head1 NAME

StreamFinder::Podbean - Fetch actual raw streamable podcast URLs on podbean.com

=head1 AUTHOR

This module is Copyright (C) 2021-2022 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::Podbean;

	die "..usage:  $0 URL\n"  unless ($ARGV[0]);

	my $podcast = new StreamFinder::Podbean($ARGV[0]);

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

StreamFinder::Podbean accepts a valid podcast ID or URL on 
Podbean.com and returns the actual stream URL(s), title, and cover art icon.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the podcast in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of play.  The author uses his own custom all-purpose media player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
Podbean.com streams.

One or more stream URLs can be returned for each podcast.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ] ... ])

Accepts a www.podbean.com podcast URL and creates and returns a 
a new podcast object, or I<undef> if the URL is not a valid podcast, or no 
streams are found.  The URL MUST be either a I<CHANNEL-id> or the full URL, 
ie. https://B<channel-id>.podbean.com/e/B<episode-id>, or 
https://B<channel-id>.podbean.com, 
https://www.podbean.com/podcast-detail/B<channel-id>/..., 
https://www.podbean.com/ew/B<episode-id>, 
https://www.podbean.com/media/share/B<episode-id>..., 
https://www.podbean.com/site/EpisodeDownload/B<episode-id>, B<channel-id> or 
B<channel-id/episode-id>.  NOTE:  If only a I<channel-id> is specified, it 
must be the channel-id of a Podbean-hosted podcast channel site 
(https://I<channel-id>.podbean.com), and for I<all> non-episode URLs, the 
first (latest) episode for the channel is returned.  

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
stream found.  [site]:  The site name (Podbean).  [url]:  The url searched 
for streams.  [time]: Perl timestamp when the line was logged.  [title], 
[artist], [album], [description], [year], [genre], [total], [albumartist]:  
The corresponding field data returned (or "I<-na->", if no value).

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
If "playlist" is specified, then an extended m3u playlist is returned 
instead of stream url(s). NOTE:  if an author / channel page url is given for 
a Podbeam-hosted podcast channel (https://B<channel-id>.podbean.com), 
get() returns the first (latest?) podcast episode found, and get("playlist") 
returns an extended m3u playlist containing the urls, titles, etc. for all 
the podcast episodes found on that page url from latest to oldest.  This 
playlist containing all episodes feature currently does NOT work for channels 
actually hosted elsewhere (URL format:  
https://www.podbean.com/podcast-detail/B<channel-id>/...), as these pages do 
not contain the playable streams.

=item $podcast->B<getID>()

Returns the podcast's Podbean ID (default).  For podcasts, the Podbean ID 
is a single value.  For individual podcast episodes it's two values 
separated by a slash ("/").

=item $podcast->B<getTitle>(['desc'])

Returns the podcast's title, or (long description).  Podcasts 
on Podbean can have separate descriptions, but for podcasts, 
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

Returns the podcast's type ("Podbean").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/Podbean/config

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

podbean

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-iheartradio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Podbean>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Podbean

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Podbean>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Podbean>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Podbean>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Podbean/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2021-2022 Jim Turner.

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

package StreamFinder::Podbean;

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

	my $self = $class->SUPER::new('Podbean', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});

	$self->{'id'} = '';
	my $isEpisode = 0;
	my $isPodbeanHosted = 1;  #True if "https://<channel-id>.podbean.com..."
	(my $url2fetch = $url) =~ s#\?.*$##;
	if ($url2fetch =~ m#^https\:\/\/www\.podbean\.com\/(?:ew|media\/share|site/EpisodeDownload)\/([^\/]+)#) { #episode pg:
		$self->{'id'} = $1;
		$isEpisode = 1;
		$isPodbeanHosted = 0;
	} elsif ($url2fetch =~ m#^https\:\/\/www\.podbean\.com\/podcast\-detail\/([^\/]+)#) { #podcast pg:
		$self->{'id'} = $1;
		$isPodbeanHosted = 0;
	} elsif ($url2fetch =~ m#^https?\:\/\/([a-z0-9]+)\.podbean\.com\/e\w?\/([^\/]+)\/?$#) {  #episode pg:
		$self->{'id'} = $1 . '/' . $2;
		$isEpisode = 1;
	} elsif ($url2fetch =~ m#^https?\:\/\/([a-z0-9]+)\.podbean\.com\/?$#) { #podcast pg:
		$self->{'id'} = $1;
	#NOTE:  NON-URL "ID" VALUES CAN ONLY BE PODBEAN-HOSTED CHANNEL-ID OR CHANNEL-ID/EPISODE-ID!:
	} elsif ($url2fetch =~ m#^https?\:# && $url2fetch =~ m#\/([a-z0-9]+)\/#) {
		$self->{'id'} = $1;
	} elsif ($url2fetch =~ m#^([a-z0-9]+\/[^\/]+)$#) {
		$self->{'id'} = $1;
	} elsif ($url2fetch =~ m#^([a-z0-9]+)$#) {
		$self->{'id'} = $1;
	}
	unless ($self->{'id'}) {  #MUST PROVIDE URL OR ID?!
		print STDERR "w:No ID found - url ($url) is NOT a valid Podbean podcast url!\n"  if ($DEBUG);
		return undef;
	}

	$self->{'genre'} = 'Podcast';
	my $html = '';
	my @epiTitles = ();
	my @epiStreams = ();
	if ($isPodbeanHosted) {
		my ($channelID, $episodeID) =($self->{'id'} =~ m#\/#) ? split(m#\/#, $self->{'id'}) : ($self->{'id'}, '');
		$url2fetch = "https://feed.podbean.com/${channelID}/feed.xml";
		print STDERR "-0(Podbean hosted page): FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
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
		print STDERR "-1a: html=$html=\n"  if ($DEBUG > 1);
		return undef  unless ($html);  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!

		$self->{'albumartist'} = "https://${channelID}.podbean.com";
		$self->{'album'} = $1  if ($html =~ m#\<title\>(.+?)\<\/title\>#s);
		$self->{'genre'} = $1  if ($html =~ m#\<category\>(.+?)\<\/category\>#s);
		$self->{'iconurl'} = $self->{'imageurl'} = $1
				if ($html =~ m#image\s+href\=\"([^\"]+)#);

		#FETCH PODCAST PAGE:

		my $epiFound = 0;
		while ($html =~ s#\<item\>(.+?)\<\/item\>##so) {
			my $epidata = $1;
			if ($epidata =~ m#\<enclosure\s+([^\>]+)#so) {
				my $streamdata = $1;
				if ($streamdata =~ m#\burl\=\"([^\"]+)#o) {
					my $stream = $1;
					next  if ($self->{'secure'} && $stream !~ /^https/o);
					if ($epidata =~ m#\<title\>(.+?)\<\/title\>#so) {
						my $title = $1;
						unless ($episodeID) {
							push @epiTitles, $title;
							push @epiStreams, $stream;
						}
						if (!$epiFound && $epidata =~ s#\<link\>\s*(.+?)\<\/link\>##so) {
							(my $link = $1) =~ s#\s+$##o;
							if ($link =~ m#\/e\/([\S]+)#o) {
								(my $epID = $1) =~ s#\/\s*$##o;;
								if ($episodeID) {
									next  unless ($epID eq $episodeID);

									push (@{$self->{'streams'}}, $stream);
									++$self->{'cnt'};
								} else {
									$self->{'id'} .= '/' . $epID;
									push (@{$self->{'streams'}}, $stream);
									++$self->{'cnt'};
								}

								#FETCH REST OF EPISODE DATA:

								++$epiFound;
								$self->{'title'} ||= $title;
								if ($epidata =~ s#\<pubDate\>(.+?)\<\/pubDate\>##s) {
									$self->{'created'} = $1;
									$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
								}
								$self->{'description'} = $1
										if ($epidata =~ m#\<description\>(.+?)\<\/description\>#s);
								$self->{'description'} ||= $1
										if ($epidata =~ m#\<content\:encoded\>(.+?)\<\/content\:encoded\>#s);
								if ($self->{'description'}) {
									$self->{'description'} =~ s#\<\!\[CDATA\[##o;
									$self->{'description'} =~ s#\]\]\>##so;
								}
								$self->{'artist'} = $1  if ($epidata =~ m#\bauthor\>([^\<]+)#);
								last  if ($episodeID);
							}
						}
					}
				}
			}
		}
	} else {
		unless ($isEpisode) {
			print STDERR "-0(Podbean unhosted page): FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
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
			print STDERR "-1a: html=$html=\n"  if ($DEBUG > 1);
			return undef  unless ($html);  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!

			$url2fetch = '';
			$html =~ s#.+\<tbody\s+class\=\"items\"\>##s;
			if ($html =~ s#\<tr\>(.+?)\<\/tr\>##s) {  #items:
				my $epidata = $1;
				if ($epidata =~ m#<a\s+target\=\"\_blank\"\s+href\=\"([^\"]+)#so) {
					$url2fetch = $1;
				}
			}

			return undef  unless ($url2fetch);  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!
		}

		#SHOULD NOW HAVE AN EPISODE URL:
		print STDERR "-1(Podbean unhosted episode): FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
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
		print STDERR "-1a: html=$html=\n"  if ($DEBUG > 1);
		return undef  unless ($html);  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!

		if ($html =~ m#\<script\s+type\=\"application\/ld\+json"\>(.+?)\<\/script\>#s) {
			my $epidata = $1;
			if ($epidata =~ m#\"associatedMedia\"\:\{([^\}]+)#) {
				my $mediadata = $1;
				while ($mediadata =~ s#\"contentUrl\"\:\"([^\"]+)\"##) {
					my $stream = $1;
					next  if ($self->{'secure'} && $stream !~ /^https/o);

					$stream =~ s#\\\/#\/#g;
					push (@{$self->{'streams'}}, $stream);
					++$self->{'cnt'};
				}
			}
			push (@{$self->{'streams'}}, $1)  if ($html =~ m#\<meta\s+property\=\"og\:video\"\s+content\=\"([^\"]+)#s);
			push (@{$self->{'streams'}}, $1)  if ($html =~ m#\<meta\s+property\=\"og\:audio\"\s+content\=\"([^\"]+)#s);
			$self->{'albumartist'} = $1  if ($epidata =~ s#\"PodcastEpisode\"\,\"url\"\:\"([^\"]+)\"\,##s);
			$self->{'albumartist'} =~ s#\\\/#\/#g;
			$self->{'title'} = $1  if ($epidata =~ s#\"name\"\:\"(.+?)\"\,##s);
			$self->{'artist'} = $1  if ($epidata =~ s#\"name\"\:\"(.+?)\"\,##s);
			$self->{'created'} = $1  if ($epidata =~ s#\"datePublished\"\:\"(.+?)\"\,##is);
			$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
			$self->{'description'} = $1  if ($epidata =~ s#\"description\"\:\"(.+?)\"\,##is);
			$self->{'description'} ||= $1  if ($html =~ m#\<meta\s+property\=\"og\:description\"\s+content\=\"([^\"]+)#);
			$self->{'imageurl'} = $1  if ($html =~ m#\<meta\s+property\=\"og\:image\"\s+content\=\"([^\"]+)#);
			$self->{'iconurl'} = $self->{'imageurl'};
			$self->{'genre'} = $1  if ($html =~ m#\<p\s+class\=\"category\"\>(.+?)\<\/p\>#s);
		}
	}



	$self->{'total'} = $self->{'cnt'};
	print STDERR "-(all)count=".$self->{'cnt'}."= iconurl=".$self->{'iconurl'}."= TITLE="
			.$self->{'title'}."= DESC=".$self->{'description'}."= YEAR=".$self->{'year'}
			."= artist=".$self->{'artist'}."= albart=".$self->{'albumartist'}."=\n"  if ($DEBUG);
	return undef  unless ($self->{'total'} > 0);

	foreach my $field (qw(title description artist album genre)) {
		$self->{$field} = HTML::Entities::decode_entities($self->{$field});
		$self->{$field} = uri_unescape($self->{$field});
		$self->{$field} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
	}

	$self->{'Url'} = $self->{'streams'}->[0];
	print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"  if ($DEBUG);
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
