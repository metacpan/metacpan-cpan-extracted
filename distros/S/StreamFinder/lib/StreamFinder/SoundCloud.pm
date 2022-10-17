=head1 NAME

StreamFinder::SoundCloud - Fetch actual raw streamable URLs from song-entry websites on SoundCloud.com

=head1 AUTHOR

This module is Copyright (C) 2021 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::SoundCloud;

	die "..usage:  $0 ID|ID/ID|URL\n"  unless ($ARGV[0]);

	my $song = new StreamFinder::SoundCloud($ARGV[0]);

	die "Invalid URL or no streams found!\n"  unless ($song);

	my @streams = $song->get();

	my $url = $song->getURL();

	print "Stream URL=$url\n";

	my $songTitle = $song->getTitle();
	
	print "Title=$songTitle\n";
	
	my $songDescription = $song->getTitle('desc');
	
	print "Description=$songDescription\n";
	
	my $songID = $song->getID();

	print "Song-ID ID=$songID\n";
	
	my $genre = $song->{'genre'};

	print "Genre=$genre\n"  if ($genre);
	
	my $artist = $song->{'artist'};

	print "Artist=$artist\n"  if ($artist);
	
	my $album = $song->{'album'};

	print "Album (podcast)=$album\n"  if ($album);
	
	my $albumartist = $song->{'albumartist'};

	print "Album Artist=$albumartist\n"  if ($albumartist);
	
	my $icon_url = $song->getIconURL();

	if ($icon_url) {   #SAVE THE ICON TO A TEMP. FILE:

		my ($image_ext, $icon_image) = $song->getIconData();

		if ($icon_image && open IMGOUT, ">/tmp/${SongID}.$image_ext") {

			binmode IMGOUT;

			print IMGOUT $icon_image;

			close IMGOUT;

		}

	}

	my $stream_count = $song->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $song->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::SoundCloud accepts a valid artist-ID/song-ID, artist-ID, or URL on 
SoundCloud.com and returns the actual stream URL(s), title, and cover art icon.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the song in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of play.  The author uses his own custom all-purpose media player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
SoundCloud.com streams.  One or more streams can be returned for each song.  

WARNING:  SoundCloud streams usually EXPIRE VERY QUICKLY, ie. A FEW MINUTES, 
and become unplayable (403 ERRORS), requiring recording during first play, or 
repeatedly readding to your playlist!

NOTE:  SoundCloud REQUIRES youtube-dl / yt-dlp (StreamFinder::Youtube) to 
extract the actual stream and only returns a SINGLE valid stream URL for a 
song based on a boilerplate URL based on the author's + song's ID.  However, 
youtube-dl does NOT return the metadata, which we're able to extract here.  
This may or may NOT work for a given song (particularly non-free / 
subscription-required songs, ymmv)!  NOTE:  If just an artist-ID is 
specified, then the first (latest?) song for that artist will be returned.  

StreamFinder::SoundCloud is not capable of returning multisong playlists.  
You therefore need to specify both an artist-ID and preferrably a song-ID or 
a SoundCloud URL containing these, NOT a "set" (playlist/group) URL (ie. 
"https://soundcloud.com/.../set/...", which will not work)!

Depends:  

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>, L<Streamfinder::Youtube>, 
and the separate application program:  youtube-dl, or a compatable program 
such as yt-dlp.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<ID/ID>|I<url> [, I<-debug> [ => 0|1|2 ]])

Accepts a soundcloud.com valid artist-ID/song-ID, artist-ID, or URL and creates 
and returns a new song object, or I<undef> if the URL is not a valid SoundCloud 
song or artist, or no streams are found.  The URL can be the full URL, 
ie. https://soundcloud.com/B<artist-id>/B<song-id>, 
https://soundcloud.com/B<artist-id>, 
or just I<artist-id> or I<artist-id>/I<song-id>.

Additional options:

Certain youtube-dl (L<StreamFinder::Youtube>) configuration options, 
namely I<-format>, I<-formatonly>, I<-youtube-dl-args>, 
and I<-youtube-dl-add-args> can be overridden here by specifying 
I<-youtube-format>, I<-youtube-formatonly>, I<-youtube-dl-args>, 
and I<-youtube-dl-add-args> arguments respectively.  It is however, 
recommended to specify these in the SoundCloud-specific configuration file 
(see B<CONFIGURATION FILES> below.

I<-log> => "I<logfile>"

Specify path to a log file.  If a valid and writable file is specified, A line will be 
appended to this file every time one or more streams is successfully fetched for a url.

DEFAULT I<-none-> (no logging).

I<-logfmt> specifies a format string for lines written to the log file.

DEFAULT "I<[time] [url] - [site]: [title] ([total])>".  

The valid field I<[variables]> are:  [stream]: The url of the first/best stream found.  
[site]:  The site name (SoundCloud).  [url]:  The url searched for streams.  
[time]: Perl timestamp when the line was logged.  [title], [artist], [album], 
[description], [year], [genre], [total], [albumartist]:  The corresponding field data 
returned (or "I<-na->", if no value).

=item $song->B<get>()

Returns an array of strings representing all stream URLs found (usually a single one).

=item $song->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  

=item $song->B<count>()

Returns the number of streams found for the song.

=item $song->B<getTitle>(['desc'])

Returns the song's title, or (long description).  

=item $song->B<getIconURL>(['artist'])

Returns the URL for the song's (or artist's) "cover art" icon image, if any.  
Most SoundCloud artists have their own art-icon.

=item $song->B<getIconData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.

=item $song->B<getImageURL>(['artist'])

Returns the URL for the song's (or artist's) "cover art" (usually larger) 
banner image, if any.  NOTE:  SoundCloud songs usually do NOT have a larger 
art image, but most artists DO.

=item $song->B<getImageData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual artist's banner image (binary data).

=item $song->B<getType>()

Returns the station's type ("SoundCloud").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/SoundCloud/config

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

Among options valid for SoundCloud streams are 
I<-youtube> options described in the B<new()> function.  Also, 
various youtube-dl (L<StreamFinder::Youtube>) configuration options, 
namely I<format>, I<formatonly>, I<youtube-dl-args>, and I<youtube-dl-add-args> 
can be overridden here by specifying I<youtube-format>, I<youtube-formatonly>, 
I<youtube-dl-args>, and I<youtube-dl-add-args> arguments respectively.  
NOTE:  SoundCloud requires youtube-dl or yt-dlp to retrieve any streams!

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

soundcloud

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

youtube-dl (or yt-dlp, or other compatable program)

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-soundcloud at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-SoundCloud>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::SoundCloud

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-SoundCloud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-SoundCloud>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-SoundCloud>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-SoundCloud/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2021 Jim Turner.

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

package StreamFinder::SoundCloud;

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

	my $self = $class->SUPER::new('SoundCloud', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});

	$self->{'notrim'} = 0;
	while (@_) {
		if ($_[0] =~ /^\-?notrim$/o) {
			shift;
			$self->{'notrim'} = (defined $_[0]) ? shift : 1;
		} else {
			shift;
		}
	}

	my $html = '';
	print STDERR "-0(SoundCloud): URL=$url=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;

	(my $url2fetch = $url);

	$self->{'_channel_url'} = '';
	my $tried = 0;
TRYIT:
	if ($url2fetch =~ m#^https?\:#) {
		$url =~ s#[\&\?].*$##;  #REMOVE ANY TRAILING JUNK.
		$url =~ s#\/$##;
		($self->{'id'} = $url) =~ s#^https?\:\/\/soundcloud\.\w+\/##;
	} else {
		$self->{'id'} = $url2fetch;
		$url2fetch = 'https://soundcloud.com/' . $self->{'id'};
	}
	print STDERR "-1  (try=$tried)FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
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
	$html =~ s/\\\"/\&quot\;/gs;
	if ($html) {  #EXTRACT METADATA, IF WE CAN:
		print STDERR "-1: EXTRACTING METADATA...\n"  if ($DEBUG);
		if ($self->{'id'} !~ m#\/#) {  #WE'RE AN ARTIST URL, FETCH 1ST (LATEST) HIT:
			if ($tried) {
				print STDERR "--WE'VE ALREADY TRIED, PUNT($tried)!\n"  if ($DEBUG);
				return undef;
			}
			++$tried;
			if ($html =~ m#\<h2\s+itemprop\=\"name\"\>\s*\<a\s+itemprop\=\"url\"\s+href\=\"\/?([^\"]+)#) {
				$self->{'_channel_url'} = $url2fetch;
				$url2fetch = $1;
				$self->{'artimageurl'} = $1  if ($html =~ m#\"visual\_url\"\:\"(https?\:\/\/[^\"]+)\"#s);
				$self->{'articonurl'} = $1  if ($html =~ m#\<meta\s+property\=\"twitter\:image\"\s+content\=\"(https?\:\/\/[^\"]+)\"#s);
print STDERR "---LATEST SONG ID=$url2fetch= IMGURL=".$self->{'artimageurl'}."=\n"  if ($DEBUG);
				goto TRYIT;
			}
		} else {                       #WE'RE A SONG URL:
			my $haveYoutube = 0;
			eval { require 'StreamFinder/Youtube.pm'; $haveYoutube = 1; };
			if ($haveYoutube) {
				unless ($self->{'_channel_url'}) {
					$self->{'_channel_url'} = $url2fetch;
					$self->{'_channel_url'} =~ s#\/[^\/]+$##;
				}
				$self->{'title'} = $1  if ($html =~ m#\<meta\s+property\=\"twitter\:title\"\s+content\=\"(.+?)\"\>#s);
				$self->{'description'} = $1  if ($html =~ m#\<meta\s+property\=\"twitter\:description\"\s+content\=\"(.+?)\"\>#s);
				$self->{'artist'} = $1  if ($html =~ m#\<meta\s+itemprop\=\"name\"\s+content\=\"([^\"]+?)\"#s);
				$self->{'genre'} = $1  if ($html =~ m#\<meta\s+itemprop\=\"genre\"\s+content\=\"([^\"]+?)\"#s);
				$self->{'iconurl'} = ($html =~ m#\"twitter\:image\"\s+content\=\"([^\"]+)\"#) ? $1 : '';
				$self->{'imageurl'} = $self->{'iconurl'};
				$self->{'iconurl'} =~ s#\?.+$##;
				if ($html =~ m#\"avatar\_url\"\:\"([^\"]+)\"#s) {
					my $avitar_url = $1;
					print STDERR "--AVITAR=".$avitar_url."= (WILL EXCLUDE *default_avitar*)!\n"  if ($DEBUG);
					$self->{'articonurl'} = $avitar_url
							unless ($avitar_url =~ /default\_avatar/);
				}
				if ($html =~ m#\"last\_modified\"\:\"([^\"]+)\"#s) {
					$self->{'created'} = $1;
					$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
				}
				$self->{'albumartist'} = $1  if ($html =~ m#\"label\_name\"\:\"([^\"]+)\"#s);

				my %globalArgs = ('-noiframes' => 1, '-fast' => 1, '-format' => 'any',
						-debug => $DEBUG
				);
				foreach my $arg (qw(secure log logfmt youtube-format youtube-formatonly
						youtube-dl-args youtube-dl-add-args)) {
					(my $arg0 = $arg) =~ s/^youtube\-(?!dl)//o;
					$globalArgs{$arg0} = $self->{$arg}  if (defined $self->{$arg});
				}
				my $yt = new StreamFinder::Youtube($url2fetch, %globalArgs);
				if ($yt && $yt->count() > 0) {
					my @ytStreams = $yt->get();
					foreach my $field (qw(title description)) {
						$self->{$field} ||= $yt->{$field}  if (defined($yt->{$field}) && $yt->{$field});
					}
					print STDERR "i:Found stream(s) (".join('|',@ytStreams).") via youtube-dl.\n"  if ($DEBUG);
					@{$self->{'streams'}} = @ytStreams;
					$self->{'cnt'} = scalar @ytStreams;
				}
			} else {
				print STDERR "f:StreamFinder::Youtube REQUIRED to fetch SoundCloud streams, exiting!\n";
				return undef;
			}
		}
	}
	return undef  unless ($self->{'id'});

	foreach my $field (qw(description artist title genre)) {
		$self->{$field} = HTML::Entities::decode_entities($self->{$field});
		$self->{$field} = uri_unescape($self->{$field});
		$self->{$field} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	}
	$self->{'total'} = $self->{'cnt'};
	$self->{'Url'} = ($self->{'total'} > 0) ? $self->{'streams'}->[0] : '';
	print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"
			if ($DEBUG && $self->{'cnt'} > 0);
	print STDERR "\n--ID=".$self->{'id'}."=\n--TITLE=".$self->{'title'}."\n--ARTIST=".$self->{'artist'}."=\n--STREAMS=".join('|',@{$self->{'streams'}})."=\n"  if ($DEBUG);
	$self->_log($url);

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub fetchChannelPage {
	my $self = shift;
	my $whichImg = shift;

	unless ($self->{'articonurl'}) {
		my $html = '';
		return ''  unless ($self->{'_channel_url'} && $self->{'_channel_url'} =~ m#^https?\:\/\/#);

		my $url2fetch = $self->{'_channel_url'};
		print STDERR "-0(Fetch SoundCloud Channel for artist. icon from $url2fetch): \n"  if ($DEBUG);
		my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});
		$ua->timeout($self->{'timeout'});
		$ua->cookie_jar({});
		$ua->env_proxy;
		my $response = $ua->get($url2fetch);
		if ($response->is_success) {
			$html = $response->decoded_content;
		}

		print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
		return ''  unless ($html);

		$self->{'artimageurl'} = $1  if ($html =~ m#\"visual\_url\"\:\"(https?\:\/\/[^\"]+)\"#s);
		$self->{'articonurl'} = $1  if ($html =~ m#\<meta\s+property\=\"twitter\:image\"\s+content\=\"(https?\:\/\/[^\"]+)\"#s);
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
