=head1 NAME

StreamFinder::BrandNewTube - Fetch actual raw streamable URLs from BrandNewTube.com.

=head1 AUTHOR

This module is Copyright (C) 2022 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::BrandNewTube;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $video = new StreamFinder::BrandNewTube($ARGV[0]);

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

StreamFinder::BrandNewTube accepts a valid full BrandNewTube video ID or page URL 
(either one of their ".html" or "embed" URL) on brandnewtube.com and returns 
the actual stream URL, title, and cover art icon for that video.  
The purpose is that one needs this URL in order to have the option to 
stream the video in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that 
method of play.  The author uses his own custom all-purpose media player 
called "fauxdacious" (his custom hacked version of the open-source 
"audacious" audio player).  "fauxdacious" incorporates this module to 
decode and play brandnewtube.com videos.  This is a submodule of the general 
StreamFinder module.

Depends:  

L<URI::Escape>, L<HTML::Entities>, and L<LWP::UserAgent>.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-secure> [ => 0|1 ]] 
[, I<-debug> [ => 0|1|2 ]])

Accepts a brandnewtube.com video ID or URL and creates and returns a new video 
object, or I<undef> if the URL is not a valid BrandNewTube video or no streams 
are found.  The URL can be the full URL, 
ie. https://brandnewtube.com/B<video-id>.html, 
https://brandnewtube.com/B<@channel-id>, 
https://brandnewtube.com/embed/B<video-id> or just B<video-id> or 
I<@channel-id>.  If a channel URL is given, then the first (latest) video of 
that channel will be returned.  Note:  Channel-ids are distinguished by the 
"@"-sign. 

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  
If 1 then only secure ("https://") streams will be returned.

DEFAULT I<-secure> is 0 (false) - return all streams (http and https).

Additional options:

I<-log> => "I<logfile>"

Specify path to a log file.  If a valid and writable file is specified, A line 
will be appended to this file every time one or more streams is successfully 
fetched for a url.

DEFAULT I<-none-> (no logging).

I<-logfmt> specifies a format string for lines written to the log file.

DEFAULT "I<[time] [url] - [site]: [title] ([total])>".  

The valid field I<[variables]> are:  [stream]: The url of the first/best 
stream found.  [site]:  The site name (BrandNewTube).  [url]:  The url searched for 
streams.  [time]: Perl timestamp when the line was logged.  [title], [artist], 
[album], [description], [year], [genre], [total], [albumartist]:  
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

Returns the video's BrandNewTube ID (alphanumeric).

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
BrandNewTube videos is always the icon image, as BrandNewTube does not 
support a separate banner image at this time.

=item $video->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual video's banner image (binary data).

=item $video->B<getType>()

Returns the video's type ("BrandNewTube").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/BrandNewTube/config

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

brandnewtube

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-brandnewtube at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-BrandNewTube>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::BrandNewTube

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-BrandNewTube>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-BrandNewTube>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-BrandNewTube>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-BrandNewTube/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Jim Turner.

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

package StreamFinder::BrandNewTube;

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

	my $self = $class->SUPER::new('BrandNewTube', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});

	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $response;
	$self->{'genre'} = 'Video';

	unless ($url =~ m#https?\:#) {
		if ($url =~ /^\@/) {
			$url = 'https://brandnewtube.com/@' . $url;
		} else {
			$url = ($url =~ m#\-#)
					? "https://brandnewtube.com/watch/${url}.html"
					: "https://brandnewtube.com/embed/${url}/";
		}
	}

	my $domain = ($url =~ m#(https?\:\/\/[^\/]+)#) ? $1 : 'https://brandnewtube.com';

	if ($url =~ /\@/) {
		my $html = '';
		print STDERR "-FETCHING CHANNEL URL=$url= ID=".$self->{'id'}."=\n"  if ($DEBUG);
		$response = $ua->get($url);
		if ($response->is_success) {
			$html = $response->decoded_content;
		} else {
			print STDERR $response->status_line  if ($DEBUG);
			my $no_wget = system('wget','-V');
			unless ($no_wget) {
				print STDERR "\n..trying wget...\n"  if ($DEBUG);
				$html = `wget -t 2 -T 20 -O- -o /dev/null \"$url\" 2>/dev/null `;
			}
		}
		if ($html && $html =~ m#\<a\s+href\=\"($domain\/watch\/[^\"]+)#s) {
			$url = $1;
			print STDERR "---FOUND 1ST EPISODE URL=$url= IN CHANNEL PAGE, RUN WITH THAT!\n"  if ($DEBUG);
		}
	}

	my $html = '';
	if ($url =~ m#\/watch\/([^\/\.]+)#) {
		$self->{'id'} = $1;
		print STDERR "-FETCHING HTML URL=$url= ID=".$self->{'id'}."=\n"  if ($DEBUG);
		$response = $ua->get($url);
		if ($response->is_success) {
			$html = $response->decoded_content;
		} else {
			print STDERR $response->status_line  if ($DEBUG);
			my $no_wget = system('wget','-V');
			unless ($no_wget) {
				print STDERR "\n..trying wget...\n"  if ($DEBUG);
				$html = `wget -t 2 -T 20 -O- -o /dev/null \"$url\" 2>/dev/null `;
			}
		}
		if ($html) {
			$self->{'title'} = ($html =~ m#\<title\>([^\<]+)\<\/title\>#s) ? $1 : '';
			$self->{'title'} ||= $1  if ($html =~ m#\<meta\s+property\=\"?og\:title\"?\s+content\=\"([^\"]+)\"#s);

			if ($html =~ m#<div class="publisher-name(.+)?\/div\>#s) {
				my $publisherHtml = $1;
				$self->{'artist'} = $1  if ($publisherHtml =~ m#\>([^\<]+)\<\/a#s);
				$self->{'albumartist'} = $1  if ($publisherHtml =~ m#\<a\s+href\=\"([^\"]+)#s);
				$self->{'year'} = $1  if ($publisherHtml =~ m#(\d+)\<\/span#s);
			}
			if ($html =~ m#<div class="publisher-avatar(.+)?\/div\>#s) {
				my $publisherHtml = $1;
				$self->{'articonurl'} = $1  if ($publisherHtml =~ m#\<img\s+src\=\"([^\"]+)#s);
				$self->{'albumartist'} ||= $1  if ($publisherHtml =~ m#\<a\s+href\=\"([^\"]+)#s);
			}
			if ($html =~ m#<div class="video-published(.+)?\/div\>#s) {
				my $publisherHtml = $1;
				$self->{'genre'} = HTML::Entities::decode_entities($1)  if ($publisherHtml =~ m#\>([^\<]+)\<\/a#s);
			}

			$self->{'description'} = $1  if ($html =~ m# itemprop\=\"description\"\>(.+?)\<\/p\>#s);
			$self->{'description'} ||= $1  if ($html =~ m#<meta\s+name\=\"(?:og\:|twitter\:)?description\"\s+content\=\"([^\"]+)#s);

			$self->{'iconurl'} = $1  if ($html =~ m#<meta\s+name\=\"thumbnail\"\s+content\=\"([^\"]+)#s);
			$self->{'iconurl'} ||= $1  if ($html =~ m#<meta\s+name\=\"(?:og\:|twitter\:)?image\"\s+content\=\"([^\"]+)#s);

			$self->{'imageurl'} = $1  if ($html =~ m# poster\=\"([^\"]+)#s);

			#TRY TO FETCH STREAMS:
			while ($html =~ s#\<source\s+src\=\"([^\"]+)\"##so) {
				my $one = $1;
				push @{$self->{'streams'}}, $one  unless ($self->{'secure'} && $one !~ /^https/o);
				$self->{'cnt'}++;
			}
			#STEP 2:  FETCH THE EMBED URL:
			if ($html =~ m#\<iframe\s+src\=\"($domain\/embed\/[^\"]+)#s) {
				$url = $1  unless ($self->{'cnt'} > 0);
			}
		}
	}
	if ($url =~ m#\/embed\/([^\/]+)$#) {
		$self->{'id'} ||= $1;
		print STDERR "-FETCHING EMBED URL=$url= ID=".$self->{'id'}."=\n"  if ($DEBUG);
		$response = $ua->get($url);
		if ($response->is_success) {
			$html = $response->decoded_content;
		} else {
			print STDERR $response->status_line  if ($DEBUG);
			my $no_wget = system('wget','-V');
			unless ($no_wget) {
				print STDERR "\n..trying wget...\n"  if ($DEBUG);
				$html = `wget -t 2 -T 20 -O- -o /dev/null \"$url\" 2>/dev/null `;
			}
		}
		if ($html) {
			$self->{'title'} ||= ($html =~ m#\<title\>([^\<]+)\<\/title\>#s) ? $1 : '';
			$self->{'title'} ||= $1  if ($html =~ m#\<meta\s+property\=\"?og\:title\"?\s+content\=\"([^\"]+)\"#s);
			$self->{'imageurl'} ||= $1  if ($html =~ m# poster\=\"([^\"]+)#s);
			$self->{'cnt'} = 0;
			while ($html =~ s#\<source\s+src\=\"([^\"]+)\"##so) {
				my $one = $1;
				push @{$self->{'streams'}}, $one  unless ($self->{'secure'} && $one !~ /^https/o);
				$self->{'cnt'}++;
			}
		}
	}

	$self->{'cnt'} = scalar @{$self->{'streams'}};
	foreach my $field (qw(description artist title)) {
		$self->{$field} = HTML::Entities::decode_entities($self->{$field});
		$self->{$field} = uri_unescape($self->{$field});
		$self->{$field} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	}
	$self->{'title'} =~ s/\s+\-\s+$self->{'artist'}\s*$//;  #CONVERT "Title - Artist" => "Title"
	$self->{'imageurl'} ||= $self->{'iconurl'};
	$self->{'iconurl'} ||= $self->{'imageurl'};
	$self->{'iconurl'} ||= $self->{'articonurl'}  if ($self->{'articonurl'});
	$self->{'total'} = $self->{'cnt'};
	$self->{'Url'} = ($self->{'cnt'} > 0) ? $self->{'streams'}->[0] : '';
	print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"
			if ($DEBUG && $self->{'cnt'} > 0);
	print STDERR "\n--ID=".$self->{'id'}."=\n--TITLE=".$self->{'title'}."=\n--CNT="
			.$self->{'cnt'}."=\n--ICON=".$self->{'iconurl'}."=\n--1ST=".$self->{'Url'}
			."=\n--streams=".join('|',@{$self->{'streams'}})."=\n"  if ($DEBUG);
	$self->_log($url);

	bless $self, $class;   #BLESS IT!

	return $self;
}

1
