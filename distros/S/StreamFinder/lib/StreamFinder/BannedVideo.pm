=head1 NAME

StreamFinder::Banned.Video - Fetch actual raw streamable video URLs from banned.video.

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

	use StreamFinder::BannedVideo;

	my $video = new StreamFinder::BannedVideo(<url>);

	die "Invalid URL or no streams found!\n"  unless ($video);

	my $firstStream = $video->get();

	print "First Stream URL=$firstStream\n";

	my $url = $video->getURL();

	print "Stream URL=$url\n";

	my $videoTitle = $video->getTitle();
	
	print "Title=$videoTitle\n";
	
	my $videoDescription = $video->getTitle('desc');
	
	print "Description=$videoDescription\n";
	
	my $videoID = $video->getID();

	print "Video ID=$videoID\n";
	
	my $icon_url = $video->getIconURL();

	if ($icon_url) {   #SAVE THE ICON TO A TEMP. FILE:

		my ($image_ext, $icon_image) = $video->getIconData();

		if ($icon_image && open IMGOUT, ">/tmp/${videoID}.$image_ext") {

			binmode IMGOUT;

			print IMGOUT $icon_image;

			close IMGOUT;

		}

	}

	my $stream_count = $video->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $video->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::BannedVideo accepts a valid video ID or URL on Banned.Video 
(Alex Jones's infowars' new video site after "communist" YouTube BANNED his 
videos) and, at the moment, youtube-dl doesn't convert them (yet?);
and returns the actual title, stream URL(s) and cover art icon for that video.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the video in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, censorship, and other crapware that can come with 
that method of playing.  The author uses his own custom all-purpose media 
player called "fauxdacious" (his custom hacked version of the open-source 
"audacious" audio player).  "fauxdacious" can incorporate this module to decode 
and play banned.video streams.

One or more stream URLs can be returned for each video.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, I<-keep> => "type1,type2?..." | [type1,type2?...] ] | [, I<-debug> [ => 0|1|2 ] ])

Accepts a Banned.Video video ID or URL and creates and returns a new video object, 
or I<undef> if the URL is not a valid Banned.Video video or no streams are found.  
The URL can be the full URL, 
ie. https://banned.video/watch?id=B<video-id>, or just I<video-id>.

The optional I<keep> argument can be either a comma-separated string or an array 
reference ([...]) of stream types to keep (include) and returned in order 
specified (type1, type2...).  Each "type" can be one of:  extension (ie. 
m4a, mp4, etc.), "direct", "stream", or ("any" or "all").

DEFAULT keep list is:  'm4a,direct,stream', meaning that all m4a streams followed 
by all "direct" streams ("directUrl" in page, followed by all remaining 
(non-direct "streamUrl") streams.  More than one value can be specified to 
control order of search.

=item $video->B<get>()

Returns an array of strings representing all stream URLs found.

=item $video->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  

Current options are:  I<"random"> and I<"noplaylists">.  By default, the 
first ("best"?) stream is returned.  If I<"random"> is specified, then 
a random one is selected from the list of streams found.  
If I<"noplaylists"> is specified, and the stream to be returned is a 
"playlist" (.pls or .m3u? extension), it is first fetched and the first entry 
in the playlist is returned.  This is needed by Fauxdacious Mediaplayer.

=item $video->B<count>()

Returns the number of streams found for the video.

=item $video->B<getID>(['fccid'])

Returns the video's Banned.Video ID, or FCC call-letters.

=item $video->B<getTitle>(['desc'])

Returns the video's title, or (long description).  

=item $video->B<getIconURL>()

Returns the URL for the video's "cover art" icon image, if any.

=item $video->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.

=item $video->B<getImageURL>()

Returns the URL for the video's "cover art" (usually larger) 
banner image.

=item $video->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual video's banner image (binary data).

=item $video->B<getType>()

Returns the video's type ("BannedVideo").

=back

=head1 CONFIGURATION FILES

=over 4

=item ~/.config/StreamFinder/BannedVideo/config

Optional text file for specifying various configuration options 
for a specific site (submodule).  Each option is specified on a 
separate line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used only by the specific 
(submodule) specified.  Valid options include 
I<-debug> => [0|1|2], and most of the L<LWP::UserAgent> options.  
Blank lines and lines starting with a "#" sign are ignored.

Options specified here override any specified in I<~/.config/StreamFinder/config>.

Among options valid for BannedVideo streams is the I<-keep> option 
described in the B<new()> function.

=item ~/.config/StreamFinder/config

Optional text file for specifying various configuration options.  
Each option is specified on a separate line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used by all sites 
(submodules) that support them.  Valid options include 
I<-debug> => [0|1|2], and most of the L<LWP::UserAgent> options.

=back

NOTE:  Options specified in the options parameter list will override 
those corresponding options specified in these files.

=head1 KEYWORDS

BannedVideo

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-bannedvideo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-BannedVideo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::BannedVideo

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-BannedVideo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-BannedVideo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-BannedVideo>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-BannedVideo/>

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

package StreamFinder::BannedVideo;

use strict;
use warnings;
use URI::Escape;
use HTML::Entities ();
use LWP::UserAgent ();
use vars qw(@ISA @EXPORT);

my $DEBUG = 0;
my $bummer = ($^O =~ /MSWin/);
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

	my @okStreams;

	my $homedir = $bummer ? $ENV{'HOMEDRIVE'} . $ENV{'HOMEPATH'} : $ENV{'HOME'};
	$homedir ||= $ENV{'LOGDIR'}  if ($ENV{'LOGDIR'});
	$homedir =~ s#[\/\\]$##;
	foreach my $p ("${homedir}/.config/StreamFinder/config", "${homedir}/.config/StreamFinder/Youtube/config") {
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
		} elsif ($_[0] =~ /^\-?keep$/o) {
			shift;
			if (defined $_[0]) {
				my $keeporder = shift;
				@okStreams = (ref($keeporder) =~ /ARRAY/) ? @{$keeporder} : split(/\,\s*/, $keeporder);
			}
		} else {
			shift;
		}
	}	
	if (!defined($okStreams[0]) && defined($uops{'keep'})) {
		@okStreams = (ref($uops{'keep'}) =~ /ARRAY/) ? @{$uops{'keep'}} : split(/\,\s*/, $uops{'keep'});
	}
	@okStreams = (qw(m4a direct stream any))  unless (defined $okStreams[0]);  # one of:  {m4a, <ext>, direct, stream, any, all}

	print STDERR "-0(BannedVideo): URL=$url=\n"  if ($DEBUG);

	(my $url2fetch = $url);
	if ($url =~ /^https?\:/) {
		$self->{'id'} = $1  if ($url2fetch =~ m#\/([^\/]+)\/?$#);
		$self->{'id'} =~ s#^(?:watch\?)?id\=##;
	} else {
		$self->{'id'} = $url;
		$url2fetch = 'https://banned.video/watch?id=' . $url;
	}
	return undef  unless ($self->{'id'});

	$self->{'cnt'} = 0;
	my $html = '';
	print STDERR "-0(BannedVideo): ID=".$self->{'id'}."= URL=$url2fetch=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new(@userAgentOps);		
	$ua->timeout($uops{'timeout'});
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
	return undef  unless ($html);  #STEP 1 FAILED, INVALID VIDEO URL, PUNT!

	my $stindex = 0;
	my @streams = ();
	foreach my $streamtype (@okStreams) {
		while ($html =~ s/\"(?:embed|direct|stream)Url\"\s*\:\s*\"([^\"]+?\.${streamtype}\b[^\"]*)\"//is) {
			$streams[$stindex++] = $1;
		}
		if ($streamtype =~ /^(embed|direct|stream)$/i) {
			my $one = $1;
			while ($html =~ s/\"${one}Url\"\s*\:\s*\"([^\"]+)\"//is) {
				$streams[$stindex++] = $1;
			}
		} elsif ($streamtype =~ /^a(?:ny|ll)$/i) {
			while ($html =~ s/\"(?:embed|direct|stream)Url\"\s*\:\s*\"([^\"]+)\"//is) {
				$streams[$stindex++] = $1;
			}
		}
	}
	print STDERR "-2: 1=$streams[0]= 2=$streams[1]\n"  if ($DEBUG);
	return undef  unless ($#streams >= 0);

	#HACK B/C THEY COMPLICATED UP THEIR SITE (FETCH STREAM FROM FIRST infowarsmedia.com URL FOUND
	#AND ADD IT TO THE TOP)! :/
	for (my $i=0;$i<=$#streams;$i++) {
		if ($streams[$i] =~ m#api\.infowarsmedia\.com/embed#o) {
			my $html = '';
			print STDERR "---STEP 2: INFOWARSMEDIA.COM STREAM ($streams[$i])\n"  if ($DEBUG);
			$url2fetch = $streams[$i];
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
			print STDERR "-STEP 2: html=$html=\n"  if ($DEBUG > 1);
			if ($html =~ m#\bdownloadUrl\=\"([^\"]+)\"#) {
				print STDERR "-3: WILL USE ($1) AS BEST STREAM.\n"  if ($DEBUG);
				unshift @streams, $1;
				last;
			}
		}
	}

	$self->{'cnt'} = scalar @streams;
	$html =~ s/\\\"/\&quot\;/gs;
	$self->{'title'} = ($html =~ /\"title\"\s*\:\s*\"([^\"]+)\"/is) ? $1 : '';
	$self->{'description'} = ($html =~ m#\bname\=\"description\"\s+content\=\"([^\"]+)\"#s) ? $1 : $self->{'title'};
	$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
	$self->{'title'} = uri_unescape($self->{'title'});
	$self->{'description'} = HTML::Entities::decode_entities($self->{'description'});
	$self->{'description'} = uri_unescape($self->{'description'});
	$self->{'iconurl'} = ($html =~ /\"(?:poster)?ThumbnailUrl\"\s*\:\s*\"([^\"]+)\"/is) ? $1 : '';
	$self->{'imageurl'} = ($html =~ /\"posterLargeUrl\"\s*\:\s*\"([^\"]+)\"/is) ? $1 : '';
	$self->{'imageurl'} = $1  if ($html =~ /\"largeImage\"\s*\:\s*\"([^\"]+)\"/is) ? $1 : '';
	$self->{'iconurl'} ||= $self->{'imageurl'};
	$self->{'imageurl'} ||= $self->{'iconurl'};
	$self->{'created'} = $1  if ($html =~ /\"createdAt\"\s*\:\s*\"([^\"]+)\"/is);
	$self->{'updated'} = $1  if ($html =~ /\"updatedAt\"\s*\:\s*\"([^\"]+)\"/is);
	if (defined $self->{'updated'} && $self->{'updated'} =~ /(\d\d\d\d)/) {
		$self->{'year'} = $1;
	} else {
		$self->{'year'} = $1  if (defined($self->{'created'}) && $self->{'created'} =~ /(\d\d\d\d)/);
	}

	$self->{'streams'} = \@streams;  #WE'LL HAVE A LIST OF 'EM TO RANDOMLY CHOOSE ONE FROM:
	$self->{'total'} = $self->{'cnt'};
	print STDERR "-(all)count=".$self->{'cnt'}."= iconurl=".$self->{'iconurl'}."=\n"  if ($DEBUG);
	print STDERR "-SUCCESS: 1st stream=".${$self->{'streams'}}[0]."=\ntitle=".$self->{'title'}."=\n"  if ($DEBUG);

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
	return 'BannedVideo';  #STATION TYPE (FOR PARENT StreamFinder MODULE).
}

sub getID
{
	my $self = shift;
	return $self->{'id'};
}

sub getTitle
{
	my $self = shift;
	return $self->{'description'}  if (defined($_[0]) && $_[0] =~ /^\-?(?:long|desc)/i);
	return $self->{'title'};  #VIDEO'S TITLE(DESCRIPTION), IF ANY.
}

sub getIconURL
{
	my $self = shift;
	return $self->{'iconurl'};  #URL TO THE VIDEO'S THUMBNAIL ICON, IF ANY.
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

	(my $image_ext = $self->{'iconurl'}) =~ s/^.+\.//;
	$image_ext =~ s/[^A-Za-z].*$//;

	return ($image_ext, $art_image);
}

sub getImageURL
{
	my $self = shift;
	return $self->{'imageurl'};  #URL TO THE VIDEO'S BANNER IMAGE, IF ANY.
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
