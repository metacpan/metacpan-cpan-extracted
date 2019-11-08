=head1 NAME

StreamFinder - Fetch actual raw streamable URLs from various radio-station and video websites.

=head1 INSTALLATION

	To install this module, run the following commands:

	perl Makefile.PL

	make

	make test

	make install

=head1 AUTHOR

This module is Copyright (C) 2017-2019 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	use strict;

	use StreamFinder;

	my $station = new StreamFinder(<url>);

	die "Invalid URL or no streams found!\n"  unless ($station);

	my $firstStream = $station->get();

	print "First Stream URL=$firstStream\n";

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

StreamFinder accepts a valid radio station or video URL on supported websites 
and returns the actual stream URL(s), title, and cover art icon for that 
station.  The purpose is that one needs one of these URLs 
in order to have the option to stream the station / video in one's own choice 
of media player software rather than using their web browser and accepting 
any / all flash, ads, javascript, cookies, trackers, web-bugs, and other 
crapware associated with that method of playing.  The author uses his own 
custom all-purpose media player called "fauxdacious" (his custom hacked 
version of the open-source "audacious" audio player).  "fauxdacious" 
incorporates this module to decode and play streams.  

The currently-supported websites are:  banned.video 
(L<StreamFinder::BannedVideo>), brighteon.com (L<StreamFinder::Brighteon>), 
iheartradio.com (L<StreamFinder::IHeartRadio>), podcasts.apple.com 
(L<StreamFinder::Apple>), radio.net (L<StreamFinder::RadioNet>), 
radionomy.com (L<StreamFinder::Radionomy>), reciva.com (L<StreamFinder::Reciva>), 
tunein.com (L<StreamFinder::Tunein>), vimeo.com (L<StreamFinder::Vimeo>), 
and (youtube.com, et. al and other sites that 
youtube-dl supports) (L<StreamFinder::Youtube>).  

NOTE:  Facebook (Streamfinder::Facebook) has been removed because 
logging into Facebook via the call to youtube-dl is now interpreted by 
Facebook as a "rogue app. login" and will cause them to LOCK your account 
and FORCE you to change your password the next time you log in 
to Facebook!

NOTE:  For some sites, ie. Youtube, Vimeo, Brighteon, and BannedVideo, etc. 
the "station" object actually refers to a specific video or podcast, but 
functions the same way.

Each site is supported by a separate subpackage (StreamFinder::I<Package>), 
which is determined and selected based on the URL when the StreamFinder object 
is created.  The methods are overloaded by the selected subpackage's methods.  

Please see the POD. documentation for each subpackage for important additional 
information on options and features specific to each site / subpackage!

One or more playable streams can be returned for each station / video / 
podcast, along with at least a "title" (station name / video or podcast 
title) and an icon image URL ("iconurl" - if found).  Additional information 
that MAY be fetched is a (larger?) banner image ("imageurl"), a (longer?) 
"description", an "artist" / author, a "genre", and a "year" (podcasts, 
videos, etc.).  Some sites also provide station's FCC call letters 
("fccid").  For icon and image URLs, functions exist (getIconData() 
and getImageData() to fetch the actual binary data and mime type for 
downloading to local storage for use by your preferred media player.  

If you have another streaming site that is not supported, please file a 
feature request via email or the CPAN bug system, or (for faster service), 
provide a Perl patch module / program source that can extract some or all 
of the necessary information for streams on that site and I'll consider it!  
The easiest way to do this is to take one of the existing submodules, copy 
it to "StreamFinder::I<YOURSITE>.pm and modify it (and the POD docs) to 
your specific site's needs, test it on several of their pages (see the 
"SYNOPSIS" code above), and send it to me (That's what I do)!

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, I<options> ])

Accepts a URL and creates and returns a new station object, or 
I<undef> if the URL is not a valid station or no streams are found.

NOTE:  A full URL must be specified here, but if using any of the 
subpackage modules directly instead, then either a full URL OR just 
the station / video's site ID may be used!  Reason being that this 
function parses the full URL to determine which subpackage (site) 
module to use.

I<options> can vary depending on the type of stream (site) that is 
being queried.  One option common to all sites is I<-debug>, which 
turns on debugging output.  A numeric option can follow specifying 
the level (0, 1, or 2).  0 is none, 1 is basic, 2 is detailed.  
Default:  B<1> (if I<-debug> is specified).

=item $station->B<get>()

Returns an array of strings representing all stream URLs found.

=item $station->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  

Current options are:  I<"random"> and I<"noplaylists">.  By default, the 
first ("best"?) stream is returned.  If I<"random"> is specified, then 
a random one is selected from the list of streams found.  
If I<"noplaylists"> is specified, and the stream to be returned is a 
"playlist" (.pls or .m3u? extension), it is first fetched and the first entry 
in the playlist is returned.  This is needed by Fauxdacious Mediaplayer 
since Fauxdacious intentionally does not allow recursive playlists.

=item $station->B<count>()

Returns the number of streams found for the station.

=item $station->B<getStationID>(['fccid'])

Returns the station's site ID (default), or station's FCC 
call-letters ("fccid") for applicable sites and stations.

=item $station->B<getTitle>(['desc'])

Returns the station's title, or (long description).  

NOTE:  Some sights do not support a separate long description field, 
so if none found, the standard title field will always be returned.

=item $station->B<getIconURL>()

Returns the URL for the station's "cover art" icon image, if any.

=item $station->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.  
This makes it easy to download the image to local storage for use by 
your preferred media player.

=item $station->B<getImageURL>()

Returns the URL for the station's "cover art" banner image, if any.

NOTE:  If no "banner image" (usually a larger image) is found, 
the "icon image" URL will be returned.

=item $station->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual station's banner image 
(binary data).  This makes it easy to download the image to 
local storage for use by your preferred media player.

NOTE:  If no "banner image" (usually a larger image) is found, 
the "icon image" data will be returned.

=item $station->B<getType>()

Returns the station's type (I<submodule-name>).  
(one of:  "Apple", "BannedVideo", "IHeartRadio", "RadioNet", 
"Radionomy", "Reciva", "Tunein", "Youtube" or "Vimeo" - 
depending on the sight that matched the URL.

=back

=head1 CONFIGURATION FILES

=over 4

=item ~/.config/StreamFinder/config

Optional text file for specifying various configuration options.  
Each option is specified on a separate line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used by all sites 
(submodules) that support them.  Valid options include 
I<-debug> => [0|1|2], and most of the L<LWP::UserAgent> options.  
Blank lines and lines starting with a "#" sign are ignored.

=item ~/.config/StreamFinder/I<submodule>/config

Optional text file for specifying various configuration options 
for a specific site (submodule, ie. "Youtube" for 
StreamFinder::Youtube).  Each option is specified on a separate 
line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used only by the specific 
(submodule) specified.  Valid options include 
I<-debug> => [0|1|2], and most of the L<LWP::UserAgent> options.

Options specified here override any specified in I<~/.config/StreamFinder/config>.

=back

NOTE:  Options specified in the options parameter list will override 
those corresponding options specified in these files.

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

youtube-dl (for Brighteon, Tunein, Vimeo)

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder

You can also look for information at:

=head1 SEE ALSO

Fauxdacious media player - (L<https://wildstar84.wordpress.com/fauxdacious>)

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2019 Jim Turner.

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

package StreamFinder;

require 5.001;

use strict;
use warnings;
use vars qw(@ISA @EXPORT $VERSION);

our $VERSION = '1.25';
our $DEBUG = 0;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
my @supported_mods = (qw(Apple BannedVideo Brighteon IHeartRadio RadioNet Radionomy Reciva 
		Tunein Vimeo Youtube));

my %haveit;

foreach my $module (@supported_mods)
{
	$haveit{$module} = 0;
	eval "use StreamFinder::$module; \$haveit{$module} = 1; 1";
}

sub new
{
	my $class = shift;
	my $url = shift;

	my $self = {};
	return undef  unless ($url);

	my @args = @_;
	push @args, ('-debug', $DEBUG)  if ($DEBUG);
	if ($haveit{'BannedVideo'} && $url =~ m#\bbanned\.video\/#) {
		return new StreamFinder::BannedVideo($url, @args);
	} elsif ($haveit{'IHeartRadio'} && $url =~ m#\biheart\.com\/#) {
#		return new StreamFinder::IHeartRadio($url, 'secure_shoutcast', 'secure', 'any', '!rtmp', @args); #DEPRECIATED, USE CONFIG FILE!
		return new StreamFinder::IHeartRadio($url, @args);
	} elsif ($haveit{'Tunein'} && $url =~ m#\btunein\.com\/#) {  #NOTE:ALSO USES youtube-dl!
		return new StreamFinder::Tunein($url, @args);
	} elsif ($haveit{'RadioNet'} && $url =~ m#\bradio\.net\/#) {
		return new StreamFinder::RadioNet($url, @args);
	} elsif ($haveit{'Radionomy'} && $url =~ m#\bradionomy\.com\/#) {
		return new StreamFinder::Radionomy($url, @args);
	} elsif ($haveit{'Reciva'} && $url =~ m#\breciva\.com\/#) {
		return new StreamFinder::Reciva($url, @args);
	} elsif ($haveit{'Brighteon'} && $url =~ m#\bbrighteon\.com\/#) {  #NOTE:ALSO USES youtube-dl!
		return new StreamFinder::Brighteon($url, @args);
	} elsif ($haveit{'Vimeo'} && $url =~ m#\bvimeo\.com\/#) {  #NOTE:ALSO USES youtube-dl!
		return new StreamFinder::Vimeo($url, @args);
	} elsif ($haveit{'Apple'} && $url =~ m#\b(?:podcasts?|music)\.apple\.com\/#) {  #NOTE:ALSO USES youtube-dl!
		return new StreamFinder::Apple($url, @args);
#	} elsif ($haveit{'Facebook'} && ($url =~ m#^http[s]?\:\/\/\w*\.facebook\.#)) {  #REMOVED SUPPORT AS FB NOW LOCKS YOUR ACCOUNT & FORCES PASSWORD CHANGE!
#		return new StreamFinder::Facebook($url, @args);
#	} elsif ($haveit{'Youtube'} && $url =~ m#\b(?:youtube|youtu|yt)\.\/#) {
#		return new StreamFinder::Youtube($url, @args);
	} elsif ($haveit{'Youtube'}) {  #DEFAULT TO youtube-dl SINCE SO MANY URLS ARE HANDLED THERE NOW.
		return new StreamFinder::Youtube($url, @args);
	} else {
		return undef;
	}
}

1