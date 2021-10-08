=head1 NAME

StreamFinder::Vimeo - Fetch actual raw streamable URLs from Vimeo.com.

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

	use StreamFinder::Vimeo;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $video = new StreamFinder::Vimeo($ARGV[0]);

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

	print "Artist=$artist\n"  if ($artist);
	
	my $albumartist = $video->{'albumartist'};

	print "Album Artist=$albumartist\n"  if ($albumartist);
	
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

StreamFinder::Vimeo accepts a valid full Vimeo video ID or URL on 
vimeo.com and returns the actual stream URL, title, and cover art icon 
for that video.  The purpose is that one needs this URL in order to have 
he option to stream the video in one's own choice of media player 
software rather than using their web browser and accepting any / all 
flash, ads, javascript, cookies, trackers, web-bugs, and other crapware 
that can come with that method of play.  The author uses his own 
custom all-purpose media player called "fauxdacious" (his custom hacked 
version of the open-source "audacious" audio player).  "fauxdacious" 
incorporates this module to decode and play vimeo.com videos.  This is a 
submodule of the general StreamFinder module.

Depends:  

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>, 
and the separate application program:  youtube-dl.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-debug> [ => 0|1|2 ]] 
[, "-quality" => I<quality>] [, I<-secure> [ => 0|1 ]])

Accepts a vimeo.com ID or URL and creates and returns a new video object, 
or I<undef> if the URL is not a valid Vimeo video or no streams are 
found.  The URL can be the full URL, 
ie. https://player.vimeo.com/video/B<video-id>, or just I<video-id>.

The optional I<-quality> argument, which can be set to a "p number" optionally 
preceeded by a relational operator ("<", ">", "=") - default: "<".  
This limits the video quality.. For example:  "720" would mean select 
a stream "<= 720p", ">720" would mean ">= 720p", and "=1080" would 
mean "only "1080p".  See also the "vimeo_quality" config. file option 
that does the same thing.  Default is just use the best quality found.

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
[site]:  The site name (Vimeo).  [url]:  The url searched for streams.  
[time]: Perl timestamp when the line was logged.  [title], [artist], [album], 
[description], [year], [genre], [total], [albumartist]:  The corresponding field data 
returned (or "I<-na->", if no value).

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

Returns the video's Vimeo ID (numeric).

=item $video->B<getTitle>(['desc'])

Returns the video's title, or (long description).  

=item $video->B<getIconURL>(['artist'])

Returns the URL for the video's "cover art" icon image, if any.
If B<'artist'> is specified, the channel artist's icon url is returned, 
if any.

=item $video->B<getIconData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.
If B<'artist'> is specified, the channel artist's icon data is returned, 
if any.

=item $video->B<getImageURL>()

Returns the URL for the video's "cover art" (usually larger) 
banner image.

=item $video->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual video's banner image (binary data).

=item $video->B<getType>()

Returns the video's type ("Vimeo").

=back

=head1 CONFIGURATION FILES

=over 4

=item ~/.config/StreamFinder/Vimeo/config

Optional text file for specifying various configuration options 
for a specific site (submodule).  Each option is specified on a 
separate line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used only by the specific 
(submodule) specified.  Valid options include 
I<-debug> => [0|1|2], and most of the L<LWP::UserAgent> options.  
Blank lines and lines starting with a "#" sign are ignored.

Options specified here override any specified in I<~/.config/StreamFinder/config>.

Among options valid for Vimeo videos are the I<-vimeo_quality> 
option, which can be set to a "p" number optionally preceeded by 
a relational operator ("<", ">", "=") - default: "<".  This limits 
the video quality.. For example:  "720" would mean select a stream 
"<= 720p", ">720" would mean ">= 720p", and "=1080" would mean "only 
"1080p".  This can be overridden with the I<-quality> argument to 
the new() function.

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

vimeo

=head1 DEPENDENCIES

youtube-dl

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>, youtube-dl

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-vimeo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Vimeo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Vimeo

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Vimeo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Vimeo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Vimeo>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Vimeo/>

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

package StreamFinder::Vimeo;

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
#	return undef  if ($url =~ /\bplayer\.vimeo\b/);

	my $self = $class->SUPER::new('Vimeo', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});

	while (@_) {
		if ($_[0] =~ /^\-?quality$/o) {
			shift;
			$self->{'vimeo_quality'} = (defined $_[0]) ? shift : 0;
		} else {
			shift;
		}
	}

	print STDERR "-0(Vimeo): URL=$url=\n"  if ($DEBUG);
	if ($url =~ m#^https?\:#) {
		$self->{'id'} = $1  if ($url =~ m#\/([^\/]+)\/?$#);
		$self->{'id'} =~ s/[\?\&].*$//;
	} else {
		$self->{'id'} = $url;
	}
	my $player_url = 'https://player.vimeo.com/video/'. $self->{'id'};
	print STDERR "-1 FETCHING URL=$player_url= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	$self->{'genre'} = 'Video';
	$self->{'albumartist'} = $player_url;

	#VIMEO VIDEOS BEST SCANNED MANUALLY!:

	my $html = '';
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $response = $ua->get($player_url);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
		my $no_wget = system('wget','-V');
		unless ($no_wget) {
			print STDERR "\n..trying wget...\n"  if ($DEBUG);
			$html = `wget -t 2 -T 20 -O- -o /dev/null \"$player_url\" 2>/dev/null `;
		}
	}
	$html =~ s/\\\"/\&quot\;/gs;
	$self->{'title'} = ($html =~ m#\<title\>([^\<]+)#) ? $1 : '';
	$self->{'imageurl'} = ($html =~ m#background\:\s+url\s*\(([^\)]+)#) ? $1 : '';
	if ($html =~ m#\"progressive\"\:(\[\{[^\]]+\])#s) {
		(my $s = $1) =~ s/\"\:/\" \=\> /gs;
		my $v;
		eval "\$v = $s";
		my %streams;
		my $cnt = 0;
		my $quality = defined ($self->{'vimeo_quality'}) ? $self->{'vimeo_quality'} : 0;
		my $direction = ($quality =~ s/^([\<\=\>])//) ? $1 : '<';
		print STDERR "--USER-REQ. QUALITY=$quality= DIR=$direction=\n"  if ($DEBUG);
		foreach my $i (@{$v}) {
			$i->{'quality'} =~ s/\D+//o;
			$streams{$i->{'quality'}} = $i->{'url'}  if (!$quality || ($i->{'quality'} == $quality)
					|| ($direction eq '<' && $i->{'quality'} <= $quality)
					|| ($direction eq '>' && $i->{'quality'} >= $quality));
			++$cnt;
		}
		if ($cnt) {
			foreach my $i (sort { $a <=> $b } keys %streams) {
				unless ($self->{'secure'} && $streams{$i} !~ /^https/o) {
					print STDERR "**** VIMEO STREAM FOUND: QUALITY($i)=$streams{$i}=\n"  if ($DEBUG);
					unshift @{$self->{'streams'}}, $streams{$i};
					$self->{'cnt'}++;
				}
			}
			if ($cnt) {
				$self->{'artist'} = $1  if ($html =~ s#\"owner\"\:\{.*?\"name\"\:\"([^\"]+)\"#STREAMFINDERMARK#s);
				$self->{'articonurl'} = $1  if ($html =~ m#STREAMFINDERMARK.*?\"img\"\:\"([^\"]+)\"#s);
				print "----ALT ART (CHANNEL) ICON=".$self->{'articonurl'}."=\n"  if ($DEBUG);
				$self->{'albumartist'} = $1  if ($html =~ s#STREAMFINDERMARK.*?\"url\"\:\"([^\"]+)\"##s);
			}
		}
	}

	#IF WE DIDN'T FIND ANY STREAMS IN THE PAGE, TRY youtube-dl:
	unless ($self->{'cnt'} > 0) {
		$url =~ s/\?autoplay\=true$//;  #STRIP THIS OFF SO WE DON'T HAVE TO.
		my $url2fetch = $url;
		#DEPRECIATED (VIDEO-IDS NOW INCLUDE STUFF BEFORE THE DASH: ($self->{'id'} = $url) =~ s#^.*\-([a-z]\d+)\/?$#$1#;
		$url2fetch = 'https://www.vimeo.com/' . $url  unless ($url2fetch =~ m#^https?\:#);
		print STDERR "\n-2 NO STREAMS FOUND IN PLAYER PAGE, TRYING youtube-dl...\n"  if ($DEBUG);
		my $ytdlArgs = '--get-url --get-thumbnail --get-title --get-description -f "'
				. ((defined $self->{'format'}) ? $self->{'format'} : 'mp4')
				. '" ' . ((defined $self->{'youtube-dl-args'}) ? $self->{'youtube-dl-args'} : '');
		my $try = 0;
		my ($more, @ytdldata, @ytStreams);

RETRYIT:
		if (defined($self->{'userid'}) && defined($self->{'userpw'})) {  #USER HAS A LOGIN CONFIGURED:
			my $uid = $self->{'userid'};
			my $upw = $self->{'userpw'};
			$_ = `youtube-dl --username "$uid" --password "$upw" $ytdlArgs "$url2fetch"`;
		} else {
			$_ = `youtube-dl $ytdlArgs "$url2fetch"`;
		}
		print STDERR "--TRY($try of 1): youtube-dl returned=$_= ARGS=$ytdlArgs=\n"  if ($DEBUG);
		@ytdldata = split /\r?\n/s;
		return undef unless (scalar(@ytdldata) > 0);

		#NOTE:  ytdldata is ORDERED:  TITLE?, STREAM-URLS, THEN THE ICON URL, THEN DESCRIPTION!:
		unless ($ytdldata[0] =~ m#^https?\:\/\/#) {
			$_ = shift(@ytdldata);
			$self->{'title'} ||= $_;
		}
		$more = 1;
		@ytStreams = ();
		while (@ytdldata) {
			$_ = shift @ytdldata;
			$more = 0  unless (m#^https?\:\/\/#o);
			if ($more) {
				push @ytStreams, $_  unless ($self->{'secure'} && $_ !~ /^https/o);
			} else {
				$self->{'description'} .= $_ . ' ';
			}
		}
		$self->{'iconurl'} = pop(@ytStreams)  if ($#ytStreams > 0);
		push @{$self->{'streams'}}, @ytStreams;
		$self->{'cnt'} = scalar @{$self->{'streams'}};
		unless ($try || $self->{'cnt'} > 0) {  #IF NOTHING FOUND, RETRY WITHOUT THE SPECIFIC FILE-FORMAT:
			$try++;
			$ytdlArgs =~ s/\-f\s+\"([^\"]+)\"//;
			goto RETRYIT  if ($1);
		}
		$self->{'imageurl'} ||= $self->{'iconurl'};
		print STDERR "-count=".$self->{'cnt'}."= iconurl=".$self->{'iconurl'}."=\n"  if ($DEBUG);
		if ($self->{'description'} =~ /\w/) {
			$self->{'description'} =~ s/\s+$//;
			$self->{'description'} = HTML::Entities::decode_entities($self->{'description'});
			$self->{'description'} = uri_unescape($self->{'description'});
		}
	}
	$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
	$self->{'title'} = uri_unescape($self->{'title'});
	$self->{'description'} ||= $self->{'title'};
	$self->{'iconurl'} ||= $self->{'imageurl'}  if ($self->{'imageurl'});
	$self->{'iconurl'} ||= $self->{'articonurl'}  if ($self->{'articonurl'});
	$self->{'total'} = $self->{'cnt'};
	$self->{'Url'} = ($self->{'total'} > 0) ? $self->{'streams'}->[0] : '';
	print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"
			if ($DEBUG && $self->{'cnt'} > 0);
	print STDERR "\n--ID=".$self->{'id'}."=\n--TITLE=".$self->{'title'}."=\n--CNT=".$self->{'cnt'}."=\n--ICON=".$self->{'iconurl'}."=\n--1ST=".$self->{'Url'}."=\n--streams=".join('|',@{$self->{'streams'}})."=\n"  if ($DEBUG);
	$self->_log($url);

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub getImageData
{
	my $self = shift;
	return $self->getIconData();
}

1
