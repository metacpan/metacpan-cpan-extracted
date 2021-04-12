=head1 NAME

StreamFinder::Youtube - Fetch actual raw streamable URLs from YouTube and others.

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

	use StreamFinder::Youtube;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $video = new StreamFinder::Youtube($ARGV[0]);

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
	
	my $artist = $video->{'artist'};

	print "Artist (channel)=$artist\n"  if ($artist);
	
	my $albumartist = $video->{'albumartist'};

	print "Album Artist (Channel URL)=$albumartist\n"  if ($albumartist);
	
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

StreamFinder::Youtube accepts a valid full YouTube video ID or URL on 
youtube, et. al. that the "youtube-dl" program supports, 
and returns the actual stream URL, title, and cover art icon for that video.  
The purpose is that one needs this URL in order to have the option to 
stream the video in one's own choice of media player software rather 
than using their web browser and accepting any / all flash, ads, 
javascript, cookies, trackers, web-bugs, and other crapware that can 
come with that method of play.  The author uses his own custom all-purpose 
media player called "fauxdacious" (his custom hacked version of the 
open-source "audacious" audio player).  "fauxdacious" incorporates this 
module to decode and play youtube.com videos.  This is a submodule of the 
general StreamFinder module.

Depends:  

L<I::Escape>, L<HTML::Entities>, L<LWP::UserAgent>, 
and the separate application program:  youtube-dl.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, "debug" [ => 0|(1)|2 ]] [, "fast" [ => 0|(1) ]])

Accepts a youtube.com video ID, or any full URL that youtube-dl supports 
and creates and returns a new video object, or I<undef> if the URL is 
not a youtube-supported video URL or no streams are found.  The URL can 
be the full URL, 
ie. https://www.youtube.com/watch?v=B<video-id>, or just I<video-id> 
(if the site is www.youtube.com, since YouTube has multiple sites).

If "fast" or "-fast" is specified (or set to 1), a separate probe of the 
page to fetch the video's title and artist is skipped.  This is useful 
if you know the video is NOT a YouTube video or you don't care about 
the artist (youtube channel's owner) field.

=item $video->B<get>()

Returns an array of strings representing all stream URLs found.

=item $video->B<getURL>([I<options>])

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

=item $video->B<count>()

Returns the number of streams found for the video.

=item $video->B<getID>()

Returns the video's YouTube ID (numeric).

=item $video->B<getTitle>(['desc'])

Returns the station's title, or (long description).  

=item $video->B<getIconURL>()

Returns the URL for the video's "cover art" icon image, if any.

=item $video->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.

=item $video->B<getImageURL>()

Returns the URL for the video's "cover art" banner image, which for 
YouTube videos is always the icon image, as YouTube does not support 
a separate banner image at this time.

=item $video->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual video's banner image (binary data).

=item $video->B<getType>()

Returns the video's type ("Youtube").

=back

=head1 CONFIGURATION FILES

=over 4

=item ~/.config/StreamFinder/Youtube/config

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

=back

NOTE:  Options specified in the options parameter list will override 
those corresponding options specified in these files.

=head1 KEYWORDS

youtube

=head1 DEPENDENCIES

youtube-dl

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>, youtube-dl

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-youtube at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Youtube>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Youtube

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Youtube>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Youtube>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Youtube>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Youtube/>

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

package StreamFinder::Youtube;

use strict;
use warnings;
use URI::Escape;
use HTML::Entities ();
use LWP::UserAgent ();
use vars qw(@ISA @EXPORT);

my $DEBUG = 0;
my $bummer = ($^O =~ /MSWin/);
my $FAST = 0;
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
	$FAST = $uops{'fast'}  if (defined $uops{'fast'});

	while (@_) {
		if ($_[0] =~ /^\-?debug$/o) {
			shift;
			$DEBUG = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
		} elsif ($_[0] =~ /^\-?fast$/o) {
			shift;
			$FAST = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
		}
	}

	print STDERR "-0(Youtube): URL=$url=\n"  if ($DEBUG);
	$url =~ s/\?autoplay\=true$//;  #STRIP THIS OFF SO WE DON'T HAVE TO.
	(my $url2fetch = $url);
	#DEPRECIATED (STATION-IDS NOW INCLUDE STUFF BEFORE THE DASH: ($self->{'id'} = $url) =~ s#^.*\-([a-z]\d+)\/?$#$1#;
	if ($url2fetch =~ m#^https?\:#) {
$url2fetch =~ s/www\.youtube\.com/youtube\.be/;  #WWW.YOUTUBE.COM SEEMS TO NOW BE BLOCKING youtube-dl?! :/
		$self->{'id'} = $1  if ($url2fetch =~ m#\/([^\/]+)\/?$#);
		$self->{'id'} =~ s/^watch\?v\=//;
		$self->{'id'} =~ s/[\?\&].*$//;
	} else {
		$self->{'id'} = $url;
		$url2fetch = 'https://youtube.be/watch?v=' . $url;
	}
	print STDERR "-1 FETCHING URL=$url= VIA youtube-dl: ID=".$self->{'id'}."=\n"  if ($DEBUG);
	$self->{'iconurl'} = '';
	$self->{'title'} = '';
	$self->{'artist'} = '';
	$self->{'albumartist'} = '';

	#FIRST:  GET STREAMS, THUMBNAIL, ETC. FROM youtube-dl:

	my $ytdlArgs = '--get-url --get-thumbnail --get-title --get-description -f "'
			. ((defined $uops{'format'}) ? $uops{'format'} : 'mp4')
			. '" ' . ((defined $uops{'youtube-dl-args'}) ? $uops{'youtube-dl-args'} : '');
	my $try = 0;
	my ($more, @ytdldata);
RETRYIT:
	$_ = '';
	if (defined($uops{'userid'}) && defined($uops{'userpw'})) {  #USER HAS A LOGIN CONFIGURED:
		my $uid = $uops{'userid'};
		my $upw = $uops{'userpw'};
		$_ = `youtube-dl --username "$uid" --password "$upw" $ytdlArgs "$url"`;
	} else {
		$_ = `youtube-dl $ytdlArgs "$url"`;
	}
	print STDERR "--TRY($try of 1): youtube-dl returned=$_= ARGS=$ytdlArgs=\n"  if ($DEBUG);
	@ytdldata = split /\r?\n/s;
	unless ($try || scalar(@ytdldata) > 0) {  #IF NOTHING FOUND, RETRY WITHOUT THE SPECIFIC FILE-FORMAT:
		print STDERR "..1:No MP4 streams found, try again for any (audio, etc.)...\n";
		$try++;
		goto RETRYIT  if ($ytdlArgs =~ s/\-f\s+\"([^\"]+)\"//);
	}
	return undef unless (scalar(@ytdldata) > 0);

	unless ($ytdldata[0] =~ m#^https?\:\/\/#) {
		$_ = shift(@ytdldata);
		$self->{'title'} ||= $_;
	}
	$self->{'description'} = '';
	$more = 1;
	while (@ytdldata) {
		$_ = shift @ytdldata;
		$more = 0  unless (m#^https?\:\/\/#o);
		if ($more) {
			push @{$self->{'streams'}}, $_;
		} else {
			$self->{'description'} .= $_ . ' ';
		}
	}
	$self->{'cnt'} = scalar @{$self->{'streams'}};
	$self->{'iconurl'} = pop(@{$self->{'streams'}})  if ($self->{'cnt'} > 1);
	$self->{'cnt'} = scalar @{$self->{'streams'}};
	unless ($try || $self->{'cnt'} > 0) {  #IF NO STREAMS FOUND, RETRY WITHOUT THE SPECIFIC FILE-FORMAT:
		print STDERR "..2:No MP4 streams found, try again for any (audio, etc.)...\n";
		$try++;
		$ytdlArgs =~ s/\-f\s+\"([^\"]+)\"//;
		goto RETRYIT  if ($1);
	}

	#NOW MANUALLY SCAN PAGE TO TRY TO GET artist, description, year, ETC. DIRECTLY FROM PAGE (IF A YOUTUBE SITE):

	unless ($FAST || $url2fetch !~ /\b(?:youtube\.|youtu.be|ytimg\.)\b/) {
		print STDERR "-2 FETCHING SCREEN URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
		my $ua = LWP::UserAgent->new(@userAgentOps);		
		$ua->timeout($uops{'timeout'});
		$ua->cookie_jar({});
		$ua->env_proxy;
		my $html = '';
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
		$html =~ s/\\\"/\&quot\;/gs;
		if ($html =~ s#\]\}\,\"title\"\:\{\"runs\"\:\[\{\"text\"\:\"([^\"]+)\"\,\"navigationEndpoint\"\:([^\}]+)##s) {
			my $two = $2;
			$self->{'artist'} = $1;
			$self->{'albumartist'} = 'https://www.youtube.com' . $1  if ($two =~ m#\"url\"\:\"([^\"]+)#);
		}
		if ($html =~ s#\"videoDetails\"\:\{\"videoId\"\:\"([^\"]+)\"([^\}]+)##s) {
			my $two = $2;
			$self->{'id'} = $1;
			$self->{'title'} = $1  if ($two =~ m#\"title\"\:\"([^\"]+)#);
			$self->{'iconurl'} = $1  if ($two =~ m#\"thumbnails\"\:\[\{\"url\"\:\"([^\"]+)#);
			$self->{'iconurl'} =~ s/\?.*$//;
		}
		if ($html =~ m#\"dateText\"\:\{([^\}]+)\}#s) {
			my $one = $1;
			$self->{'year'} = $1  if ($one =~ /(\d\d\d\d)/);
		}
	}
	$self->{'total'} = $self->{'cnt'};
	$self->{'imageurl'} = $self->{'iconurl'};
	$self->{'Url'} = ($self->{'cnt'} > 0) ? $self->{'streams'}->[0] : '';
	print STDERR "-count=".$self->{'cnt'}."= iconurl=".$self->{'iconurl'}."=\n"  if ($DEBUG);
	print STDERR "--SUCCESS: stream url=".$self->{'Url'}."=\n"  if ($DEBUG);
	if ($self->{'description'} =~ /\w/) {
		$self->{'description'} =~ s/\s+$//;
	} else {
		$self->{'description'} = $self->{'title'};
	}
	foreach my $i (qw(title artist albumartist description)) {
		$self->{$i} = HTML::Entities::decode_entities($self->{$i});
		$self->{$i} = uri_unescape($self->{$i});
		$self->{$i} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egso;
	}
	print STDERR "-2: title=".$self->{'title'}."= id=".$self->{'id'}."= artist=".$self->{'artist'}."= year(Published)=".$self->{'year'}."=\n"  if ($DEBUG);
#print STDERR "\n--ID=".$self->{'id'}."=\n--TITLE=".$self->{'title'}."=\n--CNT=".$self->{'cnt'}."=\n--ICON=".$self->{'iconurl'}."=\n--1ST=".$self->{'Url'}."=\n"  if ($DEBUG);

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub get
{
	my $self = shift;

	return wantarray ? @{$self->{'streams'}} : $self->{'Url'};
}

sub getURL   #LIKE GET, BUT ONLY RETURN THE SINGLE ONE W/BEST BANDWIDTH AND RELIABILITY:
{
	my $self = shift;
	my $arglist = (defined $_[0]) ? join('|',@_) : '';
	my $idx = ($arglist =~ /\b\-?random\b/) ? int rand scalar @{$self->{'streams'}} : 0;
	if (($arglist =~ /\b\-?nopls\b/ && ${$self->{'streams'}}[$idx] =~ /\.(pls)$/i)
			|| ($arglist =~ /\b\-?noplaylists\b/ && ${$self->{'streams'}}[$idx] =~ /\.(pls|m3u8?)$/i)) {
		my $plType = $1;
		my $firstStream = ${$self->{'streams'}}[$idx];
		print STDERR "-YT:getURL($idx): NOPLAYLISTS and (".${$self->{'streams'}}[$idx].")\n"  if ($DEBUG);
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
		my @plentries = ();
		my $firstTitle = '';
		my $plidx = ($arglist =~ /\b\-?random\b/) ? 1 : 0;
		if ($plType =~ /pls/i) {  #PLS:
			foreach my $line (@lines) {
				if ($line =~ m#^\s*File\d+\=(.+)$#o) {
					push (@plentries, $1);
				} elsif ($line =~ m#^\s*Title\d+\=(.+)$#o) {
					$firstTitle ||= $1;
				}
			}
			$self->{'title'} ||= $firstTitle;
			$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
			$self->{'title'} = uri_unescape($self->{'title'});
			print STDERR "-getURL(PLS): title=$firstTitle= pl_idx=$plidx=\n"  if ($DEBUG);
		} elsif ($arglist =~ /\b\-?noplaylists\b/) {  #m3u*:
			(my $urlpath = ${$self->{'streams'}}[$idx]) =~ s#[^\/]+$##;
			foreach my $line (@lines) {
				if ($line =~ m#^\s*([^\#].+)$#o) {
					my $urlpart = $1;
					$urlpart =~ s#^\s+##o;
					$urlpart =~ s#^\/##o;
					push (@plentries, ($urlpart =~ m#https?\:#) ? $urlpart : ($urlpath . '/' . $urlpart));
					last  unless ($plidx);
				}
			}
			print STDERR "-getURL(m3u?): pl_idx=$plidx=\n"  if ($DEBUG);
		}
		if ($plidx && $#plentries >= 0) {
			$plidx = int rand scalar @plentries;
		} else {
			$plidx = 0;
		}
		$firstStream = (defined($plentries[$plidx]) && $plentries[$plidx]) ? $plentries[$plidx]
				: ${$self->{'streams'}}[$idx];

		return $firstStream;
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
	return 'Youtube';  #STATION TYPE (FOR PARENT StreamFinder MODULE).
}

sub getID
{
	my $self = shift;
	return $self->{'id'};  #VIDEO'S YOUTUBE-ID.
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
	return $self->getIconData();
}

1
