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

	my $station = new StreamFinder::BannedVideo(<url>,
			'secure_shoutcast', 'secure', 'any', '!rtmp');

	die "Invalid URL or no streams found!\n"  unless ($station);

	my $firstStream = $station->get();

	print "First Stream URL=$firstStream\n";

	my $url = $station->getURL();

	print "Stream URL=$url\n";

	my $stationTitle = $station->getTitle();
	
	print "Title=$stationTitle\n";
	
	my $stationID = $station->getID();

	print "Station ID=$stationID\n";
	
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

StreamFinder::BannedVideo accepts a valid video URL on Banned.Video 
(Alex Jone's infowars new video site after communist YouTube BANNED his videos) 
and, at the moment, youtube-dl doesn't convert them (yet?);
and returns the actual stream URL(s) and cover art icon for that video.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the station in one's own choice of audio player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, censorship, and other crapware that can come with 
that method of playing.  The author uses his own custom all-purpose media 
player called "fauxdacious" (his custom hacked version of the open-source 
"audacious" audio player).  "fauxdacious" can incorporate this module to decode 
and play banned.video streams.

One or more stream URLs can be returned for each video.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, I<streamtype> | "debug" [ => 0|1|2 ] ... ])

Accepts an Banned.Video URL and creates and returns a new station object, or 
I<undef> if the URL is not a valid Banned.Video station or no streams are found.

The optional I<streamtype> can be one of:  any, secure, secure_pls, pls, 
secure_hls, hls, secure_shortcast, shortcast, secure_rtmp, rtmp, etc.  More 
than one value can be specified to control order of search.  A I<streamtype> 
can be preceeded by an exclamantion point ("!") to reject that type of stream.
If "any" appears in the list, it should be the last specifier without a "!" 
preceeding it, and itself should not be preceeded with a "!" (inverter)!  

For example, the list:  'secure_shoutcast', 'secure', 'any', '!rtmp' 
would try to find a "secure_shoutcast" (https) shortcast stream, if none found, 
would then look for any secure (https) stream, failing that, would look for 
any valid stream.  All the while skipping any that are "rtmp" 
streams.

=item $station->B<get>()

Returns an array of strings representing all stream urls found.

=item $station->B<getURL>()

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  

=item $station->B<count>()

Returns the number of streams found for the station.

=item $station->B<getID>([ 'iheart' | 'fccid' ])

Returns the video's Banned.Video ID.

=item $station->B<getTitle>()

Returns the station's title (description).  

=item $station->B<getIconURL>()

Returns the url for the station's "cover art" icon image, if any.

=item $station->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc. and the actual icon image (binary data), if any.

=item $station->B<getImageURL>()

Returns the url for the station's "cover art" banner image.

=item $station->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc. and the actual station's banner image (binary data).

=item $station->B<getType>()

Returns the stream's type ("BannedVideo").

=back

=head1 KEYWORDS

BannedVideo

=head1 DEPENDENCIES

LWP::UserAgent

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
use LWP::UserAgent ();
use vars qw(@ISA @EXPORT);

our $DEBUG = 0;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(get getURL getType getID getTitle getIconURL getIconData getImageURL getImageData);

sub new
{
	my $class = shift;
	my $url = shift;
	my (@okStreams, @skipStreams);
	while (@_) {
		if ($_[0] =~ /^\!/o) {
			(my $i = shift) =~ s/\!//o;
			push @skipStreams, $i;
		} elsif ($_[0] =~ /^\-?debug$/o) {
			shift;
			$DEBUG = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
print STDERR "-???- DEBUG=$DEBUG=\n";
		} else {
			push @okStreams, shift;
		}
	}	
	@okStreams = ('any')  unless (defined $okStreams[0]);  # one of:  {secure_pls | pls | stw}

	my $self = {};

	print STDERR "-0(BannedVideo): URL=$url=\n"  if ($DEBUG);
	return undef  unless ($url);

	(my $url2fetch = $url);
	$url2fetch = 'https://banned.video/watch?id=' . $url  unless ($url =~ /^http/);
	$self->{'cnt'} = 0;
	$self->{'id'} = $1  if ($url2fetch =~ m#id\=([^\/\?\&]+)$#);
	my $html = '';
	print STDERR "-0(BannedVideo): ID=".$self->{'id'}."= URL=$url2fetch=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new;		
	$ua->timeout(10);
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
		print STDERR "\n..trying wget...\n"  if ($DEBUG);
		$html = `wget -t 2 -T 20 -O- -o /dev/null \"$url2fetch\" 2>/dev/null `;
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html);  #STEP 1 FAILED, INVALID STATION URL, PUNT!

	my $stindex = 0;
	my @streams = ();
	foreach my $streamtype (@okStreams) {
		unless ($streamtype =~ /^m3u8$/i) {
			$streams[$stindex] = ($html =~ /\"directUrl\"\s*\:\s*\"([^\"]+)\"/i) ? $1 : '';
			$stindex++;
		}
		unless ($streamtype =~ /^(?:mp4|direct)$/i) {
			$streams[$stindex] = ($html =~ /\"streamUrl\"\s*\:\s*\"([^\"]+)\"/i) ? $1 : '';
			$stindex++;
		}
	}
	print STDERR "-2: 1=$streams[0]= 2=$streams[1]\n"  if ($DEBUG);
	return undef  unless ($#streams >= 0);

	$self->{'cnt'} = scalar @streams;
	$self->{'title'} = ($html =~ /\"title\"\s*\:\s*\"([^\"]+)\"/i) ? $1 : '';
	$self->{'iconurl'} = ($html =~ /\"(?:poster)?ThumbnailUrl\"\s*\:\s*\"([^\"]+)\"/i) ? $1 : '';
	$self->{'imageurl'} = ($html =~ /\"posterLargeUrl\"\s*\:\s*\"([^\"]+)\"/i) ? $1 : '';
	$self->{'imageurl'} ||= $self->{'iconurl'};

	$self->{'streams'} = \@streams;  #WE'LL HAVE A LIST OF 'EM TO RANDOMLY CHOOSE ONE FROM:
	$self->{'total'} = $self->{'cnt'};
	print STDERR "-(all)count=".$self->{'cnt'}."= iconurl=".$self->{'iconurl'}."=\n"  if ($DEBUG);
	print STDERR "-SUCCESS: 1st stream=".${$self->{'streams'}}[0]."=\n"  if ($DEBUG);

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
	my $self = $_[0];
	return ${$self->{'streams'}}[0];
}

sub count
{
	my $self = shift;
	return $self->{'total'};  #TOTAL NUMBER OF PLAYABLE STREAM URLS FOUND.
}

sub getType
{
	my $self = shift;
	return 'BannedVideo';  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
}

sub getID
{
	my $self = shift;
	return $self->{'id'};
}

sub getTitle
{
	my $self = shift;
	return $self->{'title'};  #URL TO THE STATION'S TITLE(DESCRIPTION), IF ANY.
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

	my $ua = LWP::UserAgent->new;		
	$ua->timeout(10);
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $art_image = '';
	my $response = $ua->get($self->{'iconurl'});
	if ($response->is_success) {
		$art_image = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
		print STDERR "\n..trying wget...\n"  if ($DEBUG);
		my $iconUrl = $self->{'iconurl'};
		$art_image = `wget -t 2 -T 20 -O- -o /dev/null \"$iconUrl\" 2>/dev/null `;
	}
	return ()  unless ($art_image);

	(my $image_ext = $self->{'iconurl'}) =~ s/^.+\.//;
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
	my $ua = LWP::UserAgent->new;		
	$ua->timeout(10);
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $art_image = '';
	my $response = $ua->get($self->{'imageurl'});
	if ($response->is_success) {
		$art_image = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	return ()  unless ($art_image);
	my $image_ext = $self->{'imageurl'};
	$image_ext = ($self->{'imageurl'} =~ /\.(\w+)$/) ? $1 : 'png';
	$image_ext =~ s/[^A-Za-z].*$//;
	return ($image_ext, $art_image);
}

1
