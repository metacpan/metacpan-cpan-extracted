=head1 NAME

StreamFinder::Podchaser - Fetch actual raw streamable URLs on podchaser.com

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

	use StreamFinder::Podchaser;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $podcast = new StreamFinder::Podchaser($ARGV[0]);

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

StreamFinder::Podchaser accepts a valid podcast ID or URL on 
Podchaser.com and returns the actual stream URL(s), title, and cover art icon.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the podcast in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of play.  The author uses his own custom all-purpose media player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
Podchaser.com streams.

One or more stream URLs can be returned for each podcast.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ]])

Accepts a podchaser.com podcast-ID, episode-ID or URL and creates and returns a 
a new podcast object, or I<undef> if the URL is not a valid podcast, or no 
streams are found.  The URL can be the full URL, ie. 
https://www.podchaser.com/podcasts/B<podcast-id>/episodes/B<episode-id>, 
https://www.podchaser.com/podcasts/B<podcast-id>, or just 
B<podcast-id/episode-id> or B<podcast-id>.  I do not (yet) know how to fetch 
a podchaser.com episode with just the I<episode-ID>, though it IS legal to just 
supply the numeric part of episode-IDs 
(as long as you also have the podcast-ID).

Some other URL formats also seem to work well, such as:  
https://www.podchaser.com/creators/B<creator-id> and 
https://www.podchaser.com/creators/B<creator-id>/appearances (both formats are 
podcast pages (multiple episodes).

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
stream found.  [site]:  The site name (Podchaser).  [url]:  The url searched 
for streams.  [time]: Perl timestamp when the line was logged.  [title], 
[artist], [album], [description], [year], [genre], [total], [albumartist]:  
The corresponding field data returned (or "I<-na->", if no value).

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

Returns the podcast's Episode-ID (default).  For podcaster pages, the 
Episode-ID is that of the most recent episode.

=item $podcast->B<getTitle>(['desc'])

Returns the podcast's title, or (long description).

=item $podcast->B<getIconURL>(['artist'])

Returns the URL for the podcast's "cover art" icon image, if any.
If B<'artist'> is specified, the channel/podcast artist's icon url 
is returned, if any.

=item $podcast->B<getIconData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.
If B<'artist'> is specified, the channel/podcast artist's icon data 
is returned, if any.

=item $podcast->B<getImageURL>()

Returns the URL for the podcast's "cover art" (usually larger) 
banner image.  Podchaser podcasts do not have a banner image, so the 
Icon URL (if any) will be returned.

=item $podcast->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual podcast's banner image (binary data).

=item $podcast->B<getType>()

Returns the podcast's type ("Podchaser").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/Podchaser/config

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

podchaser

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-iheartradio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Podchaser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Podchaser

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Podchaser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Podchaser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Podchaser>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Podchaser/>

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

package StreamFinder::Podchaser;

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

	my $self = $class->SUPER::new('Podchaser', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});
	$self->{'id'} = '';
	$self->{'_podcast_id'} = '';
	(my $url2fetch = $url) =~ s#\/$##;
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

TRYIT:
	if ($url2fetch =~ m#^https?\:\/\/#) {
		if ($url2fetch =~ m#\/episodes?\/(.+)$#) {
			$self->{'id'} = $1;
			$isEpisode = 1;
		} elsif ($url2fetch =~ m#\/([^\/]+)$#) {
			$self->{'id'} = $1;
			$isEpisode = 0;
		}
	} else {
		$self->{'id'} = $url2fetch;
		$isEpisode = ($url2fetch =~ m#\/#) ? 1 : 0;
		if ($isEpisode) {
			my ($podcastID, $episodeID) = split(m#\/#, $self->{'id'});
			$url2fetch = "https://www.podchaser.com/podcasts/${podcastID}/episodes/${episodeID}";
			$self->{'id'} = $episodeID;
		} else {
			$url2fetch = "https://www.podchaser.com/podcasts/$$self{'id'}";
		}
	}
	return undef  unless ($self->{'id'});  #INVALID ID/URL!

	$html = '';
	print STDERR "-0(Podchaser): ($tried) FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	$response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html);  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!

	$html =~ s/\\u00([0-9A-Fa-f]{2})/chr(hex($1))/egs;
	$html =~ s#\\##gs;

	$self->{'genre'} = 'Podcast';  #DEFAULT.
	print STDERR "---ID=".$self->{'id'}."= tried=$tried=\n"  if ($DEBUG);
	if ($isEpisode) {   #EPISODE PAGE (NOW GET THE DETAILED EPISODE METADATA & WE'RE DONE):
		print STDERR "-----WE'RE AN EPISODE PAGE: ID=".$self->{'id'}."!\n"  if ($DEBUG);
		$self->{'title'} = $1  if ($html =~ m#\"\,\"name\"\:\"([^\"]+)#s);
		$self->{'title'} ||= $1  if ($html =~ m#\<h1\s+class\=\"[^\"]*\"\s+title\=\"[^\>]+\>([^\<]+)#s);
		$self->{'iconurl'} = $1  if ($html =~ m# (?:name|itemProp|property)\=\"image\"\s+content\=\"([^\"]+)#s);
		$self->{'iconurl'} ||= $1  if ($html =~ m# property\=\"(?:ogg|twitter)\:image(?:\:src)?\"\s+content\=\"([^\"]+)#s);
		$self->{'iconurl'} ||= $1  if ($html =~ m#\"image\"\:\"([^\"]+)#s);
		$self->{'imageurl'} = $self->{'iconurl'};  #Podchaser.com DOES NOT CURRENTLY PROVIDE BANNER IMAGES.
		$self->{'genre'} = $1  if ($html =~ m#\"genre\"\:\"([^\"]+)#s);
		($self->{'albumartist'} = $url2fetch) =~ s#\/$$self{'id'}##  unless ($self->{'albumartist'});
		if ($html =~ m#\"PodcastSeries\"\,\"\@id\"\:\"([^\"]+)\"\,\"name\"\:\"([^\"]+)#s) {
			$self->{'albumartist'} = $1;
			$self->{'artist'} = $2;
		} elsif ($html =~ m#\<span\s+class\=\"[^\"]*\"\>([^\<]+)\<\/span\>\<\/a\>\<\/h4\>#s) {
			$self->{'artist'} = $1;
		}
		#SOME PODCASTS HAVE A SEPARATE PODCAST-ARTIST NAME, IF SO, MOVE THE PODCAST NAME TO THE ALBUM FIELD:
		#(FOR REFERENCE, NORMALLY THE "ARTIST" IS THE PODCAST'S ARTIST'S NAME, AND ALBUM IS THE 
		#PODCAST'S NAME (AN ARTIST CAN HAVE MULTIPLE PODCASTS & A PODCAST CAN HAVE MULT. EPISODES)!)
		if ($html =~ m#\"itunes_owner_name\"\:\"([^\"]+)#s) {
			$self->{'album'} = $self->{'artist'}  if ($self->{'artist'});
			$self->{'artist'} = $1;
		}
		$self->{'articonurl'} ||= $1  if ($html =~ m#\,\"image_url\":\"([^\"]+)#s);
		$self->{'articonurl'} ||= $self->{'iconurl'};
		if ($html =~ m#\,\"air_date\"\:\"([^\"]+)#s) {
			$self->{'created'} = $1;
			$self->{'year'} = ($self->{'created'} =~ /(\d\d\d\d)/) ? $1 : '';
		}
		$self->{'description'} = $1
				if ($html =~ m#\"id\"\:$$self{'id'}\,\"creator_count\"\:\d+\,\"exclusive_to\"\:(?:null|\"[^\"]*\")\,\"description\":\"([^\"]+)#s);
		unless ($self->{'description'}) {
			$self->{'description'} = $1  if ($html =~ m# (?:name|itemProp|property)\=\"description\"\s+content\=\"([^\"]+)#s);
			$self->{'description'} =~ s/\x{2026}$/\.\.\.)/;
			$self->{'description'} ||= $self->{'title'};
		}

		#NOW FETCH THE STREAM(S) (Podchaser.com PODCASTS NORMALLY ONLY HAVE ONE):
		my $stream = '';
		$stream = $1 	if ($html =~ m#\"audio_url\"\:\"([^\"]+)#s);
		$stream ||= $1  if ($html =~ m#\>Download\s+Audio\s+File\<\/span\>\<span\s+(class\=\"[^\"]*\"\s+)?title\=\"([^\"]+)#s);
		my $protocol = $self->{'secure'} ? '' : '?';
		@{$self->{'streams'}} = ($stream)  if ($stream =~ m#^https${protocol}\:#);
		#MIGHT AS WELL ANTICIPATE & TRY TO EXTRAPOLATE POSSIBLE VIDEO!:
		$stream = ($html =~ m#\"video_url\"\:\"([^\"]+)#s) ? $1 : '';
		$stream ||= $1  if ($html =~ m#\>Download\s+Video\s+File\<\/span\>\<span\s+(class\=\"[^\"]*\"\s+)?title\=\"([^\"]+)#s);
		unshift(@{$self->{'streams'}}, $stream)  if ($stream);
	} else {   #PODCAST PAGE:
		print STDERR "-----WE'RE A PODCAST PAGE: ID=".$self->{'id'}."!\n"  if ($DEBUG);

		#FETCH PODCAST-WIDE METADATA HERE!:
		$self->{'albumartist'} = $url2fetch;
		$self->{'articonurl'} = $1  if ($html =~ m#\"\s+name\=\"image\"\s+content\=\"([^\"]+)#s);
		$self->{'articonurl'} ||= $1  if ($html =~ m#\s+property\=\"(?:og|twiter)\:image\"\s+content\=\"([^\"]+)#s);
		$self->{'artist'} = $1  if ($html =~ m#\s+property\=\"title\"\s+content\=\"([^\"]+)#s);
		if ($html =~ m#\"itunes_owner_name\"\:\"([^\"]+)#s) {
			$self->{'album'} = $self->{'artist'}  if ($self->{'artist'});
			$self->{'artist'} = $1;
		}

		#WE NEED TO EXTRACT 1ST EPISODE ID, BUT WHILST AT IT, GO AHEAD AND FETCH PLAYLIST DATA HERE TOO!:
		my %epiHash = ();
		my %titleHash = ();

		#Podchaser.com PODCAST PAGES HAVE THE LATEST AND/OR FEATURED EPISODE AT THE TOP, BUT OFTEN
		#(BUT NOT ALWAYS) REPEATED AGAIN IN THE EPISODE LIST:
		#THE "LATEST EPISODE" MAY NOT ALWAYS BE THE LATEST EITHER, GO FIGURE! :/
		foreach my $special (qw(latest featured)) {
			if ($html =~ s#\"${special}_episode\"\:\{([^\}]+)\}##s) {
				my $latest = $1;
				my @streams = ();
				foreach my $av (qw(video audio)) {
					while ($latest =~ s#\"${av}_url\"\:\"([^\"]+)##s) {
						my $streamURL = uri_unescape($1);
						next  if ($self->{'secure'} && $streamURL !~ /^https/o);

						push @streams, $streamURL;
					}
				}
				next  unless ($#streams >= 0);  #SKIP EPISODE IF NO STREAMS.

				#EPISODES HERE HAVE INCOMPLETE DATA, SO SCRAPE ENOUGH FOR PLAYLIST ENTRIES,
				#SAVE IN THE HASH, AND HOPE THEY SHOW UP AGAIN IN THE MAIN EPISODE-LIST,
				#THAT WAY, THEY'LL STILL APPEAR IN THE PLAYLIST, AND IF THE MAIN LIST IS
				#EMPTY, WE CAN USE THIS AND FETCH THE REST OF THE DATA VIA THEN FETCHING
				#THE EPISODE PAGE:
				my $created = $1  if ($latest =~ m#\"air_date\"\:\"([^\"]+)#s);
				my $ep1id = $1  if ($latest =~ m#\"id\"\:\"?(\d+)#s);
				next  unless ($ep1id);  #SKIP EPISODE IF NO EPISODE-ID (SHOULD NOT HAPPEN).

				my $title = $1  if ($latest =~ m#\"title\"\:\"([^\"]+)#s);
				my $epikey = "$created|$title";
				print STDERR "---FOUND ($special) EPISODE($created): $title ($streams[0])\n"  if ($DEBUG);
				$epiHash{$epikey} = "id=$ep1id\x02_complete=0";
				$epiHash{$epikey} .= "\x02streamstr=";
				foreach my $s (@streams) {
					$epiHash{$epikey} .= $s . '|';
				}
				$epiHash{$epikey} =~ s#\|$##o;
			}
		}

		#NOTE:  Podchaser.com HAS AN ABBREVIATED LIST OF MOST RECENT EPISODES SORTED IN REVERSE ORDER
		#(LATEST|FEATURED, THEN OLDEST TO NEWEST):
		$html =~ s#^.+?\"episodes\"\:\{##s;
		while ($html =~ s#^(.+?)\"user_data\"\:\{##so) {
			my $epihtml = $1;
			#SCRAPE THE STREAM(S) FOR EACH EPISODE (WE DON'T KNOW WHICH ONE IS LATEST YET):
			my @streams = ();
			foreach my $av (qw(video audio)) {
				while ($epihtml =~ s#\"${av}_url\"\:\"([^\"]+)##s) {
					my $streamURL = uri_unescape($1);
					next  if ($self->{'secure'} && $streamURL !~ /^https/o);

					push @streams, $streamURL;
				}
			}
			next  unless ($#streams >= 0);  #SKIP EPISODE IF NO STREAMS.

			my $epid = $1  if ($epihtml =~ m#\"(\d+)\"\:\{#o);
			next  unless ($epid);  #SKIP EPISODE IF NO EPISODE-ID (SHOULD NOT HAPPEN).

			#SCRAPE THE DETAILED METADATA FOR EACH EPISODE (WE DON'T KNOW WHICH ONE IS LATEST YET):
			if ($epihtml =~ s#\,\"podcast_id\"\:\"?(\d+)\"?\,\"title\"\:\"([^\"]+)##o) {
				my $temp;
				$temp->{'_podcast_id'} = $1;
				$temp->{'title'} = $2;
				foreach my $field (qw(album genre created year iconurl articonurl description)) {
					$temp->{$field} = '';   #INIT 'EM TO AVOID PERL NANNY WARNINGS.
				}
				if ($epihtml =~ m#\"air_date\"\:\"([^\"]+)#so) {
					$temp->{'created'} = $1;
					$temp->{'year'} = ($temp->{'created'} =~ /(\d\d\d\d)/o) ? $1 : '';
				}
				$temp->{'articonurl'} = $self->{'articonurl'};
				$temp->{'articonurl'} ||= $1  if ($epihtml =~ m#\:\{\"image_url\"\:\"([^\"]+)#o);
				$temp->{'iconurl'} = $1  if ($epihtml =~ m#\,\"image_url\"\:\"([^\"]+)#o);
				$temp->{'album'} = $1  if ($epihtml =~ m#\,\"title\"\:\"([^\"]+)#o);
				$temp->{'description'} = $1  if ($epihtml =~ m#\,\"description\"\:\"([^\"]+)#o);
				$temp->{'genre'} = $1  if ($epihtml =~ m#\,\"text\"\:\"([^\"]+)#o);
				$temp->{'_complete'} = 1;
				@{$temp->{'streams'}} = @streams;

				#STORE SCRAPED METADATA IN EPISODE HASH FOR LATER SORTING:
				my $epikey = "$$temp{'created'}|$$temp{'title'}";
				$epiHash{$epikey} = "id=$epid";
				foreach my $field (qw(_complete _podcast_id album genre created year iconurl articonurl description)) {
					$epiHash{$epikey} .= "\x02${field}=$$temp{$field}";
				}
				$epiHash{$epikey} .= "\x02streamstr=";
				foreach my $s (@{$temp->{'streams'}}) {
					$epiHash{$epikey} .= $s . '|';
				}
				$epiHash{$epikey} =~ s#\|$##o;
			}
		}

		#NOW SET UP THE PLAYLIST AND SORT EPISODES BY AIRING DATA/TIME,TITLE (AVOIDING DUPLICATE TITLES):
		my $first = 1;
		my ($name, $value);
		foreach my $epikey (sort { $b cmp $a } keys %epiHash) {
			my @data = split(/\x02/o, $epiHash{$epikey});
			if ($first) {  #LOOK FOR 1ST (LATEST) EPISODE W/COMPLETE DATA TO BE THE EPISODE RETURNED:
				(undef, $self->{'title'}) = split(/\|/o, $epikey);
				foreach my $f (@data) {
					($name, $value) = split(/\=/o, $f);
					$self->{$name} = $value;
				}
				$first = 0  if ($self->{'_complete'});  #STOP LOOKING IF EPISODE HAS COMPLETE DATA.
				@{$self->{'streams'}} = split(/\|/o, $self->{'streamstr'});
				$self->{'Url'} = ${$self->{'streams'}}[0];
				unless ($titleHash{$self->{'title'}}) { #ADD TO PLAYLIST UNLESS DUPLICATE TITLE:
					push @epiTitles, $self->{'title'};
					push @epiStreams, ${$self->{'streams'}}[0];
					$titleHash{$self->{'title'}} = 1;
				}
				delete $self->{'streamstr'};
			} else {  #WE ALREADY HAVE OUR COMPLETE EPISODE, SO JUST ADD REST TO PLAYLIST:
				my (undef, $epiTitle) = split(/\|/o, $epikey);
				next  if ($titleHash{$epiTitle});

				foreach my $f (@data) {
					($name, $value) = split(/\=/o, $f);
					if ($name eq 'streamstr') {
						my ($epiStream) = split(/\|/o, $value);
						push @epiTitles, $epiTitle;
						push @epiStreams, $epiStream;
						$titleHash{$epiTitle} = 1;
						last  if ($self->{'id'});
					} elsif ($name eq 'id') {
						$self->{'id'} ||= $value;
					}
				}
			}
		}
		if ($DEBUG) {
			print STDERR "--ep1id=".$self->{'id'}."= title=".$self->{'title'}."= First=".$self->{'Url'}."=\n";
			for (my $i=0;$i<=$#epiStreams;$i++) {
				print STDERR "-----EPISODE: $epiTitles[$i] ($epiStreams[$i])\n";
			}
		}
		if ($self->{'id'} && $tried < 1 && !$self->{'_complete'}) {   #EMPTY EP. LIST, BUT HAVE LATEST|FEATURED (INCOMPLETE DATA, MUST FETCH EP. PAGE)!:
			++$tried;
			$url2fetch .= '/episodes/' . $self->{'id'};
			print STDERR "i:No episode list, but have featured episode($$self{'id'}), BUT INCOMPLETE DATA, SO FETCH URL=$url2fetch=\n"  if ($DEBUG);
			goto TRYIT;
		}
	}

	$self->{'imageurl'} ||= $self->{'iconurl'};
	$self->{'artimageurl'} ||= $self->{'articonurl'};
	$self->{'cnt'} = scalar(@{$self->{'streams'}});
	$self->{'total'} = $self->{'cnt'};
	$self->{'Url'} = ($self->{'total'} > 0) ? $self->{'streams'}->[0] : '';

	if ($DEBUG) {
		foreach my $i (sort keys %{$self}) {
			print STDERR "--KEY=$i= VAL=".$self->{$i}."=\n";
		}
		print STDERR "--FIRST STREAM=".${$self->{'streams'}}[0]."=\n";
		print STDERR "-(all)count=".$self->{'total'}."= ID=".$self->{'id'}."= iconurl="
				.$self->{'iconurl'}."= TITLE=".$self->{'title'}."= DESC=".$self->{'description'}
				."= YEAR=".$self->{'year'}."=\n";
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
