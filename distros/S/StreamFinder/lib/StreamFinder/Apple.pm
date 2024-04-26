=head1 NAME

StreamFinder::Apple - Fetch actual raw streamable URLs from Apple 
podcasts on podcasts.apple.com

=head1 AUTHOR

This module is Copyright (C) 2017-2021 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::Apple;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $podcast = new StreamFinder::Apple($ARGV[0]);

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

	print "PODCAST ID=$podcastID\n";
	
	my $artist = $podcast->{'artist'};

	print "Artist=$artist\n"  if ($artist);
	
	my $genre = $podcast->{'genre'};

	print "Genre=$genre\n"  if ($genre);
	
	my $icon_url = $podcast->getIconURL();

	if ($icon_url) {   #SAVE THE ICON TO A TEMP. FILE:

		my ($image_ext, $icon_image) = $podcast->getIconData();

		if ($icon_image && open IMGOUT, ">/tmp/${podcastID}.$image_ext") {

			binmode IMGOUT;

			print IMGOUT $icon_image;

			close IMGOUT;

		}

	}

	my $stream_count = $podcast->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $podcast->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::Apple accepts a valid podcast or episode URL on 
podcasts.apple.com, and returns the actual stream URL(s), title, and cover 
art icon for that podcast.  The purpose is that one needs one of these URLs 
in order to have the option to stream the station in one's own choice of 
media player software rather than using their web browser and accepting any / 
all flash, ads, javascript, cookies, trackers, web-bugs, and other crapware 
that can come with that method of play.  The author uses his own custom 
all-purpose media player called "fauxdacious" (his custom hacked version of 
the open-source "audacious" audio player.  "fauxdacious" incorporates this 
module to decode and play podcasts.apple.com streams.

NOTE:  The URL must be either a podcast site, format:  
https://podcasts.apple.com/I<country>/podcast/idB<podcast#> 
(returns stream(s) for all "episodes" for that site, OR a specific podcast / 
"episode" page site, format:  
https://podcasts.apple.com/I<country>/podcast/idB<podcast#>?i=B<episode#> 
(returns a single stream for that specific podcast).  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ]])

Accepts a podcasts.apple.com ID or URL and creates and 
returns a new podcast object, or I<undef> if the URL is not a valid podcast, 
album, etc. or no streams are found.  The URL can be the full URL, 
ie. https://podcasts.apple.com/podcast/idI<podcast-id>, 
https://podcasts.apple.com/podcast/idB<podcast-id>?i=B<episode-id>, or just 
I<podcast-id>, or I<podcast-id>/I<episode-id>.  

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
[site]:  The site name (Apple).  [url]:  The url searched for streams.  
[time]: Perl timestamp when the line was logged.  [title], [artist], [album], 
[description], [year], [genre], [total], [albumartist]:  The corresponding field data 
returned (or "I<-na->", if no value).

=item $podcast->B<get>(['playlist'])

Returns an array of strings representing all stream urls found.
If I<"playlist"> is specified, then an extended m3u playlist is returned 
instead of stream url(s).  NOTE:  If an author / channel page url is given, 
rather than an individual podcast episode's url, get() returns the first 
(latest?) podcast episode found, and get("playlist") returns an extended 
m3u playlist containing the urls, titles, etc. for all the podcast 
episodes found on that page url.

=item $podcast->B<getURL>([I<options>])

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

=item $podcast->B<count>(['playlist'])

Returns the number of streams found for the podcast.
If I<"playlist"> is specified, the number of episodes returned in the 
playlist is returned (the playlist can have more than one item if a 
podcast page URL is specified).

=item $podcast->B<getID>()

Returns the station's Apple ID (numeric).  For podcasts and albums, this 
is a single numeric value.  For episodes and songs, it's two numbers 
separated by a slash ("/").

=item $podcast->B<getTitle>(['desc'])

Returns the podcast's, album's, episode's or song clip's title, 
or (long description).  

=item $podcast->B<getIconURL>(['artist'])

Returns the url for the podcast's / album's "cover art" icon image, 
if any.
If B<'artist'> is specified, the channel artist's icon url is returned, 
if any.  Note:  This requires StreamFinder::Apple to also fetch the 
channel artist's (AlbumArtist) url as this icon is currently not included 
on the podcast's page.

=item $podcast->B<getIconData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.
If B<'artist'> is specified, the channel artist's icon data is returned, 
if any.

=item $podcast->B<getImageURL>()

Returns the url for the podcast's / album's "cover art" banner image, 
which for Apple is always the icon image, as Apple does not support 
a separate banner image at this time.

=item $podcast->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual station's banner image (binary data).

=item $podcast->B<getType>()

Returns the station's type ("Apple").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/Apple/config

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
Blank lines and lines starting with a "#" sign are ignored.

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

apple podcasts

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-apple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Apple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Apple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Apple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Apple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Apple>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Apple/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2021 Jim Turner.

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

package StreamFinder::Apple;

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

	my $self = $class->SUPER::new('Apple', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});

	$self->{'id'} = '';
	(my $url2fetch = $url);
	if ($url2fetch =~ m#^https?\:\/\/(?:embed\.)?podcasts\.apple\.#) {
#EXAMPLE1:my $url = 'https://podcasts.apple.com/us/podcast/wnbc-sec-shorts-josh-snead/id1440412195?i=1000448441439';
#EXAMPLE2:my $url = 'https://podcasts.apple.com/us/podcast/good-bull-hunting-for-texas-a-m-fans/id1440412195';
		$self->{'id'} = ($url =~ m#\/(?:id)?(\d+)(?:\?i\=(\d+))?\/?#) ? $1 : '';
		$self->{'id'} .= '/'. $2  if (defined $2);
	} elsif ($url2fetch !~ m#^https?\:\/\/#) {
		my ($id, $podcastid) = split(m#\/#, $url2fetch);
		$self->{'id'} = $id;
		$url2fetch = 'https://podcasts.apple.com/podcast/id' . $id;
		$url2fetch .= '?i=' . $podcastid  if ($podcastid);
	}

	print STDERR "--URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	return undef  unless ($self->{'id'});

	my $html = '';
	print STDERR "-0(Apple): ID=".$self->{'id'}."= AGENT=".join('|',@{$self->{'_userAgentOps'}})."=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $response;
	$self->{'albumartist'} = $url2fetch;
	my @epiTitles = ();
	my @epiStreams = ();
	my @epiGenres = ();
	my $embedepisode = '';

	if ($self->{'id'} !~ m#\/#) {   #PAGE (multiple episodes):
		print STDERR "i:FETCHING PAGE URL ($url2fetch)...\n"  if ($DEBUG);
		$response = $ua->get($url2fetch);
		if ($response->is_success) {
			$html = $response->decoded_content;
		} else {
			print STDERR $response->status_line  if ($DEBUG);
			my $no_wget = system('wget','-V');
			unless ($no_wget) {
				print STDERR "\n..trying wget...\n"  if ($DEBUG);
				$html = `wget -t 2 -T 20 -O- -o /dev/null \"$url2fetch\" 2>/dev/null `;
			}
		}

		print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
		return undef  unless ($html);

		if ($url2fetch =~ s#\/\/embed.podcast#\/\/podcast#) {  #HANDLE "EMBEDDED PODCAST URLS:
			print STDERR "--2a: EMBEDDED PODCAST, take 5, then fetch podcast page ($url2fetch)...\n"  if ($DEBUG);
			sleep 5;  #AVOID HITTING 'EM TOO QUICK IN SUCCESSION (AVOID DOS SUSPICION):
			$response = $ua->get($url2fetch);
			if ($response->is_success) {  #JETCH PODCAST PAGE:
				$html = $response->decoded_content;
			} else {
				print STDERR $response->status_line  if ($DEBUG);
				my $no_wget = system('wget','-V');
				unless ($no_wget) {
					print STDERR "\n..trying wget...\n"  if ($DEBUG);
					$html = `wget -t 2 -T 20 -O- -o /dev/null \"$url2fetch\" 2>/dev/null `;
				}
			}

			print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
			return undef  unless ($html);

			$embedepisode = $url2fetch;
			if ($html =~ m#${embedepisode}\?i\=(\d+)#s) {
				$self->{'id'} = $1;
				$url2fetch .= '?i=' . $1;
				print STDERR "--3: EMBEDDED EPISODE FOUND (id=$1): URL=$url2fetch)!\n"  if ($DEBUG);
			} else {
				return undef;
			}
		} else {
			my $ep1id = $1  if ($html =~ m#\bdata\-episode\-id\=\"([^\"]+)#);
			$ep1id ||= $1  if ($html =~ m#\btargetId\&quot\;\:\&quot\;(\d+)#);
			return undef  unless ($ep1id);

			$url2fetch = 'https://podcasts.apple.com/podcast/id' . $self->{'id'}
					. '?i=' . $ep1id;
			$self->{'id'} .= '/' . $ep1id;

			$self->{'articonurl'} = ($html =~ m#\<img\s+class\=\".*?src\=\"([^\"]+)#s) ? $1 : '';
			$self->{'articonurl'} = ($html =~ /\s+srcset\=\"([^\"\s]+)/s) ? $1 : ''
					if ($self->{'articonurl'} !~ /^http/);

			$html =~ s#^.+?\"episodes\\?\"\:\{##s;
			while ($html =~ s#^(.+?)\"assetUrl\\?\"\:\\?\"([^\\\"]+)##so) {
				my $pre = $1;
				my $stream = $2;
				next  if ($self->{'secure'} && $stream !~ /^https/o);

				my $title = ($pre =~ s#\"(?:name|itunesTitle)\\?\"\:\\?\"(.+?)\\?\"\,##so) ? $1 : '';
				next  unless ($title);

				$title =~ s#\\##g;
				$title = HTML::Entities::decode_entities($title);
				$title = uri_unescape($title);
				$title =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
				my $genre = ($pre =~ m#\"genreNames\\?\"\:\[\\?\"(.+?)\\?\"[\,\]]#so) ? $1 : '';
				$genre =~ s#\\##g;

				push @epiStreams, $stream;
				push @epiTitles, $title;
				push @epiGenres, $genre;
			}
		}
 	}

#FETCH EPISODE:

	print STDERR "i:FETCHING EPISODE URL ($url2fetch)...\n"  if ($DEBUG);
	$response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
		my $no_wget = system('wget','-V');
		unless ($no_wget) {
			print STDERR "\n..trying wget...\n"  if ($DEBUG);
			$html = `wget -t 2 -T 20 -O- -o /dev/null \"$url2fetch\" 2>/dev/null `;
		}
	}

	print STDERR "-2: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html);

	$html =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
	$self->{'iconurl'} = ($html =~ m#\<img\s+class\=\".*?src\=\"([^\"]+)#s) ? $1 : '';
	if ($self->{'iconurl'} !~ /^http/) {
		$self->{'iconurl'} = ($html =~ /\s+srcset\=\"([^\"\s]+)/s) ? $1 : '';
	}
	$self->{'imageurl'} = $self->{'iconurl'};
	
	if ($html =~ m#\<span\s+class\=\"product\-header\_\_identity(.+?)\<\/span\>#s) {
		my $span = $1;
		$self->{'album'} = $1  if ($span =~ m#\>\s*([^\<]+)\<\/a#s);
		if ($self->{'album'} !~ /\w/) {
			$self->{'album'} = $1  if ($span =~ m#\>\s*([^\<]+)#s);
		}
		$self->{'album'} =~ s/\s+$//;
		$self->{'albumartist'} = $1  if ($span =~ m#href\=\"([^\"]+)\"\s+class\=\"link#is);
	}
	$self->{'artist'} = $1  if ($html =~ m#\"creator\"\:\"([^\"]+)#);
	if (!$self->{'artist'} && $html =~ m#\<li\s+class\=\"tracklist\-footer\_\_item\"\>([^\<]+)#s) {
		$self->{'artist'} = $1;
		$self->{'artist'} =~ s/^\s+//s;
		$self->{'artist'} =~ s/\s+$//s;
	}
	if ($html =~ m#\<li\s+class\=\"product\-header\_\_list\_\_item\"\>(.*?)\<\/ul\>#s) {
		my $prodlistitemdata = $1;
		$self->{'genre'} = $1  if ($prodlistitemdata =~ s#genre\"?\>\s*([^\<]+)\<\/##s);
		$self->{'year'} = $1  if ($prodlistitemdata =~ m#\>([\d]+)\D*\<\/time\>#s);
	}
	$self->{'genre'} ||= $1  if ($html =~ m#\<li\s+class\=\"inline\-list\_\_item[^\>]+\>(.*?)\<\/li\>#s);
	if ($html =~ m#\<h1(.+?)\<\/h1\>#si) {
		my $titlestuff = $1;
		if ($titlestuff =~ m#\s+aria\-label\=\"([^\"]+)#s) {
			$self->{'title'} = $1;
		} elsif ($titlestuff =~ m#\>(.+?)\<\/span\>#s) {
			$self->{'title'} = $1;
		}
	}
	$self->{'title'} ||= $1  if ($html =~ s#\"(?:name|itunesTitle)\\?\"\:\\?\"(.+?)\\?\"\,##so);
	$self->{'title'} =~ s#\\##g;
	if ($html =~ m#episode\-description\>(.+?)\<\/section\>#s) {
		$self->{'description'} = $1;
		$self->{'description'} =~ s#\<p[^\>]*\>(.+?)\<\/p\>#$1#s;
	}
	$self->{'description'} ||= $1  if ($html =~ m#\"description\\?\"\:\{\\?\"standard\\?\"\:\\?\"([^\\\"]+)#s);
	$self->{'description'} ||= $1  if ($html =~ m#\"short\"\:\"([^\"]+)\"#s);
	$self->{'created'} = $1  if ($html =~ m#\"datePublished\"\:\"([^\"]+)#s);
	while ($html =~ s#\"assetUrl\\?\"\:\\?\"([^\\\"]+)##s) {
		my $stream = $1;
		push (@{$self->{'streams'}}, $stream)  unless ($self->{'secure'} && $stream !~ /^https/o);
	}
	$self->{'cnt'} = scalar @{$self->{'streams'}};
	$self->{'total'} = $self->{'cnt'};
	return undef  unless ($self->{'total'} > 0);

	$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
	if ($self->{'genre'})	{
		$self->{'genre'} =~ s/^\s+//;
		$self->{'genre'} =~ s/\s+$//;
	} else {
		$self->{'genre'} = 'Podcast';
	}
	$self->{'imageurl'} = $self->{'iconurl'};
	if ($self->{'description'} =~ /\w/) {
		$self->{'description'} =~ s/\s+$//;
		$self->{'description'} =~ s/^\s+//;
	} else {
		$self->{'description'} = $self->{'title'};
	}
	foreach my $i (qw(title artist album description genre)) {
		$self->{$i} = HTML::Entities::decode_entities($self->{$i});
		$self->{$i} = uri_unescape($self->{$i});
		$self->{$i} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
	}
	$self->{'Url'} = $self->{'streams'}->[0];
	print STDERR "-SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"  if ($DEBUG);
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
			$self->{'playlist'} .= "#EXTGENRE:" . ($epiGenres[$i] || $self->{'genre'}) . "\n"
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
	if ($DEBUG) {
		foreach my $f (sort keys %{$self}) {
			print "--KEY=$f= VAL=$$self{$f}=\n";
		}
	}

	$self->_log($url);

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub getIconURL
{
	my $self = shift;
	return $self->{'iconurl'}  unless (defined($_[0]) && $_[0] =~ /^\-?artist/i);

	unless ($self->{'articonurl'}) {
		my $html = '';
		return ''  unless ($self->{'albumartist'} && $self->{'albumartist'} =~ m#^https?\:\/\/#);

		my $url2fetch = $self->{'albumartist'};
		print STDERR "-0(Fetch Apple Channel for alt. icon from $url2fetch): \n"  if ($DEBUG);
		my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});
		$ua->timeout($self->{'timeout'});
		$ua->cookie_jar({});
		$ua->env_proxy;
		my $response = $ua->get($url2fetch);
		if ($response->is_success) {
			$html = $response->decoded_content;
		} else {
			print STDERR $response->status_line  if ($DEBUG);
			my $no_wget = system('wget','-V');
			unless ($no_wget) {
				print STDERR "\n..trying wget...\n"  if ($DEBUG);
				$html = `wget -t 2 -T 20 -O- -o /dev/null \"$url2fetch\" 2>/dev/null `;
			}
		}

		print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
		return ''  unless ($html);

		$self->{'articonurl'} = ($html =~ m#\<img\s+class\=\".*?src\=\"([^\"]+)#s) ? $1 : '';
		$self->{'articonurl'} = ($html =~ /\s+srcset\=\"([^\"\s]+)/s) ? $1 : ''
				if ($self->{'articonurl'} !~ /^http/);
		print STDERR "--ART ICON URL=".$self->{'articonurl'}."=\n"  if ($DEBUG);
	}
	return $self->{'articonurl'};
}

1
