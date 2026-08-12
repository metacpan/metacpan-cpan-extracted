=head1 NAME

StreamFinder::Subsplash - Fetch actual raw streamable URLs on subsplash.com

=head1 AUTHOR

This module is Copyright (C) 2021-2026 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::Subsplash;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $podcast = new StreamFinder::Subsplash($ARGV[0]);

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

		if ($icon_image && open IMGOUT, ">/tmp/${podcastID}.$image_ext") {

			binmode IMGOUT;

			print IMGOUT $icon_image;

			close IMGOUT;

			print "...Icon image downloaded to (/tmp/${podcastID}.$image_ext)\n";

		}

	}

	my $stream_count = $podcast->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $podcast->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::Subsplash accepts a valid podcast (sermon) page URL on 
Subsplash.com and returns the actual stream URL(s), title, and cover art icon.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the podcast in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of play.  The author uses his own custom all-purpose media player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
Subsplash.com streams.

One or more stream URLs can be returned for each podcast.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, I<-secure> [ => 0|1 ] 
[, I<-nohls> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ] 
[, I<-youtube> => yes|no|first|last|only|ifneeded ]])

Accepts a subsplash.com podcast (sermon) URL and creates and returns a 
a new podcast object, or I<undef> if the URL is not a valid podcast, or no 
streams are found.  The URL must be the full URL, ie. 
https://subsplash.com/...B<channel>/.../B<episode><id>.

The optional I<-youtube> argument can be set to "I<yes>" or "I<last>" - 
Subsplash will also look for streams via the external program yt-dlp ,if 
available, (last - after Subsplash streams, if any, found on the page); 
"I<no>" - only include streams found from the video's subsplash.com page; 
"I<only>" - return only streams returned by yt-dlp; or "I<first>" - include the 
yt-dlp streams (if any) first.  
NOTE:  Unlike most other modules, yt-dlp will NOT be used if I<-youtube> is set 
to I<no> regardless of whether any Subsplash streams were found.  
If I<-youtube> is set to I<ifneeded>, then yt-dlp 
will only be called if no other streams found.  Default is set to "first" 
because now generally only audio streams are found on Subsplash pages.

DEFAULT I<-youtube> is 'first'.

The optional (<-nohls> argument can be set to either 0 or 1 
(I<false> or I<true>).  If 1 (I<true>), then only non-HLS (.m3u8?) streams 
will be accepted from Subsplash or yt-dlp (Youtube).

DEFAULT I<-nohls> is 0 (false) - return all streams yt-dlp finds in Subsplash.

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  If 1 
then only secure ("https://") streams will be returned.

DEFAULT I<-secure> is 0 (false) - return all streams (http and https).

Additional options:

Certain yt-dlp (L<StreamFinder::Youtube>) configuration options, 
namely I<-format>, I<-formatonly>, I<-youtube-dl-args>, 
and I<-youtube-dl-add-args> can be overridden here by specifying 
I<-youtube-format>, I<-youtube-formatonly>, I<-youtube-dl-args>, 
and I<-youtube-dl-add-args> arguments respectively.  It is however, 
recommended to specify these in the Subsplash-specific configuration file 
(see B<CONFIGURATION FILES> below).

I<-log> => "I<logfile>"

Specify path to a log file.  If a valid and writable file is specified, 
A line will be appended to this file every time one or more streams is 
successfully fetched for a url.

DEFAULT I<-none-> (no logging).

I<-logfmt> specifies a format string for lines written to the log file.

DEFAULT "I<[time] [url] - [site]: [title] ([total])>".  

The valid field I<[variables]> are:  [stream]: The url of the first/best 
stream found.  [site]:  The site name (Subsplash).  [url]:  The url searched 
for streams.  [time]: Perl timestamp when the line was logged.  [title], 
[artist], [album], [description], [year], [genre], [total], [albumartist]:  
The corresponding field data returned (or "I<-na->", if no value).

=item $podcast->B<get>()

Returns an array of strings representing all stream URLs found.

=item $podcast->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  There currently are no valid I<options>.

=item $podcast->B<count>()

Returns the number of streams found for the podcast.

=item $podcast->B<getID>()

Returns the podcast's Subsplash ID (default).  For podcasts, the Subsplash ID 
is a single value.  For individual podcast episodes it's two values 
separated by a slash ("/").

=item $podcast->B<getTitle>(['desc'])

Returns the podcast's title, or (long description).  Podcasts 
on Subsplash can have separate descriptions, but for podcasts, 
it is always the podcast's title.

=item $podcast->B<getIconURL>(['artist'])

Returns the URL for the podcast's "cover art" icon image, if any.
If B<'artist'> is specified, the channel artist's icon url is returned, 
if any.

=item $podcast->B<getIconData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.
If B<'artist'> is specified, the channel artist's icon data is returned, 
if any.

=item $podcast->B<getImageURL>(['artist'])

Returns the URL for the podcast's "cover art" (usually larger) 
banner image.  Note:  Subsplash returns the same image url as the icon url.
If B<'artist'> is specified, the channel artist's image URL 
is returned, if any, which may be larger than the artist's icon image.

=item $podcast->B<getImageData>(['artist'])

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual podcast's banner image (binary data).
If B<'artist'> is specified, the channel artist's image data is returned, 
if any.

=item $podcast->B<getType>()

Returns the podcast's type ("Subsplash").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/Subsplash/config

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
I<-debug> => [0|1|2]> and most of the L<LWP::UserAgent> options.  

Among options valid for Subsplash streams are the various youtube-dl 
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
I<-debug> => [0|1|2]> and most of the L<LWP::UserAgent> options.

=back

NOTE:  Options specified in the options parameter list will override 
those corresponding options specified in these files.

=head1 KEYWORDS

subsplash

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

yt-dlp, or other compatable program

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-subsplash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Subsplash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Subsplash

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Subsplash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Subsplash>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Subsplash/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2021-2026 Jim Turner.

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

package StreamFinder::Subsplash;

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

	my $self = $class->SUPER::new('Subsplash', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});
	$self->{'youtube'} = 'first'  unless (defined $self->{'youtube'});
	$self->{'nohls'} = 0  unless (defined $self->{'nohls'});
	while (@_) {
		if ($_[0] =~ /^\-?youtube$/o) {
			shift;
			$self->{'youtube'} = (defined $_[0]) ? shift : 'first';
		} elsif ($_[0] =~ /^\-?nohls$/o) {
			shift;
			$self->{'nohls'} = (defined $_[0]) ? shift : 1;
		} else {
			shift;
		}
	}

	$url =~ s#\\##g;
	my $url2fetch = HTML::Entities::decode_entities($url);
	my ($protocol, undef, $server, @urlparts) = split(m#\/#, $url2fetch);
	my $channel = '';
	foreach my $j (@urlparts) {
		$j =~ s/[\?\&].*$//o;
		next  if ($j =~ /\b(?:embed|media)\b/o);
		if (length($j) < 4) {
			$self->{'albumartist'} .= '/' . $j  unless ($channel);
			next;
		} elsif ($channel) {
			$self->{'id'} = $j;
		} else {
			$self->{'albumartist'} .= '/' . $j;
			$channel = $j;
		}
	}
	$self->{'id'} ||= $channel;
	my $baseURL = $protocol . '//' . $server;
	$self->{'albumartist'} = $baseURL . $self->{'albumartist'} . '/media';
	my $html = '';
	print STDERR "-0(Subsplash): FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html);  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!
	$self->{'cnt'} = 0;
	$self->{'title'} = '';
	$self->{'artist'} = '';
	$self->{'album'} = $url2fetch;
	$self->{'description'} = '';
	$self->{'created'} = '';
	$self->{'year'} = '';
	$self->{'genre'} = 'Podcast';
	$self->{'iconurl'} = '';
	$self->{'streams'} = [];
	$self->{'Url'} = '';
	$self->{'playlist'} = '';
	my %dups = ();
	my $stream = '';
	my @nonYtStreams = ();
	my $nonYtCnt = 0;
	my @YTDLstreams = ();
	my $YTDLcnt = 0;
	my $embedPage = 0;
	unless ($self->{'youtube'} =~ /only/i) {
		#TRY TO FETCH ANY STREAM IN THE SUBSPLASH PAGE ITSELF:
		foreach my $tag ('video', 'audio') {
			if ($html =~ s#\<$tag\s+preload(.+?)\<\/$tag\>##si) {
				my $stuff = $1;
				if ($stuff =~ m#\<source\s+src\=\"([^\"]+)#) {
					$stream = $1;
					next  if ($self->{'nohls'} && $stream =~ /\.m3u8?/o);
					print STDERR "+++++FOUND $tag stream in page=$stream=\n"  if ($DEBUG);
					push (@nonYtStreams, $stream)
							unless ($self->{'secure'} && $stream !~ /^https/o);
				}
			}
		}
		$nonYtCnt = scalar (@nonYtStreams);

		return undef  unless ($nonYtCnt > 0 || $self->{'youtube'} !~ /no/i);
	}

	foreach my $tag ('og:title', 'twitter:title') {
		if ($html =~ s#\"$tag\"\s+content\=\"([^\"]+)\"##gso) {
			$self->{'title'} = $1;
			last  if ($self->{'title'});
		}
	}
	foreach my $tag ('og:description', 'twitter:description') {
		if ($html =~ s#\"$tag\"\s+content\=\"([^\"]+)\"##gso) {
			$self->{'description'} = $1;
			last  if ($self->{'description'});
		}
	}
	foreach my $tag ('og:image', 'twitter:image') {
		if ($html =~ s#\"$tag\"\s+content\=\"([^\"]+)\"##gso) {
			$self->{'iconurl'} = $1;
			($self->{'imageurl'} = $self->{'iconurl'}) =~ s/\&.+$//;
			last  if ($self->{'iconurl'});
		}
	}
	unless ($self->{'iconurl'}) {
		if ($html =~ m#\<img\s+class\=\"kit\-image\_\_image\"\s+src\=\"([^\"]+)\"#g) {
			($self->{'iconurl'} = $1) =~ s/\&amp\;.*$//;
			$self->{'imageurl'} = $self->{'iconurl'};
		}
	}
	if ($html =~ s#kit\-player\_\_info\-text\-\-date\"\>(.+?)\<\/div\>##s) {
		$self->{'created'} = $1;
		$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
	} elsif ($html =~ s#app\_\_footer\-copyright\"\>(.+?)\<\/div\>##s) {
		$self->{'created'} = $1;
		$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
	} elsif ($html =~ m#\\\"date\\\"\:\\\"(.+?)\\\"#s) {
		$self->{'created'} = $1;
		$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
	} elsif ($html =~ m#\<\!\-\-\s+\-\-\>(\d\d\d\d)\<\!\-\-\s+\-\-\>#) {
		$self->{'created'} = $self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
	}
	if ($html =~ m#\<div\s+class\=\"route\-media\-item\_\_basic\-info\"\>(.+?)\<\/div\>#s) {
		my $addtl = $1;
		if ($addtl =~ m#\<p\>\s*(.+?)\<\/p\>#s) {
			my $stuff = $1;
			if ($stuff =~ s#^\s*(.+?\d\d\d\d)##s) {
				$self->{'created'} = $1;
				$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
				($self->{'artist'} = $stuff) =~ s#^[^\w]+##s;
				$self->{'artist'} =~ s/\s+$//;
				$self->{'artist'} =~ s/[\\\"].*$//s;
			}
		}
	} elsif ($html =~ s#kit\-player\_\_info\-text\-\-additional\"\>(.+?)\<\/div\>##s) { ## DEPRECIATED? ##:
		$self->{'artist'} = $1;
		$self->{'artist'} =~ s/^\s+//s;
		$self->{'artist'} =~ s/\s+$//s;
	} elsif ($html =~ m#\\\"speaker\\\"\:\\\"(.+?)\\\"#s) {
		$self->{'artist'} = $1;
	} elsif ($html =~ m#\<meta\s+property\="(?:og|twitter)\:site\_name\"\s+content\=\"([^\"]+)#s) {
		$self->{'artist'} = $1;
	}
	$self->{'genre'} = $1  if ($html =~ m#\\\"topic\:(.+?)\\\"#s);
	if ($html =~ m#\<div\s+class\=\"route\-media\-item\_\_more\-items\-title\"(.+?)\<\/div\>#s) {
		my $addtl = $1;
		if ($addtl =~ m#\<a[^\>]+\>\s*(.+?)\<\/a\>#s) {
			($self->{'album'} = $1) =~ s/\s+$//;
		}
	}
	if ($html =~ m#\<img\s+alt\=\"logo\" ([^\>]+)#s) {
		my $data = $1;
		$self->{'articonurl'} = $1  if ($data =~ m#src\=\"(.+?)(?:\"| \dx)#);
		$self->{'articonurl'} = $baseURL . $self->{'articonurl'}
				if ($self->{'articonurl'} =~ m#^\/#);
		$self->{'articonurl'} =~ s/\"$//;
		$self->{'articonurl'} = uri_unescape($self->{'articonurl'});
		$self->{'articonurl'} = HTML::Entities::decode_entities($self->{'articonurl'});
		$self->{'articonurl'} =~ s/^.*\?url\=//;
	}

	my $haveYoutube = 0;
	unless ($self->{'youtube'} =~ /no/i || ($nonYtCnt > 0 && $self->{'youtube'} =~ /ifneeded/i)) {
		eval { require 'StreamFinder/Youtube.pm'; $haveYoutube = 1; };
	}
	print STDERR "\n-2 NO STREAMS FOUND IN PAGE (haveYoutube=$haveYoutube)\n"  if ($DEBUG && $nonYtCnt <= 0);
	if ($haveYoutube) {
		print STDERR "\n-2 TRYING yt-dlp...\n"  if ($DEBUG);
		my %globalArgs = (
				'-noiframes' => 1, '-fast' => 1, '-debug' => $DEBUG
		);
		foreach my $arg (qw(secure log logfmt youtube-format youtube-format-fallback
				youtube-formatonly youtube-dl-args youtube-dl-add-args)) {
			(my $arg0 = $arg) =~ s/^youtube\-(?!dl)//o;
			$globalArgs{$arg0} = $self->{$arg}  if (defined $self->{$arg});
		}
		my $yt = new StreamFinder::Youtube($url2fetch, %globalArgs);
		if ($yt) {
			if ($yt->count() > 0) {
				my @ytStreams = $yt->get();
				foreach my $s (@ytStreams) {
					print STDERR "+++++FOUND stream via yt-dlp=$s=\n"  if ($DEBUG);
					push (@YTDLstreams, $s)  unless ($self->{'nohls'} && $s =~ /\.m3u8?/o);
				}
				$YTDLcnt = scalar (@YTDLstreams);
				$self->{'description'} = $yt->{'description'}
						if (length($yt->{'description'}) > length($self->{'description'}));
			}
		}
	}
	push (@{$self->{'streams'}}, @YTDLstreams)
			if ($YTDLcnt > 0 && $self->{'youtube'} =~ /(?:yes|top|first|last|only|ifneeded)/i);
	if ($nonYtCnt > 0 && $self->{'youtube'} !~ /only/i) {
		if ($self->{'youtube'} =~ /(?:top|first)/i) {  #PUT yt-dlp STREAMS ON TOP:
			push @{$self->{'streams'}}, @nonYtStreams;
		} else {                                       #PUT STREAMS FROM PAGE ON TOP:
			unshift @{$self->{'streams'}}, @nonYtStreams;
		}
	}
	$self->{'cnt'} = scalar @{$self->{'streams'}};

	foreach my $field (qw(title description artist)) {
		$self->{$field} = HTML::Entities::decode_entities($self->{$field});
		$self->{$field} = uri_unescape($self->{$field});
		$self->{$field} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	}
	$self->{'total'} = $self->{'cnt'};
	$self->{'id'} =~ s/[\+]//g;  #DON'T LEAVE THESE IN POTENTIAL FILE-NAMES!:
	$self->{'id'} =~ s/^[\-]//;
	$self->{'Url'} = ($self->{'total'} > 0) ? $self->{'streams'}->[0] : '';
	print STDERR "-SUCCESS: 1st stream=".$self->{'Url'}."=\n"  if ($DEBUG);
	$self->_log($url);
	if ($DEBUG) {
		foreach my $i (sort keys %{$self}) {
			print STDERR "--KEY=$i= VAL=".$self->{$i}."=\n";
		}
		print STDERR "--FIRST STREAM=".${$self->{'streams'}}[0]."=\n";
	}

	bless $self, $class;   #BLESS IT!

	return $self;
}

1
