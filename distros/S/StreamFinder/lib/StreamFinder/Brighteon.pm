=head1 NAME

StreamFinder::Brighteon - Fetch actual raw streamable URLs from Brighteon.com.

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

	use StreamFinder::Brighteon;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $video = new StreamFinder::Brighteon($ARGV[0]);

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

StreamFinder::Brighteon accepts a valid full Brighteon video ID or URL on 
brighteon.com and returns the actual stream URL, title, and cover art icon 
for that video.  The purpose is that one needs this URL in order to have 
the option to stream the video in one's own choice of media player 
software rather than using their web browser and accepting any / all flash, 
ads, javascript, cookies, trackers, web-bugs, and other crapware that can 
come with that method of play.  The author uses his own custom all-purpose 
media player called "fauxdacious" (his custom hacked version of the 
open-source "audacious" audio player).  "fauxdacious" incorporates this 
module to decode and play brighteon.com videos.  This is a submodule of the 
general StreamFinder module.

Depends:  

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent> 

The separate application program:  youtube-dl, or a compatable program 
such as yt-dlp (only if wishing to use the I<-youtube> option).

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-youtube> => yes|no|first|last|only ] 
[, I<-keep> => "type1,type2?..." | [type1,type2?...] ] 
[, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ]])

Accepts a brighteon.com video ID or URL and creates and returns a new video 
object, or I<undef> if the URL is not a valid Brighteon video or no streams 
are found.  The URL can be the full URL, ie. 
https://www.brighteon.com/B<video-id>, 
or just I<video-id>.

NOTE:  Brighteon channel pages are no longer accepted as Brighteon.com has 
recently made them non-scrapable (without Javascript).

The optional I<-keep> argument can be either a comma-separated string or an 
array reference ([...]) of stream types to keep (include) and returned in 
order specified (type1, type2...).  Each "type" can be one of:  extension 
(ie. m4a, mp4, etc.), "playlist", "stream", or ("any" or "all").

DEFAULT I<-keep> list is:  'm4a,mpd,stream,all', meaning that all m4a streams 
followed by all "mpd" streams, followed by non-playlists, followed by all 
remaining (playlists: (pls) streams.  More than one value can be specified to 
control order of search.

NOTE:  I<-keep> is ignored if I<-youtube> is set to "I<only>".

The optional I<-youtube> argument can be set to "I<yes>" or "I<last>" - also 
include streams youtube-dl finds (last); "I<no>" - only include streams 
embedded in the video's brighteon.com page, unless none are found; 
"I<only>" - only include streams youtube-dl finds; or "I<first>" - include 
streams youtube-dl finds first.  Default is B<"yes">.  This is needed because 
currently the streams on the page: (mpd plays best but is unseekable, and the 
m3u8 (HLS) stream doesn't seem to work well).  youtube-dl also returns a 
"chunky" m3u8 (HLS) stream that is seekable and seems to work ok.

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  
If 1 then only secure ("https://") streams will be returned.

DEFAULT I<-secure> is 0 (false) - return all streams (http and https).

Additional options:

Certain youtube-dl (L<StreamFinder::Youtube>) configuration options, 
namely I<format>, I<formatonly>, I<youtube-dl-args>, and I<youtube-dl-add-args> 
can be overridden here by specifying I<youtube-format>, I<youtube-formatonly>, 
I<youtube-dl-args>, and I<youtube-dl-add-args> arguments respectively.  It is 
however, recommended to specify these in the Brighteon-specific 
configuration file (see B<CONFIGURATION FILES> below.  NOTE:  These are only 
applicable when using the option: I<-youtube> => I<yes|only|top>, etc.

I<-log> => "I<logfile>"

Specify path to a log file.  If a valid and writable file is specified, A line 
will be appended to this file every time one or more streams is successfully 
fetched for a url.

DEFAULT I<-none-> (no logging).

I<-logfmt> specifies a format string for lines written to the log file.

DEFAULT "I<[time] [url] - [site]: [title] ([total])>".  

The valid field I<[variables]> are:  [stream]: The url of the first/best 
stream found.  [site]:  The site name (Brighteon).  [url]:  The url searched 
for streams.  [time]: Perl timestamp when the line was logged.  [title], 
[artist], [album], [description], [year], [genre], [total], [albumartist]:  
The corresponding field data returned (or "I<-na->", if no value).

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

Returns the video's Brighteon ID (alphanumeric).

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

Returns the URL for the video's "cover art" banner image, which for 
Brighteon videos is always the icon image, as Brighteon does not 
support a separate banner image at this time.

=item $video->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual video's banner image (binary data).

=item $video->B<getType>()

Returns the video's type ("Brighteon").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/Brighteon/config

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

Among options valid for Brighteon streams is the I<-keep> and 
I<-youtube> options described in the B<new()> function.  Also, 
various youtube-dl (L<StreamFinder::Youtube>) configuration options, 
namely I<format>, I<formatonly>, I<youtube-dl-args>, and I<youtube-dl-add-args> 
can be overridden here by specifying I<youtube-format>, I<youtube-formatonly>, 
I<youtube-dl-args>, and I<youtube-dl-add-args> arguments respectively.  
NOTE:  These are only applicable when using the option:  
I<-youtube> => I<yes|only|top>, etc.

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

brighteon

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

youtube-dl (or yt-dlp, or other compatable program)

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-brighteon at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Brighteon>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Brighteon

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Brighteon>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Brighteon>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Brighteon>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Brighteon/>

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

package StreamFinder::Brighteon;

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

	my $self = $class->SUPER::new('Brighteon', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});

	my @okStreams;
	$self->{'youtube'} = 'no'  unless (defined $self->{'youtube'});
	while (@_) {
		if ($_[0] =~ /^\-?youtube$/o) {
			shift;
			$self->{'youtube'} = (defined $_[0]) ? shift : 'yes';
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
	if (!defined($okStreams[0]) && defined($self->{'keep'})) {
		@okStreams = (ref($self->{'keep'}) =~ /ARRAY/) ? @{$self->{'keep'}} : split(/\,\s*/, $self->{'keep'});
	}
	@okStreams = (qw(m4a mpd mp3 stream all))  unless (defined $okStreams[0]);  # one of:  {m4a, <ext>, direct, stream, any, all}

	print STDERR "-0(Brighteon): URL=$url=\n"  if ($DEBUG);
	$url =~ s/\?autoplay\=true$//;  #STRIP THIS OFF SO WE DON'T HAVE TO.
	(my $url2fetch = $url);
	#DEPRECIATED (VIDEO-IDS NOW INCLUDE STUFF BEFORE THE DASH: ($self->{'id'} = $url) =~ s#^.*\-([a-z]\d+)\/?$#$1#;
	if ($url2fetch =~ m#^https?\:#) {
		$url2fetch =~ s#\/embed\/#\/#;   #CONVERT "embed" URLS TO STANDARD ONES.
		$self->{'id'} = $1  if ($url2fetch =~ m#\/([^\/]+)\/?$#);
		$self->{'id'} =~ s/[\?\&].*$//;
	} else {
		$self->{'id'} = $url;
		$url2fetch = ($url =~ /\-\w\w\w\w\-/) ? 'https://www.brighteon.com/'
				: 'https://www.brighteon.com/channels/';
		$url2fetch .= $url;
	}
	print STDERR "-1 FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	$self->{'genre'} = 'Video';

	my $html = '';
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
	return undef  unless ($html);

	if ($url2fetch =~ m#\/channels\/#) {  #WE'RE A CHANNEL PAGE, GRAB 1ST VIDEO! (DEPRECIATED!):
		print "--WE'RE A BRIGHTEON CHANNEL URL!\n"  if ($DEBUG);
		if ($html =~ m#\bhref\=\"([^\"]+)\"\>\s*\<img\s+src\=\"https\:\/\/photos\.brighteon\.com\/thumbnail#) {
			($url2fetch = $1) =~ s#^\/#https://www.brighteon.com/#;
			$self->{'id'} = $1  if ($url2fetch =~ m#\/([^\/]+)\/?$#);
			$self->{'id'} =~ s/[\?\&].*$//;
			print "---FOUND 1ST EPISODE! FETCHING=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
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
			return undef  unless ($html);
		} else {
			print STDERR "\ne:Brighteon podcast/channel pages no longer supported (unscrapable)!\n";
			return undef;
		}
	}

	$html =~ s/\\\"/\&quot\;/gs;
	if ($html =~ s#\<a\s+href\=\"([^\"]*)\"\s+title\=\"[^\"]*\"\s+class\=\"author\_\_name\"\>([^\<]+)\<##s) {
		my $one = $1;
		($self->{'artist'} = $2) =~ s/\s+$//;
		$self->{'albumartist'} = 'https://www.brighteon.com' . $one  if ($one);
	} elsif ($html =~ m#\"shortUrl\"\:\"([^\"]+)\"\,\"name\"\:\"([^\"]+)\"#) {
		$self->{'artist'} = $2;
		$self->{'albumartist'} = "http://www.brighteon.com/channels/$1"  if ($1);
	}

	#FETCH ALL STREAMS:

	unless ($self->{'youtube'} =~ /only/i) {  #FETCH STREAMS HERE UNLESS USER WANT'S youtube-dl STREAMS ONLY:
		my $streams = '';
		if ($html =~ m#\"source\"\:\[([^\]]+)#s) {
			my $sourcedata = $1;
			my ($one, $ext);
			while ($sourcedata =~ s#\{\"src\"\:\"([^\"]+)\"##so) {
				$one = $1;
				$ext = ($one =~ /\.(\w+)$/) ? $1 : '';
				$streams .= "$ext=$one|";
			}
		}
		if ($html =~ m#\"audioSource\"\:\[([^\]]+)#s) {
			my $sourcedata = $1;
			my ($one, $ext);
			while ($sourcedata =~ s#\{\"src\"\:\"([^\"]+)\"##so) {
				$one = $1;
				$ext = ($one =~ /\.(\w+)$/) ? $1 : '';
				$streams .= "$ext=$one|";
			}
		}
		if ($streams) {
			my $stindex = 0;
			my $savestreams = $streams;
			my %havestreams = ();

			if (defined $self->{'formats_by_channel'} && $self->{'albumartist'}) {
				my %formats_by_url = %{$self->{'formats_by_channel'}};
				foreach my $i (keys %formats_by_url) {
					if ($self->{'albumartist'} =~ m#$i#i) {
						@okStreams = split(/\,\s*/, $formats_by_url{$i});
					}
				}
			}
			print STDERR "--Brighteon: ok Stream types=".join('|',@okStreams)."= channel=".$self->{'albumartist'}."=\n"  if ($DEBUG);
			foreach my $streamtype (@okStreams) {
				$streams = $savestreams;
				if ($streamtype =~ /^stream$/i) {
					while ($streams =~ /^([^\=]*)\=([^\|]+)/o) {
						my $ext = $1;
						my $one = $2;
						$one = 'https://video.brighteon.com/file/BTBucket-Prod/' . $one
								unless ($one =~ m#^https?\:\/\/#);
						if ($ext !~ /^pls$/i && !defined($havestreams{"$ext|$one"})) {
							unless ($self->{'secure'} && $one !~ /^https/o) {
								$self->{'streams'}->[$stindex++] = $one;
								$havestreams{"$ext|$one"}++;
							}
						}
						$streams =~ s/^[^\|]*\|//o;
					}
				} elsif ($streamtype =~ /^playlist$/i) {
					while ($streams =~ /^([^\=]*)\=([^\|]+)/o) {
						my $ext = $1;
						my $one = $2;
						if ($ext =~ /^pls$/i && !defined($havestreams{"$ext|$one"})) {
							unless ($self->{'secure'} && $one !~ /^https/o) {
								$self->{'streams'}->[$stindex++] = $one;
								$havestreams{"$ext|$one"}++;
							}
						}
						$streams =~ s/^[^\|]*\|//o;
					}
				} elsif ($streamtype =~ /^a(?:ny|ll)$/i) {
					while ($streams =~ /^([^\=]*)\=([^\|]+)/o) {
						my $ext = $1;
						my $one = $2;
						unless (defined($havestreams{"$ext|$one"})) {
							unless ($self->{'secure'} && $one !~ /^https/o) {
								$self->{'streams'}->[$stindex++] = $one;
								$havestreams{"$ext|$one"}++;
							}
						}
						$streams =~ s/^[^\|]*\|//o;
					}
				} else {
					while ($streams =~ /^([^\=]*)\=([^\|]+)/o) {
						my $ext = $1;
						my $one = $2;
						if ($ext =~ /^${streamtype}$/i && !defined($havestreams{"$ext|$one"})) {
							unless ($self->{'secure'} && $one !~ /^https/o) {
								$self->{'streams'}->[$stindex++] = $one;
								$havestreams{"$ext|$one"}++;
							}
						}
						$streams =~ s/^[^\|]*\|//o;
					}
				}
			}
			$self->{'cnt'} = scalar @{$self->{'streams'}};
		} elsif ($html =~ m#\"audio\"\:\"([^\"]+)#s) {  #TRY FALLBACK AUDIO STREAM IF NO STREAMS FOUND:
			my $one = $1;
			$one = 'https://video.brighteon.com/file/BTBucket-Prod/' . $one
					unless ($one =~ m#^https?\:\/\/#);
			unless ($self->{'secure'} && $one !~ /^https/o) {
				$self->{'streams'}->[0] = $one;
				$self->{'cnt'} = scalar @{$self->{'streams'}};
			}
		}
	}

	#FETCH OTHER METADATA FROM PAGE:

	$self->{'title'} = $1  if ($html =~ m#\"name\"\:\"([^\"]+)#s);
	$self->{'description'} = $1  if ($html =~ m#\"description\"\:\"([^\"]+)#s);
	$self->{'iconurl'} = $1  if ($html =~ m#\"thumbnail\"\:\"([^\"]+)#s);
	$self->{'imageurl'} = ($html =~ m#\"poster\"\:\"(https?\:\/\/[^\"]+)#s)
			? $1 : $self->{'iconurl'};
	$self->{'articonurl'} = $1  if ($html =~ m#\"thumbnailUrl\"\:\"([^\"]+)#s);
	$self->{'articonurl'} ||= $1  if ($html =~ m#\"channelAvatar\"\:\"([^\"]+)#s);
	if ($html =~ m#\"createdAt\"\:\"([^\"]+)#s) {
		$self->{'created'} = $1;
		$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
	}

	#IF WE DIDN'T FIND ANY STREAMS IN THE PAGE, TRY youtube-dl (DEPRECIATED!):

	if ($self->{'cnt'} <= 0 || $self->{'youtube'} =~ /(?:yes|top|first|last)/i) { #(ANYTHING BUT "no"):
		my $haveYoutube = 0;
		eval { require 'StreamFinder/Youtube.pm'; $haveYoutube = 1; };
		print STDERR "\n-2 NO STREAMS FOUND IN PAGE (haveYoutube=$haveYoutube)\n"  if ($DEBUG && $self->{'cnt'} <= 0);
		if ($haveYoutube) {
			print STDERR "\n-2 TRYING youtube-dl($self->{'youtube'})...\n"  if ($DEBUG && $self->{'youtube'} =~ /(?:yes|top|first)/i);
			my %globalArgs = (
					'-noiframes' => 1, '-fast' => 1, '-debug' => $DEBUG
			);
			foreach my $arg (qw(secure log logfmt youtube-format youtube-format-fallback
					youtube-formatonly youtube-dl-args youtube-dl-add-args)) {
				(my $arg0 = $arg) =~ s/^youtube\-(?!dl)//o;
				$globalArgs{$arg0} = $self->{$arg}  if (defined $self->{$arg});
			}
			my $yt = new StreamFinder::Youtube($url2fetch, %globalArgs);
			if ($yt && $yt->count() > 0) {
				my @ytStreams = $yt->get();
				if ($self->{'youtube'} =~ /(?:top|first)/i) {  #PUT youtube-dl STREAMS ON TOP:
					unshift @{$self->{'streams'}}, @ytStreams;
				} else {
					push @{$self->{'streams'}}, @ytStreams;
				}
				foreach my $field (qw(title description)) {
					$self->{$field} ||= $yt->{$field}  if (defined($yt->{$field}) && $yt->{$field});
				}
				$self->{'cnt'} = scalar @{$self->{'streams'}};
				print STDERR "i:Found stream(s) (".join('|',@ytStreams).") via youtube-dl.\n"  if ($DEBUG);
			}
		}
	}
	if ($self->{'description'} =~ /\w/) {
		$self->{'description'} =~ s/\s+$//;
	} else {
		$self->{'description'} = $self->{'title'};
	}
	foreach my $i (qw(title artist description)) {
		$self->{$i} = HTML::Entities::decode_entities($self->{$i});
		$self->{$i} = uri_unescape($self->{$i});
		$self->{$i} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egso;
	}
	$self->{'total'} = $self->{'cnt'};
	$self->{'Url'} = ($self->{'cnt'} > 0) ? $self->{'streams'}->[0] : '';
	if ($DEBUG) {
		foreach my $i (sort keys %{$self}) {
			print STDERR "--KEY=$i= VAL=".$self->{$i}."=\n";
		}
		print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"
				if ($self->{'cnt'} > 0);
	}
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
