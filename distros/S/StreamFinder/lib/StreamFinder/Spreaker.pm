=head1 NAME

StreamFinder::Spreaker - Fetch actual raw streamable URLs on widget.spreaker.com

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

	use StreamFinder::Spreaker;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $podcast = new StreamFinder::Spreaker($ARGV[0]);

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

StreamFinder::Spreaker accepts a valid podcast ID or URL on 
Spreaker.com and returns the actual stream URL(s), title, and cover art icon.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the podcast in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of play.  The author uses his own custom all-purpose media player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
Spreaker.com streams.

One or more stream URLs can be returned for each podcast.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ]])

Accepts a spreaker.com podcast ID or URL and creates and returns a 
a new podcast object, or I<undef> if the URL is not a valid podcast, or no streams 
are found.  The URL can be the full URL, ie. 
https://widget.spreaker.com/player?episode_id=B<episode-id>, 
https://www.spreaker.com/user/B<user-id>/B<podcast-id-string>, or just 
I<podcast-id>.  Due to multiple Spreaker URL combinations, it is advised to provide 
a full Spreaker URL, if possible.

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
[site]:  The site name (Spreaker).  [url]:  The url searched for streams.  
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

Returns the podcast's Spreaker ID (default).  For podcasts, the Spreaker ID 
is a single value.  For individual podcast episodes it's two values 
separated by a slash ("/").

=item $podcast->B<getTitle>(['desc'])

Returns the podcast's title, or (long description).  Podcasts 
on Spreaker can have separate descriptions, but for podcasts, 
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

Returns the podcast's type ("Spreaker").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/Spreaker/config

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

spreaker

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-iheartradio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Spreaker>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Spreaker

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Spreaker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Spreaker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Spreaker>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Spreaker/>

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

package StreamFinder::Spreaker;

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

	my $self = $class->SUPER::new('Spreaker', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});
	$self->{'id'} = '';
	$self->{'_podcast_id'} = '';
	(my $url2fetch = $url);
	my $tried = 0;
	my @epiTitles = ();
	my @epiStreams = ();
	my $episodeID = '';
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $html = '';
	my $response;

	if ($url2fetch =~ m#^(https?\:\/\/([^\/]+))#) {
		if ($url2fetch =~ m#\?\w+?\_id\=([\d]+)#) {
			$self->{'id'} = $1;
		} else {  #WE'RE A FULL URL, IE. "https://www.spreaker.com/user/<user-id>/<podcast-id-string>"
		          #OR https://www.spreaker.com/show/<podcast-id>
			$self->{'id'} = ($url2fetch =~ m#([^\/]+)$#) ? $1 : '';
#			$self->{'id'} =~ s/^[^\d]+(\d+)$/$1/;
		}
	} else {
		$self->{'id'} = $url2fetch;
	}
	if ($self->{'id'} =~ m#\/#) {
		$self->{'_podcast_id'} = $1  if ($self->{'id'} =~ m#^(\d+)\/#);
		$self->{'id'} =~ s#^.*\/##;
		$episodeID = $self->{'id'};
	} else {
#		$episodeID = ($self->{'id'} =~ /(\d\d\d\d\d\d\d\d)$/) ? $1 : $self->{'id'}
		$episodeID = ($self->{'id'} =~ /(\d\d\d\d\d\d\d\d)$/) ? $1 : '';
	}
	if ($episodeID) {
		$url2fetch = "https://api.spreaker.com/episode/$episodeID";
	} elsif ($self->{'id'} =~ /^\d+$/) {
		if (length($self->{'id'}) < 8) {
			$url2fetch = "https://www.spreaker.com/show/$self->{'id'}/episodes/feed";
		} else {
			$url2fetch = "https://api.spreaker.com/episode/$self->{'id'}";
			$episodeID = $self->{'id'};
		}
	}

	$html = '';
	print STDERR "-0(Spreaker): ($tried) FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	print STDERR "-!!!-ID=$$self{'id'}= episodeID=$episodeID= fetch=$url2fetch=\n"  if ($DEBUG);
	$response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html && $self->{'id'});  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!

	$self->{'genre'} = 'Podcast';
	$self->{'albumartist'} = $url2fetch;
	print STDERR "---ID=".$self->{'id'}."= tried=$tried=\n"  if ($DEBUG);
	if ($self->{'id'} =~ /^\d+$/) {   #NUMERIC ID:                            ** DEPRECIATED? **
		if (length($self->{'id'}) < 8) {   #PODCAST PAGE ID (FETCH XML PAGE):
			print STDERR "-----WE'RE AN XML PODCAST PAGE!\n"  if ($DEBUG);
			my $ep1id = '';
			#WE NEED TO EXTRACT 1ST EPISODE ID, BUT WHILST AT IT, GO AHEAD AND FETCH PLAYLIST DATA HERE TOO!:
			while ($html =~ s#\<item\>(.+?)\<\/item\>##si) {
				my $item = $1;
				if ($item =~ s#\<enclosure\s+url\=\"([^\"]+)##si) {
					my $stream = $1;
					next  if ($self->{'secure'} && $stream !~ /^https/o);
					if ($item =~ s#\<title\>([^\<]+)\<\/title\>##si) {
						my $title = $1;
						push @epiStreams, $stream;
						push @epiTitles, $title;
						$ep1id ||= $1  if ($stream =~ m#episode\/(\d\d\d\d\d\d\d\d)\b#o);  #EXTRACT 1ST EPISODE ID!
					}
				}
			}
			if ($ep1id) {   #WE FOUND AN EPISODE, SO RETRY (TO FETCH THE EPISODE PAGE):
				++$tried;
				$url2fetch = $ep1id;
				print STDERR "-!!!!- RETRY w/XML EPISODE ID2=$url2fetch=\n"  if ($DEBUG);
				goto TRYIT;
			}
		} else {   #EPISODE PAGE ID (NOW GET THE DETAILED EPISODE METADATA & WE'RE DONE):
			my %fh = (qw(title title  published_at year  download_url Url  large_url iconurl 
					big_url imageurl description description  site_url albumartist
					name genre  fullname artist));
			foreach my $f (keys %fh) {
				($self->{$fh{$f}} = $1) =~ s#\\##g  if ($html =~ s#\"$f\"\:\"([^\"]+)\"##);
			}
			%fh = (qw(large_url articonurl  site_url albumartist  title album));
			foreach my $f (keys %fh) {
				($self->{$fh{$f}} = $1) =~ s#\\##g  if ($html =~ s#\"$f\"\:\"([^\"]+)\"##);
			}
			$self->{'created'} = $self->{'year'};
			$self->{'year'} =~ s#^(\d\d\d\d).+$#$1#;
			if ($self->{'Url'} =~ /^http/) {
				push @{$self->{'streams'}}, $self->{'Url'};
				$self->{'cnt'}++;
			}
		}
	} elsif ($episodeID) {   #EXTRACT EPISODE DATA FROM api.spreaker.com:
		$html = HTML::Entities::decode_entities($html);
		$html = uri_unescape($html);
		$html =~ s#\\\/#\/#gs;
		$self->{'title'} = ($html =~ s#\"title\"\:\"([^\"]+)##s) ? $1 : '';
		$self->{'description'} = ($html =~ m#\"description\"\:\"([^\"]+)#s) ? $1 : '';
		$self->{'description'} = HTML::Entities::decode_entities($self->{'description'});
		$self->{'description'} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
		$self->{'description'} =~ s#\\$##gs;
		$self->{'album'} = ($html =~ m#\"title\"\:\"([^\"]+)#s) ? $1 : '';
		$self->{'iconurl'} = ($html =~ s#\"medium\_url\"\:\"([^\"]+)##s) ? $1 : '';
		$self->{'articonurl'} = ($html =~ m#\"medium\_url\"\:\"([^\"]+)#s) ? $1 : '';
		$self->{'imageurl'} = ($html =~ m#\"(?:image\_original|big)\_url\"\:\"([^\"]+)#s) ? $1 : '';
		$self->{'artimageurl'} = ($html =~ m#\"cover\_url\"\:\"([^\"]+)#s) ? $1 : '';
		$self->{'artist'} = ($html =~ m#\"fullname\"\:\"([^\"]+)#s) ? $1 : '';
		$self->{'genre'} = ($html =~ m#\"category\_id\"\:\d+\,\"name\"\:\"([^\"]+)#s) ? $1 : '';
		$self->{'created'} = ($html =~ m#\"published\_at\"\:\"([^\"]+)\"#s) ? $1 : '';
		$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/o);
		my $stream = ($html =~ m#\"download\_url\"\:\"([^\"]+)#s) ? $1 : '';
		if ($stream) {
			unless ($self->{'secure'} && $stream !~ /^https/o) {
				push @epiTitles, $self->{'title'};
				push @epiStreams, $stream;
				push @{$self->{'streams'}}, $stream;
				$self->{'cnt'}++;
			}
		}
	} else {    #EXTRACT PODCAST PAGE DATA FROM EMBEDDED, ENCODED JSON:
		$html = HTML::Entities::decode_entities($html);
		$html = uri_unescape($html);
		$html =~ s#\\\/#\/#gs;
		$self->{'album'} = ($html =~ m#\<meta\s+property\=\"(?:og|twitter)\:title\"\s+content\=\"([^\"]+)\"\s*\/\>#s) ? $1 : '';
		$self->{'articonurl'} = ($html =~ m#\<link\s+rel\=\"image\_src\"\s+href\=\"([^\"]+)#s) ? $1 : '';
		$self->{'articonurl'} ||= ($html =~ m#\<meta\s+property\=\"(?:og|twitter)\:image\"\s+content\=\"([^\"]+)\"\s*\/\>#s) ? $1 : '';
		$self->{'artist'} = ($html =~ m#\"fullname\"\:\"([^\"]+)#s) ? $1 : '';
		$self->{'genre'} = ($html =~ m#\"category\_id\"\:\d+\,\"name\"\:\"([^\"]+)#s) ? $1 : '';

		my $episodes = $1  if ($html =~ m#\"episodes\"\:\[(.+)$#s);

		#EXTRACT PLAYLIST DATA FOR ALL EPISODES & ALL DATA FOR THE FIRST/LATEST EPISODE:
		my $haveit = 0;  #TRUE WHEN WE HAVE DETAILED DATA FOR THE LATEST EPISODE.
		while ($episodes =~ s#^.+?\{\"miniplayer_data\"\:##s) {
			(my $ephtml = $episodes) =~ s/\{\"miniplayer_data\"\:.*$//so;
			next  unless ($ephtml =~ /\"episode_id\"\:(\d+)/so);
			my $epiID = $1;
			my $stream = ($ephtml =~ /\"playback\_url\"\:\"([^\"]+)/so) ? $1 : '';
			my $title = ($stream && $ephtml =~ /\"title\"\:\"([^\"]+)/so) ? $1 : '';
			if ($title) {
				unless ($self->{'secure'} && $stream !~ /^https/o) {
					push @epiTitles, $title;    #ADD ALL EPISODES TO THE PLAYLIST:
					push @epiStreams, $stream;
					print STDERR "--haveit=$haveit= epiID=$epiID= episodeID=$episodeID=\n"  if ($DEBUG);
					if (!$haveit && (!$episodeID || $episodeID eq $epiID)) { #GRAB 1ST/LATEST EPISODE DETAILS:
						$episodeID = $epiID;
						$haveit = 1;
						$self->{'title'} = $title;
						print STDERR "---GRABBED EPI=$epiID= title=$title=\n"  if ($DEBUG);
						$self->{'description'} = $1  if ($ephtml =~ m#\"description\"\:\"([^\"]+)\"#so);
						$self->{'description'} = HTML::Entities::decode_entities($self->{'description'});
						$self->{'description'} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
						$self->{'description'} =~ s#\\$##gs;
						$self->{'iconurl'} = $1  if ($ephtml =~ m#\"image\_url\"\:\"([^\"]+)\"#so);
						$self->{'imageurl'} = $1  if ($ephtml =~ m#\"image\_original\_url\"\:\"([^\"]+)\"#so);
						$self->{'iconurl'} ||= $self->{'imageurl'};
						$self->{'imageurl'} ||= $self->{'iconurl'};
						$self->{'created'} = $1 if ($ephtml =~ m#\"published\_at\"\:\"([^\"]+)\"#so);
						$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/o);
						push @{$self->{'streams'}}, $stream;
						$self->{'cnt'}++;
					}
				}
			}
		}
	}

	$self->{'total'} = $self->{'cnt'};
	$self->{'Url'} = ($self->{'total'} > 0) ? $self->{'streams'}->[0] : '';

	print STDERR "-(all)count=".$self->{'total'}."= ID=".$self->{'id'}."= iconurl="
			.$self->{'iconurl'}."= TITLE=".$self->{'title'}."= DESC=".$self->{'description'}
			."= YEAR=".$self->{'year'}."=\n"  if ($DEBUG);
	return undef  unless ($self->{'cnt'} > 0);

	#GENERATE EXTENDED-M3U PLAYLIST:

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

	if ($DEBUG) {
		foreach my $i (sort keys %{$self}) {
			print STDERR "--KEY=$i= VAL=".$self->{$i}."=\n";
		}
		print STDERR "-SUCCESS: 1st stream=".$self->{'Url'}."=\n"  if ($DEBUG);
	}

	$self->_log($url);

	bless $self, $class;   #BLESS IT!

	return $self;
}

#IF WE WERE GIVEN A PODCAST PAGE W/O A NUMERIC PODCAST-ID, WE WAIT UNTIL HERE (ASKED BY USER) TO 
#FETCH THE XML PODCAST PAGE (REQUIRES NUMERIC PODCAST-ID)
#OTHERWISE, WE ALREADY HAVE THE PLAYLIST DATA, SO WE RETURN THAT:
sub get   ## DEPRECIATED? ##
{
	my $self = shift;

	if (defined($_[0]) && $_[0] =~ /playlist/i) {
		print STDERR "---GET PLAYLIST!--- CNT=".$self->{'playlist_cnt'}."= PCID=".$self->{'_podcast_id'}."=\n"  if ($DEBUG);
		return $self->{'playlist'}  if ($self->{'playlist_cnt'} > 1);  #HAVE ALREADY FETCHED IT BEFORE!

		if ($self->{'_podcast_id'}) {  #FETCH UNFETCHED PLAYLIST DATA (NOW THAT USER HAS ASKED FOR IT):
			my @epiTitles = ();
			my @epiStreams = ();
			my $url2fetch = "https://www.spreaker.com/show/$self->{'_podcast_id'}/episodes/feed";
			print STDERR "--GET: FETCHING URL=$url2fetch=\n"  if ($DEBUG);
			my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
			$ua->timeout($self->{'timeout'});
			$ua->cookie_jar({});
			$ua->env_proxy;
			my $xml = '';
			my $response = $ua->get($url2fetch);
			if ($response->is_success) {
				$xml = $response->decoded_content;
			} else {
				print STDERR $response->status_line  if ($DEBUG);
			}

			while ($xml =~ s#\<item\>(.+?)\<\/item\>##si) {
				my $item = $1;
				if ($item =~ s#\<enclosure\s+url\=\"([^\"]+)##si) {
					my $stream = $1;
					next  if ($self->{'secure'} && $stream !~ /^https/o);
					if ($item =~ s#\<title\>([^\<]+)\<\/title\>##si) {
						my $title = $1;
						push @epiStreams, $stream;
						push @epiTitles, $title;
					}
				}
			}
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
		return $self->{'playlist'};
	}
	return wantarray ? @{$self->{'streams'}} : ${$self->{'streams'}}[0];
}

1
