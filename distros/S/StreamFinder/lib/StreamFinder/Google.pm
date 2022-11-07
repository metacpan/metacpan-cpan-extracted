=head1 NAME

StreamFinder::Google - Fetch actual raw streamable podcast URLs on google.com

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

	use StreamFinder::Google;

	die "..usage:  $0 URL\n"  unless ($ARGV[0]);

	my $podcast = new StreamFinder::Google($ARGV[0]);

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

		(my $image_filename = $podcastID) =~ s#^[^\/]*\/##;

		if ($icon_image && open IMGOUT, ">/tmp/${image_filename}.$image_ext") {

			binmode IMGOUT;

			print IMGOUT $icon_image;

			close IMGOUT;

			print "...Icon image downloaded to (/tmp/${image_filename}.$image_ext)\n";

		}

	}

	my $stream_count = $podcast->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $podcast->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::Google accepts a valid podcast ID or URL on Google.com and 
returns the actual podcast URL, title, description, artist, year, and cover 
art icon.  The purpose is that one needs one of these URLs in order to have 
the option to stream the podcast in one's own choice of media player software 
rather than using their web browser and accepting any / all flash, ads, 
javascript, cookies, trackers, web-bugs, and other crapware that can come 
with that method of play.  The author uses his own custom all-purpose media 
player called "fauxdacious" (his custom hacked version of the open-source 
"audacious" audio player).  "fauxdacious" can incorporate this module to 
decode and play Google.com podcasts.

For Google podcasts, currently a single stream will be returned for the 
podcast episode.  If no episode-ID is specified, then a stream will be 
returned for the first (latest) episode on the podcast page.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ] ... ])

Accepts a podcasts.google.com podcast URL and creates and returns a 
a new podcast object, or I<undef> if the URL is not a valid podcast, or no 
streams are found.  The URL can be the full URL, 
ie. https://podcasts.google.com/feed/B<podcast-id>/episode/B<episode-id>, 
https://podcasts.google.com/feed/B<podcast-id>, B<podcast-id>/B<episode-id>, 
or just B<podcast-id>.  (If no I<episode-id> is specified, the first (latest) 
episode on the podcaster's page will be fetched).

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
[site]:  The site name (Google).  [url]:  The url searched for streams.  
[time]: Perl timestamp when the line was logged.  [title], [artist], [album], 
[description], [year], [genre], [total], [albumartist]:  The corresponding field data 
returned (or "I<-na->", if no value).

=item $podcast->B<get>(['playlist'])

Returns an array of strings representing all stream URLs found.  For Google 
podcasts, only a single stream URL is returned.
If I<"playlist"> is specified, then an extended m3u playlist is returned 
instead of stream url.  NOTE:  If an author / channel page url is given, 
rather than an individual podcast episode's url, get() returns the first 
(latest?) podcast episode found, and get("playlist") returns an extended 
m3u playlist containing the urls, titles, etc. for all the podcast 
episodes found on that page url.

=item $podcast->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the stream found (if a valid stream is found).  There currently are 
no valid I<options>.

=item $podcast->B<count>(['playlist'])

Returns the number of streams found for the podcast.
If I<"playlist"> is specified, the number of episodes returned in the 
playlist is returned (the playlist can have more than one item if a 
podcast page URL is specified).

=item $podcast->B<getID>()

Returns the podcast's Google ID consisting of two values (the podcast ID, and 
the episode ID combined into a single string separated by a slash ("/").  
NOTE:  Google IDs are generally long strings of random letters and numbers.

=item $podcast->B<getTitle>(['desc'])

Returns the podcast's title, or (long description).  Podcasts 
on Google usually have separate long-descriptions.

=item $podcast->B<getIconURL>()

Returns the URL for the podcast's "cover art" icon image, if any.

NOTE:  For Google podcasts, the podcast episode's icon will always be the 
podcast's icon (the "channel icon"), as Google does not provide for icons 
for individual episodes.

=item $podcast->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.

=item $podcast->B<getImageURL>()

Returns the URL for the podcast's "cover art" (usually larger) 
banner image.  For Google podcasts, there is no larger banner image, so 
the Icon URL will be returned.

=item $podcast->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual podcast's banner image (binary data).
For Google podcasts, there is no larger banner image, so 
the Icon image data will be returned.

=item $podcast->B<getType>()

Returns the podcast's type ("Google").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/Google/config

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

google

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-iheartradio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Google>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Google

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Google>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Google>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Google>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Google/>

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

package StreamFinder::Google;

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

	my $self = $class->SUPER::new('Google', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});

	$self->{'id'} = '';
	my $urlroot = '';
	(my $url2fetch = $url) =~ s#\/www\.google\.(\w+)\/podcasts\?feed\=#\/podcasts\.google\.$1\/feed\/#;
	$url2fetch =~ s/\?.*$//;
	if ($url2fetch =~ m#^https?\:\/\/podcasts\.google\.[a-z]+\/feed\/([a-zA-Z0-9]+)\/episode\/([a-zA-Z0-9]+)#) {
		$self->{'id'} = $1 . '/'. $2;
	} elsif ($url2fetch =~ m#^https?\:\/\/podcasts\.google\.[a-z]+\/feed\/([a-zA-Z0-9]+)#) {
		$self->{'id'} = $1;
	} elsif ($url2fetch !~ m#^https?\:\/\/#) {
		$self->{'id'} = $url2fetch;
		my ($podcastid, $episodeid) = split(m#\/#, $self->{'id'});
		$url2fetch = $episodeid ? "https://podcasts.google.com/feed/${podcastid}/episode/${episodeid}"
				: "https://podcasts.google.com/feed/${podcastid}";
	}
	my $html = '';
	print STDERR "-0(Google): FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);

	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $response;
	$self->{'genre'} = 'Podcast';
	$self->{'albumartist'} = $url2fetch;
	my @epiTitles = ();
	my @epiStreams = ();
	if ($self->{'id'} !~ m#\/#) {  #NO SPECIFIC EPISODE GIVEN, TRY TO FIND 1ST (LATEST) ONE:

		#FETCH PODCAST PAGE:

		$response = $ua->get($url2fetch);
		if ($response->is_success) {
			$html = $response->decoded_content;
		} else {
			print STDERR $response->status_line  if ($DEBUG);
		}
		print STDERR "-1a: html=$html=\n"  if ($DEBUG > 1);

		#ARTIST (PODCAST AUTHOR):
		$self->{'artist'} = $1  if ($html =~ m#hash\:\s*\'\d\'\,\s*data\:[^\"]*\"([^\"]+)#);
		print STDERR "-1-ARTIST=".$self->{'artist'}."=\n"  if ($DEBUG);

		#STREAM(S):
		my $episodeid = ($html =~ s#\"\,\"$self->{'id'}\"\,\"([^\"]+)\"\]#1ST-EPISODE#s) ? $1 : '';
		print STDERR "-1a: no episode specified, found first ep=$episodeid=\n"  if ($DEBUG);
		$html =~ s#^.*?1ST-EPISODE##s;
		while ($html =~ s#(?:true|false)\,(?:\"\w+\"|null)\,(?:true|false)\,\"(.+?)\,\"$self->{'artist'}\"##so) {
			(my $goodstuff = $1) =~ s/\\\"/\x02/gso;
			if ($goodstuff =~ s#([^\"]+\")##so) {
				(my $title = $1) =~ s#\x02#\"#go;  #c
				$title =~ s#\"$##o;  #  unless ($title =~ m#\".+$#o);  #c
				if ($goodstuff =~ m#\"(https?\:[^\"]+)#so) {
					my $streamURL = $1;
					$self->{'artist'} = $1  if ($#epiStreams < 0 && $goodstuff =~ m#\"\,\"([^\"]+)#);
					$streamURL =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/eg;
					$streamURL =~ s/\?.*$//o;
					if ($streamURL && (!$self->{'secure'} || $streamURL =~ /^https/o)) {
						push @epiStreams, $streamURL;
						push @epiTitles, $title;
					}
				}
			}
		}

		#FOUND 1ST EPISODE, BUT NOT THE METADATA, SO FETCH THE EPISODE PAGE:
		print STDERR "-1a: We found 1st episode, but incomplete metadata, so fetch episode's page...\n"  if ($DEBUG);
		$url2fetch = 'https://podcasts.google.com/feed/' . $self->{'id'} . "/episode/$episodeid";
		$self->{'id'} .= "/$episodeid";
		$html = '';
	}

	$response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html && $self->{'id'});  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!

	#STREAM:
	if ($html =~ s#\bjsdata\=\"(?:[a-zA-Z0-9]*\;)?(https?\:\/\/[^\"\?\;]+)##s) {
		my $one = $1;
		unless ($self->{'secure'} && $one !~ /^https/o) {
			push @{$self->{'streams'}}, $one;
			$self->{'cnt'}++;
		}
	}
	$self->{'total'} = $self->{'cnt'};
	return undef  unless ($self->{'cnt'} > 0);

	#ALBUM:
	$self->{'album'} = $1  if ($html =~ s#\<meta\s+(?:itemprop\=\"author\"|property\=\"article\:author\"|name\=\"twitter\:creator\")\s+content\=\"([^\"]+)##s);

	#ARTIST (PODCAST AUTHOR):
	$self->{'artist'} ||= $1  if ($html =~ m#\"([^\"]+)\"\,\[\"http#);

	#TITLE:
	if ($html =~ s#\<meta\s+(?:itemprop\=\"name\"|name\=\"title\")\s+content\=\"([^\"]+)##s) {
		$self->{'title'} = $1;
	} elsif ($html =~ s#\<\/script\>\s*\<title\>([^\<]+)##si) {
		$self->{'title'} = $1;
	}
	if ($self->{'title'}) {
		if ($self->{'album'}) {
			$self->{'title'} =~ s#^$self->{'album'}\s*\-\s*##;
		} else {
			$self->{'album'} = $1  if ($self->{'title'} =~ s#^([^\-]+)\-\s*##);
		}
	}

	#DESCRIPTION:
	$self->{'description'} = $1  if ($html =~ s#\<meta\s+(?:name\=\"description\"|property="og:description")\s+content\=\"([^\"]+)##s);
	$self->{'description'} ||= $self->{'title'};

	#YEAR:
	if ($html =~ s#\>$self->{'album'}\<\/a\>\<div\s+class\=\"[a-z0-9]+\"\>([^\<]+)\<\/div\>##si) {
		my $datestuff = $1;
		$self->{'year'} = $1  if ($datestuff =~ /(\d\d\d\d)\s*$/);
	}
	if (!$self->{'year'} && $html =~ m#\,(\d{10}\d?)\,\d+\,#) {
		$self->{'created'} = scalar(localtime($1));
		$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
	}

	#ALBUMARTIST:
	($self->{'albumartist'} = $url2fetch) =~ s#\/episode\/.+$##;

	#ICON/IMAGE:
	if ($html =~ m#\<img\s+([^\>]+)#si) {
		my $imgdata = $1;	
		$self->{'iconurl'} = $1  if ($imgdata =~ m#src\=\"([^\"]+)#i);
	}
	$self->{'imageurl'} = $self->{'iconurl'};
	
	$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
	$self->{'title'} = uri_unescape($self->{'title'});
#	$self->{'title'} =~ s#\\u0027#\"#g;
	$self->{'title'} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	$self->{'description'} = HTML::Entities::decode_entities($self->{'description'});
	$self->{'description'} = uri_unescape($self->{'description'});
	$self->{'description'} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
	$self->{'Url'} = ($self->{'total'} > 0) ? $self->{'streams'}->[0] : '';
	print STDERR "-(all)count=".$self->{'cnt'}."= iconurl=".$self->{'iconurl'}."= TITLE=".$self->{'title'}."= DESC=".$self->{'description'}."= YEAR=".$self->{'year'}."= artist=".$self->{'artist'}."= albart=".$self->{'albumartist'}."=\n"  if ($DEBUG);
	print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"  if ($DEBUG);

	#GENERATE EXTENDED-M3U PLAYLIST:

	$self->{'playlist'} = "#EXTM3U\n";
print STDERR "=====EPISTREAM COUNT=".scalar(@epiStreams)."=\n";
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

sub getIconData
{
	my $self = shift;
	return ()  unless ($self->{'iconurl'});

	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $art_image = '';
	my $response = $ua->get($self->{'iconurl'});
	if ($response->is_success) {
		$art_image = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	return ()  unless ($art_image);

	(my $image_ext = $self->{'iconurl'}) =~ s/^.+\.//;
	$image_ext =~ s/[^A-Za-z].*$//;
	$image_ext = 'png'  unless ($image_ext =~ /^(?:png|jpg|jpeg|gif)$/i);
	return ($image_ext, $art_image);
}

sub getImageData
{
	my $self = shift;
	return ()  unless ($self->{'imageurl'});
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $art_image = '';
	my $response = $ua->get($self->{'imageurl'});
	if ($response->is_success) {
		$art_image = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	return ()  unless ($art_image);

	(my $image_ext = $self->{'iconurl'}) =~ s/^.+\.//;
	$image_ext =~ s/[^A-Za-z].*$//;
	$image_ext = 'png'  unless ($image_ext =~ /^(?:png|jpg|jpeg|gif)$/i);
	return ($image_ext, $art_image);
}

1
