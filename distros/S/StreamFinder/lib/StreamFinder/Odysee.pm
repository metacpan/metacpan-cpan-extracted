=head1 NAME

StreamFinder::Odysee - Fetch actual raw streamable URLs from Odysee.com.

=head1 AUTHOR

This module is Copyright (C) 2017-2023 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::Odysee;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $video = new StreamFinder::Odysee($ARGV[0]);

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

StreamFinder::Odysee accepts a valid full Odysee video webpage URL on 
odysee.com and returns the actual stream URL, title, and cover art icon 
for that video.  The purpose is that one needs this URL in order to have 
the option to stream the video in one's own choice of media player 
software rather than using their web browser and accepting any / all flash, 
ads, javascript, cookies, trackers, web-bugs, and other crapware that can 
come with that method of play.  The author uses his own custom all-purpose 
media player called "fauxdacious" (his custom hacked version of the 
open-source "audacious" audio player).  "fauxdacious" incorporates this 
module to decode and play odysee.com videos.  This is a submodule of the 
general StreamFinder module.  NOTE:  This submodule requires a full 
odysee URL as there is no searchability by just the "ID"!

Depends:  

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>, 
and the separate application program:  youtube-dl, or a compatable program 
such as yt-dlp.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-youtube> => yes|no|first|last|only|ifneeded ] 
[, I<-secure> [ => 0|1 ]] [, I<-nohls> [ => 0|1 ]]
[, I<-debug> [ => 0|1|2 ]])

Accepts a full odysee.com video URL and creates and returns a new video object, 
or I<undef> if the URL is not a valid Odysee video or no streams are found.  
The URL must be the full URL, ie. https://odysee.com/@channel/video-id.
NOTE:  I<channel> and I<video-id> usually end with a colon followed by 
random digits.

The optional I<-youtube> argument can be set to "I<yes>" or "I<last>" - Odysee 
will also look in the bottom of the video's description for a youtube link and 
try to fetch Youtube streams (last - after Odysee streams); "I<no>" - only 
include streams found from the video's odysee.com page; "I<only>" - return 
results only if there's a youtube link found at the bottom of the description 
(use only Youtube streams); or "I<first>" - include the Youtube streams 
(if any) first.  Default is B<"no"> (ignore any youtube link in 
the description).  NOTE:  Unlike most other modules, youtube will NOT be 
checked if I<-youtube> is set to I<no> regardless of whether any Odysee streams 
were found.  If I<-youtube> is set to I<ifneeded>, then youtube-dl will only 
be called a second time, if no other streams found.

The optional (<-nohls> argument can be set to either 0 or 1 
(I<false> or I<true>).  If 1 (I<true>), then only non-HLS (.m3u8?) streams 
will be accepted from Odysee.

DEFAULT I<-nohls> is 0 (false) - return all streams youtube-dl finds in Odysee.

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  If 1 
then only secure ("https://") streams will be returned.

DEFAULT I<-secure> is 0 (false) - return all streams (http and https).

Additional options:

Certain youtube-dl (L<StreamFinder::Youtube>) configuration options, 
namely I<-format>, I<-formatonly>, I<-youtube-dl-args>, 
and I<-youtube-dl-add-args> can be overridden here by specifying 
I<-youtube-format>, I<-youtube-formatonly>, I<-youtube-dl-args>, 
and I<-youtube-dl-add-args> arguments respectively.  It is however, 
recommended to specify these in the Odysee-specific configuration file 
(see B<CONFIGURATION FILES> below.

I<-log> => "I<logfile>"

Specify path to a log file.  If a valid and writable file is specified, A line will be 
appended to this file every time one or more streams is successfully fetched for a url.

DEFAULT I<-none-> (no logging).

I<-logfmt> specifies a format string for lines written to the log file.

DEFAULT "I<[time] [url] - [site]: [title] ([total])>".  

The valid field I<[variables]> are:  [stream]: The url of the first/best stream found.  
[site]:  The site name (Odysee).  [url]:  The url searched for streams.  
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

Returns the video's Odysee ID (alphanumeric).

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

=item $video->B<getImageURL>(['artist'])

Returns the URL for the video's "cover art" banner image.
If B<'artist'> is specified, the channel artist's image url is returned, 
if any.

=item $video->B<getImageData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual video's banner image (binary data).
If B<'artist'> is specified, the channel artist's image data is returned, 
if any.

=item $video->B<getType>()

Returns the video's type ("Odysee").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/Odysee/config

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

Among options valid for Odysee streams are the various youtube-dl 
(L<StreamFinder::Youtube>) configuration options, 
namely I<format>, I<formatonly>, I<youtube-dl-args>, and I<youtube-dl-add-args> 
can be overridden here by specifying I<youtube-format>, I<youtube-formatonly>, 
I<youtube-dl-args>, and I<youtube-dl-add-args> arguments respectively.  

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

odysee

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

youtube-dl (or yt-dlp, or other compatable program)

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-odysee at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Odysee>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Odysee

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Odysee>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Odysee>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Odysee>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Odysee/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2023 Jim Turner.

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

package StreamFinder::Odysee;

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

	my $self = $class->SUPER::new('Odysee', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});
	$self->{'youtube'} = 'no'  unless (defined $self->{'youtube'});
	$self->{'nohls'} = 0  unless (defined $self->{'nohls'});
	while (@_) {
		if ($_[0] =~ /^\-?youtube$/o) {
			shift;
			$self->{'youtube'} = (defined $_[0]) ? shift : 'yes';
		} elsif ($_[0] =~ /^\-?nohls$/o) {
			shift;
			$self->{'nohls'} = (defined $_[0]) ? shift : 1;
		} else {
			shift;
		}
	}

	print STDERR "-0(Odysee): URL=$url=\n"  if ($DEBUG);
	(my $url2fetch = uri_unescape($url));
	if ($url2fetch =~ m#^https?\:#) {
		$self->{'id'} = $1  if ($url2fetch =~ m#\/([^\/]+)\/?$#);
		$self->{'id'} =~ s/[^a-z0-9-_].*$//i;
		$self->{'artist'} = $1  if ($url2fetch =~ m#\@([^\/]+)#);
		($self->{'albumartist'} = $url2fetch) =~ s/\@$self->{'artist'}.+$/\@$self->{'artist'}/;
		$self->{'artist'} =~ s/[^a-z0-9-_].*$//i;
	}
	return undef  unless ($self->{'id'});

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
	if ($html =~ m#\<script\s+type\=\"application\/ld\+json\"\>\s*\{([^\}]+)#s) {
		my $jsonstuff = $1;
		my $streams = '';
		$self->{'title'} = $1  if ($jsonstuff =~ m#\"name\"\:\s*\"([^\"]+)#s);
#x		$self->{'description'} = $1  if ($jsonstuff =~ m#\"description\"\:\s*\"([^\"]+)#s);
		$self->{'iconurl'} = $1  if ($jsonstuff =~ m#\"thumbnailUrl\"\:\s*\"([^\"]+)#s);
		($self->{'imageurl'} = $self->{'iconurl'}) =~ s#^.+?(https?\:\/.+)$#$1#i
				if ($self->{'iconurl'});
		$self->{'year'} = $1  if ($jsonstuff =~ m#\"uploadDate\"\:\s*\"(\d\d\d\d)#s);
		my $haveYoutube = 0;
		eval { require 'StreamFinder/Youtube.pm'; $haveYoutube = 1; };
		print STDERR "\n-2 NO STREAMS FOUND IN PAGE (haveYoutube=$haveYoutube)\n"  if ($DEBUG && $self->{'cnt'} <= 0);
		if ($haveYoutube) {
			print STDERR "\n-2 TRYING youtube-dl...\n"  if ($DEBUG);
			my %globalArgs = (
					'-noiframes' => 1, '-fast' => 1, '-debug' => $DEBUG
			);
			foreach my $arg (qw(secure log logfmt youtube-format youtube-formatonly
					youtube-dl-args youtube-dl-add-args)) {
				(my $arg0 = $arg) =~ s/^youtube\-(?!dl)//o;
				$globalArgs{$arg0} = $self->{$arg}  if (defined $self->{$arg});
			}
			my @nonYtStreams = ();
			my $nonYtCnt = 0;
			my $yt = new StreamFinder::Youtube($url2fetch, %globalArgs);
			if ($yt) {
				if ($yt->count() > 0) {
					my @ytStreams = $yt->get();
					foreach my $s (@ytStreams) {
						push (@nonYtStreams, $s)  unless ($self->{'nohls'} && $s =~ /\.m3u8?/o);
					}
					$nonYtCnt = scalar (@nonYtStreams);
				}
				print STDERR "--PREFER-YT=".$self->{'youtube'}."= iconURL=".$yt->{'iconurl'}."=\n"  if ($DEBUG);
				if ($self->{'youtube'} =~ /(?:yes|top|first|last|only|ifneeded)/i && $yt->{'iconurl'} =~ /\b(?:youtube\.|youtu.be|ytimg\.)\b/) {
					#ODYSEE VIDEOS USUALLY HAVE A YOUTUBE URL AS LAST LINE IN DESCRIPTION, WHICH ENDS
					#UP IN THE iconurl ARGUMENT AND USER WOULD PREFER YOUTUBE, SO WE'LL TRY THAT!:
					print STDERR "---user prefers Youtube (".$yt->{'iconurl'}.")!...\n"  if ($DEBUG);
					#IF youtube-dl FOUND A NON-YOUTUBE STREAM & USER SAYS "ifneeded", THEN SKIP 2ND youtube-dl SEARCH!:
					goto NOTNEEDED  if ($nonYtCnt > 0 && $self->{'youtube'} =~ /ifneeded/);

					my %globalArgs = (
							'-noiframes' => 1, '-debug' => $DEBUG
					);
					foreach my $arg (qw(secure log logfmt youtube-format youtube-formatonly
							youtube-dl-args youtube-dl-add-args)) {
						(my $arg0 = $arg) =~ s/^youtube\-(?!dl)//o;
						$globalArgs{$arg0} = $self->{$arg}  if (defined $self->{$arg});
					}
					my $yt0 = new StreamFinder::Youtube($yt->{'iconurl'}, %globalArgs);
					if (defined($yt0) && $yt0->count() > 0) {
						return $yt0  if ($self->{'youtube'} =~ /only/i);

						my @ytStreams = $yt0->get();
						push @{$self->{'streams'}}, @ytStreams;
						if ($self->{'youtube'} =~ /(?:top|first)/i) {
							foreach my $field (qw(title description artist albumartist year iconurl articonurl)) {
								$self->{$field} ||= $yt0->{$field}  if (defined($yt0->{$field}) && $yt0->{$field});
							}
						}
						$self->{'cnt'} = scalar @{$self->{'streams'}};
						print STDERR "i:Found (".$self->{'cnt'}.") Youtube stream(s) (".join('|',@ytStreams).") via youtube-dl.\n"  if ($DEBUG);
					}					
				}
NOTNEEDED:
				if ($nonYtCnt > 0) {
					if ($self->{'youtube'} =~ /(?:top|first)/i) {  #PUT youtube-dl STREAMS ON TOP:
						push @{$self->{'streams'}}, @nonYtStreams;
					} else {
						unshift @{$self->{'streams'}}, @nonYtStreams;
					}
					foreach my $field (qw(title description)) {
						$self->{$field} ||= $yt->{$field}  if (defined($yt->{$field}) && $yt->{$field});
					}
					$self->{'cnt'} = scalar @{$self->{'streams'}};
					print STDERR "i:Found ($nonYtCnt) non-Youtube stream(s) (".join('|',@nonYtStreams).") via youtube-dl.\n"  if ($DEBUG);
				}
			}
			$self->{'imageurl'} ||= $self->{'iconurl'};
			$self->{'cnt'} = scalar @{$self->{'streams'}};
			if ($self->{'description'} =~ /\w/) {
				$self->{'description'} =~ s/\s+$//;
			} else {
				$self->{'description'} = $self->{'title'};
			}
			foreach my $i (qw(title description)) {
				$self->{$i} = HTML::Entities::decode_entities($self->{$i});
				$self->{$i} = uri_unescape($self->{$i});
				$self->{$i} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egso;
			}
		}
	}
	$self->{'total'} = $self->{'cnt'};
	$self->{'Url'} = ($self->{'cnt'} > 0) ? $self->{'streams'}->[0] : '';
	print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"
			if ($DEBUG && $self->{'cnt'} > 0);
	print STDERR "\n--ID=".$self->{'id'}."=\n--TITLE=".$self->{'title'}."=\n--CNT=".$self->{'cnt'}."=\n--ICON=".$self->{'iconurl'}."=\n--1ST=".$self->{'Url'}."=\n--streams=".join('|',@{$self->{'streams'}})."=\n"  if ($DEBUG);
	$self->_log($url);

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub fetchChannelPage {
	my $self = shift;
	my $whichImg = shift;

	unless ($self->{'articonurl'}) {
		my $html = '';
		return ''  unless ($self->{'albumartist'} && $self->{'albumartist'} =~ m#^https?\:\/\/#);

		my $url2fetch = $self->{'albumartist'};
		print STDERR "-0(Fetch Odysee Channel for artist. icon from $url2fetch): \n"  if ($DEBUG);
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

		$self->{'articonurl'} = $1  if ($html =~ m#\<meta\s+name\=\"twitter\:image\"\s+content\=\"([^\"]+)#s) ? $1 : '';
		($self->{'artimageurl'} = $self->{'articonurl'}) =~ s#^.+?(https?\:\/.+)$#$1#i
				if ($self->{'articonurl'});
		print STDERR "--ART ($whichImg) URL=".$self->{$whichImg}."=\n"  if ($DEBUG);
	}
	return $self->{$whichImg};
}


sub getIconURL
{
	my $self = shift;
	return $self->{'iconurl'}  unless (defined($_[0]) && $_[0] =~ /^\-?artist/i);
	return $self->fetchChannelPage('articonurl');
}

sub getImageURL
{
	my $self = shift;
	return $self->{'iconurl'}  unless (defined($_[0]) && $_[0] =~ /^\-?artist/i);
	return $self->fetchChannelPage('artimageurl');
}

1
