=head1 NAME

StreamFinder::Tunein - Fetch actual raw streamable URLs from radio-station websites on Tunein.com

=head1 AUTHOR

This module is Copyright (C) 2019 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	use strict;

	use StreamFinder::Tunein;

	my $station = new StreamFinder::Tunein(<url>);

	die "Invalid URL or no streams found!\n"  unless ($station);

	my @streams = $station->get();

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

StreamFinder::Tunein accepts a valid radio station or podcast ID or URL on 
Tunein.com and returns the actual stream URL(s), title, and cover art icon.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the station in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of playing.  The author uses his own custom all-purpose media player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
Tunein.com streams.  One or more streams can be returned for each station.  

NOTE:  Tunein uses StreamFinder::Youtube (youtube-dl) to extract the actual 
stream and only returns a SINGLE valid stream URL for a station based on a 
boilerplate url based on the station's ID.  However, youtube-dl does NOT return 
the metadata, which we're able to extract here.  This may or may NOT work for a 
given station (particularly non-free / subscription-required stations, ymmv)!

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, "debug" [ => 0|1|2 ]])

Accepts a tunein.com URL and creates and returns a new station object, or 
I<undef> if the URL is not a valid tunein station or no streams are found.

=item $station->B<get>()

Returns an array of strings representing all stream urls found.

=item $station->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  

Current options are:  I<"random"> and I<"noplaylists">.  By default, the 
first ("best"?) stream is returned.  If I<"random"> is specified, then 
a random one is selected from the list of streams found.  
If I<"noplaylists"> is specified, and the stream to be returned is a 
"playlist" (.pls or .m3u? extension), it is first fetched and the first entry 
in the playlist is returned.  This is needed by Fauxdacious Mediaplayer.

=item $station->B<count>()

Returns the number of streams found for the station.

=item $station->B<getID>(['fccid'])

Returns the station's Tunein ID (default) or 
station's FCC call-letters ("fccid").

=item $station->B<getTitle>(['desc'])

Returns the station's title, or (long description).  

=item $station->B<getIconURL>()

Returns the url for the station's "cover art" icon image, if any.

=item $station->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc. and the actual icon image (binary data), if any.

=item $station->B<getImageURL>()

Returns the url for the station's "cover art" banner image, if any.

=item $station->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc. and the actual station's banner image (binary data).

=item $station->B<getType>()

Returns the station's type ("Tunein").

=back

=head1 CONFIGURATION FILES

=over 4

=item ~/.config/StreamFinder/Tunein/config

Optional text file for specifying various configuration options 
for a specific site (submodule).  Each option is specified on a 
separate line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used only by the specific 
(submodule) specified.  Valid options include 
I<-debug> => [0|1|2], and most of the L<LWP::UserAgent> options.  
Blank lines and lines starting with a "#" sign are ignored.

Options specified here override any specified in I<~/.config/StreamFinder/config>.

=item ~/.config/StreamFinder/config

Optional text file for specifying various configuration options.  
Each option is specified on a separate line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used by all sites 
(submodules) that support them.  Valid options include 
I<-debug> => [0|1|2], and most of the L<LWP::UserAgent> options.
Blank lines and lines starting with a "#" sign are ignored.

=back

NOTE:  Options specified in the options parameter list will override 
those corresponding options specified in these files.

=head1 KEYWORDS

tunein

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-tunein at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Tunein>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Tunein

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Tunein>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Tunein>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Tunein>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Tunein/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jim Turner.

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

my $haveYoutube = 0;
eval "use StreamFinder::Youtube; \$haveYoutube = 1; 1";

package StreamFinder::Tunein;

use strict;
use warnings;
use URI::Escape;
use HTML::Entities ();
use LWP::UserAgent ();
use vars qw(@ISA @EXPORT);


my $DEBUG = 0;
my %uops = ();
my @userAgentOps = ();

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(get getURL getType getID getTitle getIconURL getIconData getImageURL getImageData);

sub new
{
	my $class = shift;
	my $url = shift;

	my $self = {};
	return undef  unless ($url);

	foreach my $p ("$ENV{HOME}/.config/StreamFinder/config", "$ENV{HOME}/.config/StreamFinder/Tunein/config") {
		if (open IN, $p) {
			my ($atr, $val);
			while (<IN>) {
				chomp;
				next  if (/^\s*\#/o);
				($atr, $val) = split(/\s*\=\>\s*/o, $_, 2);
				eval "\$uops{$atr} = $val";
			}
			close IN;
		}
	}
	foreach my $i (qw(agent from conn_cache default_headers local_address ssl_opts max_size
			max_redirect parse_head protocols_allowed protocols_forbidden requests_redirectable
			proxy no_proxy)) {
		push @userAgentOps, $i, $uops{$i}  if (defined $uops{$i});
	}
	push (@userAgentOps, 'agent', 'Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0')
			unless (defined $uops{'agent'});
	$uops{'timeout'} = 10  unless (defined $uops{'timeout'});
	$DEBUG = $uops{'debug'}  if (defined $uops{'debug'});

	while (@_) {
		if ($_[0] =~ /^\-?debug$/o) {
			shift;
			$DEBUG = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
		}
	}	

	my $html = '';
	print STDERR "-0(Tunein): URL=$url=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new(@userAgentOps);		
	$ua->timeout($uops{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	$self->{'id'} = '';
	$self->{'title'} = '';
	$self->{'artist'} = '';
	$self->{'created'} = '';
	$self->{'year'} = '';
	$self->{'streams'} = [];
	$self->{'cnt'} = 0;
	

	(my $url2fetch = $url);
	#DEPRECIATED (STATION-IDS NOW INCLUDE STUFF BEFORE THE DASH: ($self->{'id'} = $url) =~ s#^.*\-([a-z]\d+)\/?$#$1#;
	if ($url2fetch =~ m#^https?\:#) {
		($self->{'id'} = $url) =~ s#^.*?\/([a-zA-Z0-9\-\_]+)(?:\/?|\/\?[^\/]+\/?)$#$1#;
	} else {
		my ($id, $podcastid) = split(m#\/#, $url2fetch);
		$url2fetch = 'https://tunein.com/radio/' . $id;
		$url2fetch .= '/?topicId=' . $podcastid  if ($podcastid);
		$self->{'id'} = $id;
	}
	print STDERR "-1 FETCHING URL=$url2fetch=\n"  if ($DEBUG);
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
	if ($html) {  #EXTRACT METADATA, IF WE CAN:
		print STDERR "-1: EXTRACTING METADATA...\n"  if ($DEBUG);
		my $artist;
		$self->{'id'} = $1  if ($html =~ m#\"guideId\"\:\"([^\"]+)\"#);
		$self->{'fccid'} = ($html =~ m#\"callSign\"\:\"([^\"]+)\"#i) ? $1 : '';
		$self->{'title'} = ($html =~ m#\"twitter\:title\"\s+content\=\"([^\"]+)\"#) ? $1 : '';
		$self->{'description'} = $self->{'title'};
		$artist = ($html =~ m#\"title\"\:\"([^\"]+)\"#) ? $1 : '';
		$artist ||= ($html =~ m# title\=\"([^\"]+)\" #) ? $1 : '';
		if ($artist && $self->{'title'} !~ /\w/) {
			$self->{'title'} = $artist;
			$artist = '';
		}
		$self->{'artist'} = ($html =~ m#\"subtitle\"\:\"([^\"]+)\"#i) ? $1 : '';
		$self->{'description'} = ($html =~ m#name\=\"twitter\:description\"\s+content\=\"([^\"]+)\"#i) ? $1 : $self->{'title'};
		$self->{'description'} = HTML::Entities::decode_entities($self->{'description'});
		$self->{'description'} = uri_unescape($self->{'description'});
		$self->{'iconurl'} = ($html =~ m#\"twitter\:image\:src\"\s+content\=\"([^\"]+)\"#) ? $1 : '';
		$self->{'iconurl'} ||= ($html =~ m#\"image\"\:\"([^\"]+)\"#) ? $1 : '';
		$self->{'iconurl'} =~ s#\\u002F#\/#g;
		$self->{'iconurl'} =~ s#\?.+$##;
		$self->{'imageurl'} = ($html =~ m#\"bannerImage\"\:\"([^\"]+)\"#) ? $1 : $self->{'iconurl'};
		$self->{'imageurl'} =~ s#\\u002F#\/#g;
		$self->{'imageurl'} =~ s#\?.+$##;
		if ($self->{'artist'} =~ /\S/) {
			$self->{'artist'} =~ s/\s*\\?u?003E\s*$//;
			$artist .= ' - '  if ($artist);
			$artist .= $self->{'artist'}
		}
		if ($artist) {
			$artist = HTML::Entities::decode_entities($artist);
			$artist = uri_unescape($artist);
			$self->{'artist'} = $artist;
		}
		my $genre = ($html =~ m#\"rootGenre\"\:\"([^\"]+)\"#) ? $1 : '';
		my $subgenre = ($html =~ m#\"primaryGenreName\"\:\"([^\"]+)\"#) ? $1 : '';
		if ($genre && $subgenre) {
			$self->{'genre'} = ($genre eq 'music') ? $subgenre : $genre . ' - ' . $subgenre;
		} elsif ($genre) {
			$self->{'genre'} = $genre;
		} elsif ($subgenre) {
			$self->{'genre'} = $subgenre;
		}
	}
	return undef  unless ($self->{'id'});

	my $stationID = $self->{'id'};
	$self->{'streams'} = [];
	$self->{'cnt'} = 0;
	while ($html =~ s#\"playUrl\"\:\"([^\"]+)\"#STREAMFINDER_MARK#i) {  #PROBABLY A PODCAST?:
		(my $one = $1) =~ s#\\u002F#\/#g;
		$one =~ s#\.mp3\?.*$#\.mp3#;   #STRIP OFF EXTRA GARBAGE PARMS, COMMENT OUT IF STARTS FAILING!
		push @{$self->{'streams'}}, $one;
		$self->{'cnt'}++;
		print STDERR "i:Found stream ($one) in page.\n"  if ($DEBUG);
	}
	if ($self->{'cnt'}) {   #STREAM(S) FOUND, PBLY A PODCAST:
		$self->{'id'} .= '/' . $1  if ($html =~ s#\"guideId\"\:\"([^\"]+)\"\,STREAMFINDER_MARK#STREAMFINDER_MARK#i);
		$self->{'created'} = $1  if ($html =~ s#\"publishTime\"\:\"([^\"]*)\"\,STREAMFINDER_MARK##i);
		$self->{'year'} = (defined($self->{'created'}) && $self->{'created'} =~ /(\d\d\d\d)/) ? $1 : '';
		print STDERR "i:Podcast found, ID changed to (".$self->{'id'}."), year (".$self->{'year'}.").\n"  if ($DEBUG);
	} else {  #(USUALLY) NO STREAMS FOUND, TRY youtube-dl!:
		my $tryStream = "http://opml.radiotime.com/Tune.ashx?id=$stationID";
		if ($haveYoutube) {
			$_ = `youtube-dl --get-url  "$tryStream"`;
			print STDERR "-2 TRYING($tryStream): YT returned ($_)!\n"  if ($DEBUG);
			my @urls = split(/\r?\n/);
			while (@urls && $urls[0] !~ m#^https?\:\/\/#o) {
				shift @urls;
			}
			if (scalar(@urls) > 0) {
				print STDERR "i:Found stream(s) (".join('|',@urls).") via youtube-dl.\n"  if ($DEBUG);
				@{$self->{'streams'}} = @urls;
				$self->{'cnt'} = scalar @urls;
			}
		}
	}
	$self->{'total'} = $self->{'cnt'};
	$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
	$self->{'title'} = uri_unescape($self->{'title'});
	print STDERR "\n--ID=".$self->{'id'}."=\n--TITLE=".$self->{'title'}."\n--ARTIST=".$self->{'artist'}."=\n--STREAMS=".join('|',@{$self->{'streams'}})."=\n"  if ($DEBUG);

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub get
{
	my $self = shift;

	return wantarray ? @{$self->{'streams'}} : ${$self->{'streams'}}[0];
}

sub getURL   #LIKE GET, BUT ONLY RETURN THE SINGLE ONE W/BEST BANDWIDTH AND RELIABILITY:
{
	my $self = shift;
	my $arglist = (defined $_[0]) ? join('|',@_) : '';
	my $idx = ($arglist =~ /\b\-?random\b/) ? int rand scalar @{$self->{'streams'}} : 0;
	if ($arglist =~ /\b\-?noplaylists\b/ && ${$self->{'streams'}}[$idx] =~ /\.(pls|m3u8?)$/i) {
		my $plType = $1;
		my $firstStream = ${$self->{'streams'}}[$idx];
		print STDERR "-getURL($idx): NOPLAYLISTS and (".${$self->{'streams'}}[$idx].")\n"  if ($DEBUG);
		my $ua = LWP::UserAgent->new(@userAgentOps);		
		$ua->timeout($uops{'timeout'});
		$ua->cookie_jar({});
		$ua->env_proxy;
		my $html = '';
		my $response = $ua->get($firstStream);
		if ($response->is_success) {
			$html = $response->decoded_content;
		} else {
			print STDERR $response->status_line  if ($DEBUG);
			my $no_wget = system('wget','-V');
			unless ($no_wget) {
				print STDERR "\n..trying wget...\n"  if ($DEBUG);
				$html = `wget -t 2 -T 20 -O- -o /dev/null \"$firstStream\" 2>/dev/null `;
			}
		}
		my @lines = split(/\r?\n/, $html);
		$firstStream = '';
		if ($plType =~ /pls/) {  #PLS:
			my $firstTitle = '';
			foreach my $line (@lines) {
				if ($line =~ m#^\s*File\d+\=(.+)$#) {
					$firstStream ||= $1;
				} elsif ($line =~ m#^\s*Title\d+\=(.+)$#) {
					$firstTitle ||= $1;
				}
			}
			$self->{'title'} ||= $firstTitle;
			print STDERR "-getURL(PLS): first=$firstStream= title=$firstTitle=\n"  if ($DEBUG);
		} else {  #m3u8:
			(my $urlpath = ${$self->{'streams'}}[$idx]) =~ s#[^\/]+$##;
			foreach my $line (@lines) {
				if ($line =~ m#^\s*([^\#].+)$#) {
					my $urlpart = $1;
					$urlpart =~ s#^\s+##;
					$urlpart =~ s#^\/##;
					$firstStream = ($urlpart =~ m#https?\:#) ? $urlpart : ($urlpath . '/' . $urlpart);
					last;
				}
			}
			print STDERR "-getURL(m3u?): first=$firstStream=\n"  if ($DEBUG);
		}
		return $firstStream || ${$self->{'streams'}}[$idx];
	}
	return ${$self->{'streams'}}[$idx];
}

sub count
{
	my $self = shift;
	return $self->{'total'};  #TOTAL NUMBER OF PLAYABLE STREAM URLS FOUND.
}

sub getType
{
	my $self = shift;
	return 'Tunein';  #STATION TYPE (FOR PARENT StreamFinder MODULE).
}

sub getID
{
	my $self = shift;
	return $self->{'fccid'}  if (defined($_[0]) && $_[0] =~ /fcc/i);  #STATION'S CALL LETTERS OR TUNEIN-ID.
	return $self->{'id'};
}

sub getTitle
{
	my $self = shift;
	return $self->{'description'}  if (defined($_[0]) && $_[0] =~ /^\-?(?:long|desc)/i);
	return $self->{'title'};  #STATION'S TITLE(DESCRIPTION), IF ANY.
}

sub getIconURL
{
	my $self = shift;
	return $self->{'iconurl'};  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
}

sub getIconData
{
	my $self = shift;
	return ()  unless ($self->{'iconurl'});
	my $ua = LWP::UserAgent->new(@userAgentOps);		
	$ua->timeout($uops{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $art_image = '';
	my $response = $ua->get($self->{'iconurl'});
	if ($response->is_success) {
		$art_image = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
		my $no_wget = system('wget','-V');
		unless ($no_wget) {
			print STDERR "\n..trying wget...\n"  if ($DEBUG);
			my $iconUrl = $self->{'iconurl'};
			$art_image = `wget -t 2 -T 20 -O- -o /dev/null \"$iconUrl\" 2>/dev/null `;
		}
	}
	return ()  unless ($art_image);
	my $image_ext = $self->{'iconurl'};
	$image_ext =~ s/^.+\.//;
	$image_ext =~ s/[^A-Za-z].*$//;
	return ($image_ext, $art_image);
}

sub getImageURL
{
	my $self = shift;
	return $self->{'imageurl'};  #URL TO THE STATION'S BANNER IMAGE, IF ANY.
}

sub getImageData
{
	my $self = shift;
	return ()  unless ($self->{'imageurl'});
	my $ua = LWP::UserAgent->new(@userAgentOps);		
	$ua->timeout($uops{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $art_image = '';
	my $response = $ua->get($self->{'imageurl'});
	if ($response->is_success) {
		$art_image = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
		my $no_wget = system('wget','-V');
		unless ($no_wget) {
			print STDERR "\n..trying wget...\n"  if ($DEBUG);
			my $iconUrl = $self->{'iconurl'};
			$art_image = `wget -t 2 -T 20 -O- -o /dev/null \"$iconUrl\" 2>/dev/null `;
		}
	}
	return ()  unless ($art_image);
	my $image_ext = $self->{'imageurl'};
	$image_ext = ($self->{'imageurl'} =~ /\.(\w+)$/) ? $1 : 'png';
	$image_ext =~ s/[^A-Za-z].*$//;
	return ($image_ext, $art_image);
}

1
