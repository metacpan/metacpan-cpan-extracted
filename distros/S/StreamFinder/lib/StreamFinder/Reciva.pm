=head1 NAME

StreamFinder::Reciva - Fetch actual raw streamable URLs from radio-station websites on Reciva.com

=head1 AUTHOR

This module is Copyright (C) 2017 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	use strict;

	use StreamFinder::Reciva;

	my $station = new StreamFinder::Reciva(<url>);

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

StreamFinder::Reciva accepts a valid radio station URL on radios.reciva.com and
returns the actual streamurl and cover art icon for that station.  
The purpose is that one needs one of these URLs 
in order to have the option to stream the station in one's own choice of 
audio player software rather than using their web browser and accepting any / 
all flash, ads, javascript, cookies, trackers, web-bugs, and other crapware 
that can come with that method of playing.  The author uses his own custom 
all-purpose audio player called "fauxdacious" (his custom hacked version of 
the open-source "audacious" media player.  "fauxdacious" incorporates this 
module to decode and play reciva.com streams.

StreamFinder::Reciva accepts a valid radio station URL on radios.reciva.com and 
returns the actual stream URL(s) and cover art icon for that station.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the station in one's own choice of audio player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of playing.  The author uses his own custom all-purpose audio player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
media player).  "fauxdacious" can incorporate this module to decode and play 
reciva.com streams.

One or more streams can be returned for each station.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, "debug" [ => 0|1|2 ]])

Accepts a reciva.com URL and creates and returns a new station object, or 
I<undef> if the URL is not a valid reciva station or no streams are found.
The url can be the full URL, ie. https://radios.reciva.com/station/55952, 
or just the station ID:  55952.

=item $station->B<get>()

Returns an array of strings representing all stream urls found.

=item $station->B<getURL>()

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  

=item $station->B<count>()

Returns the number of streams found for the station.

=item $station->B<getID>()

Returns the station's Reciva ID (numeric).

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

Returns the stream's type ("Reciva").

=back

=head1 KEYWORDS

reciva

=head1 DEPENDENCIES

LWP::UserAgent

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-reciva at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Reciva>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Reciva

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Reciva>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Reciva>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Reciva>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Reciva/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jim Turner.

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

package StreamFinder::Reciva;

use strict;
use warnings;
use LWP::UserAgent ();
use vars qw(@ISA @EXPORT $VERSION);

our $VERSION = '1.00';
our $DEBUG = 0;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(get getURL getType getID getTitle getIconURL getIconData getImageURL getImageData);

sub new
{
	my $class = shift;
	my $url = shift;
	while (@_) {
		if ($_[0] =~ /^debug$/o) {
			shift;
			$DEBUG = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
		}
	}	

	my $self = {};
	return undef  unless ($url);

	$url = 'https://radios.reciva.com/station/' . $url  unless ($url =~ /^http/);
	(my $url2fetch = $url) =~ s#station\/(\d+).*$#streamer\?stationid\=$1\&streamnumber=0#;
	$self->{'id'} = $1;
	my $html = '';
	print STDERR "-0(Reciva): URL=$url2fetch=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new;		
	$ua->timeout(10);
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html);  #STEP 1 FAILED, INVALID STATION URL, PUNT!
	$self->{'iconurl'} = ($html =~ m#stationid\=\"\d+\"\s+href\=\"\/station\/\d+\"\>\s*\<img\s+src\=\"([^\"]*)#) ? $1 : '';
	$self->{'imageurl'} = $self->{'iconurl'};

	my @streams;
	$html = '';
	print STDERR "-3: url2=$url2fetch=\n"  if ($DEBUG);
	return undef  unless ($url2fetch);
	$response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-4: html2=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html);  #STEP 1 FAILED, INVALID STATION URL, PUNT!

	$self->{'cnt'} = 0;
	$self->{'title'} = ($html =~ m#Playing:\s*([^\<]+)#) ? $1 : '';
	my $stream = '';
	my $plshtml = '';
	while ($html =~ s/\<iframe\s+src\=\"(\w+\:\/[^\"]+)//io) {  #FIND ONE (OR MORE) STREAM URLS:
		$stream = $1;
		if ($stream =~ /\.pls/io) {
			$response = $ua->get($stream);
			if ($response->is_success) {
				$plshtml = $response->decoded_content;
			} else {
				$html = '';
				print STDERR $response->status_line  if ($DEBUG);
			}
			while ($plshtml =~ s#File\d+\=(\S+)##) {
				print STDERR "-----5: Adding PLS stream ($1)!\n"  if ($DEBUG);
				push @streams, $1;
				++$self->{'cnt'};
			}
		} else {
			print STDERR "-----5: Adding stream ($stream) !\n"  if ($DEBUG);
			push @streams, $1;
			++$self->{'cnt'};   #NUMBER OF Streams FOUND
		}
	}
	while ($html =~ s/\<a\s+id\=\"livestreams\"\s+class\=\"live\"\s+onclick\="iframe\(\'(\w+\:\/[^\']+)//o) {  #FIND ONE (OR MORE) STREAM URLS:
		$stream = $1;
		if ($stream =~ /\.pls/io) {
			$response = $ua->get($stream);
			if ($response->is_success) {
				$plshtml = $response->decoded_content;
			} else {
				$html = '';
				print STDERR $response->status_line  if ($DEBUG);
			}
			while ($plshtml =~ s#File\d+\=(\S+)##) {
				print STDERR "-----6: Adding PLS stream ($1)!\n"  if ($DEBUG);
				push @streams, $1;
				++$self->{'cnt'};
			}
		} else {
			print STDERR "-----6: Adding stream ($1) !\n"  if ($DEBUG);
			push @streams, $1;
			++$self->{'cnt'};   #NUMBER OF Streams FOUND
		}
	}
	print STDERR "-count=".$self->{'cnt'}."= iconurl=".$self->{'iconurl'}."=\n"  if ($DEBUG);
	return undef  unless ($self->{'cnt'});   #STEP 2 FAILED - NO PLAYABLE STREAMS FOUND, PUNT!

	$self->{'total'} = $self->{'cnt'};
	$self->{'streams'} = \@streams;
	print STDERR "-SUCCESS: 1st stream=".${$self->{'streams'}}[0]."=\n"  if ($DEBUG);
	bless $self, $class;   #BLESS IT!

	return $self;
}

sub get
{
	my $self = shift;

	return wantarray ? @{$self->{'streams'}} : ${$self->{'streams'}}[0];
}

sub getURL   #LIKE GET, BUT ONLY RANDOMLY SELECT ONE TO RETURN:
{
	my $self = $_[0];
	my $streamNumber = int rand scalar @{$self->{'streams'}};
	$streamNumber = $#{$self->{'streams'}}  if ($streamNumber > $#{$self->{'streams'}});
	$streamNumber = scalar(@{$self->{'streams'}}) + $streamNumber  if ($streamNumber < 0);
	$streamNumber = 0  if ($streamNumber < 0);
	return ${$self->{'streams'}}[$streamNumber];  #URL TO RANDOM PLAYABLE STREAM.
}

sub count
{
	my $self = shift;
	return $self->{'total'};  #TOTAL NUMBER OF PLAYABLE STREAM URLS FOUND.
}

sub getType
{
	my $self = shift;
	return 'Reciva';  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
}

sub getID
{
	my $self = shift;
	return $self->{'id'};  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
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
