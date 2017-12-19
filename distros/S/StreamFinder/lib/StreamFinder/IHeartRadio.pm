=head1 NAME

StreamFinder::IHeartRadio - Fetch actual raw streamable URLs from radio-station websites on IHeartRadio.com

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

	use StreamFinder::IHeartRadio;

	my $station = new StreamFinder::IHeartRadio(<url>,
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

StreamFinder::IHeartRadio accepts a valid radio station URL on IHeartRadio.com 
and returns the actual stream URL(s) and cover art icon for that station.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the station in one's own choice of audio player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of playing.  The author uses his own custom all-purpose audio player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
media player).  "fauxdacious" can incorporate this module to decode and play 
IHeartRadio.com streams.

One or more stream URLs can be returned for each station.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, I<streamtype> | "debug" [ => 0|1|2 ] ... ])

Accepts an iheartradio.com URL and creates and returns a new station object, or 
I<undef> if the URL is not a valid iheartradio station or no streams are found.

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

Returns the station's FCC call-letters (default) or 
station's IHeartRadio ID.

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

Returns the stream's type ("IHeartRadio").

=back

=head1 KEYWORDS

iheartradio

=head1 DEPENDENCIES

LWP::UserAgent

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-iheartradio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-IHeartRadio>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::IHeartRadio

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-IHeartRadio>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-IHeartRadio>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-IHeartRadio>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-IHeartRadio/>

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

package StreamFinder::IHeartRadio;

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
	my (@okStreams, @skipStreams);
	while (@_) {
		if ($_[0] =~ /^\!/o) {
			(my $i = shift) =~ s/\!//o;
			push @skipStreams, $i;
		} elsif ($_[0] =~ /^debug$/o) {
			shift;
			$DEBUG = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
print STDERR "-???- DEBUG=$DEBUG=\n";
		} else {
			push @okStreams, shift;
		}
	}	
	@okStreams = ('any')  unless (defined $okStreams[0]);  # one of:  {secure_pls | pls | stw}

	my $self = {};

	print STDERR "-0(IHeartRadio): URL=$url=\n"  if ($DEBUG);
	return undef  unless ($url);

	(my $url2fetch = $url);
	$url2fetch = 'https://www.iheart.com/live/' . $url . '/'  unless ($url =~ /^http/);
	$self->{'id'} = $1  if ($url2fetch =~ m#\/([^\/]+)\/$#);
	my $html = '';
	print STDERR "-0(IHeartRadio): URL=$url2fetch=\n"  if ($DEBUG);
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

	my $html2 = '';
	my $streamhtml0 = ($html =~ /\"streams\"\s*\:\s*\{([^\}]+)\}/) ? $1 : '';
	print STDERR "-2: streamhtml=$streamhtml0=\n"  if ($DEBUG);
	return undef  unless ($streamhtml0);

	my ($streamhtml, $streampattern);
	my %streams = ();
	my $weight = 999;

	# OUTTERMOST LOOP TO TRY EACH STREAM-TYPE: (CONSTRAINED IF USER SPECIFIES STREAMTYPES AS EXTRA ARGS TO new())
	foreach my $streamtype (@okStreams) {
print STDERR "--OUTTER: type=$streamtype=\n"  if ($DEBUG);
		$streamhtml = $streamhtml0;
		$streampattern = $streamtype;
		if ($streamtype eq 'secure') {
			$streampattern = '\"secure_\w+';
		} elsif ($streamtype eq 'any') {
			$streampattern = '\"\w+';
		} else {
			$streampattern = '\"' . $streamtype;
		}
		$self->{'cnt'} = 0;
		$self->{'id'} = ($html =~ m#\"id\"\s*\:\s*([^\,\s]+)#) ? $1 : '';
		$self->{'id'} = $1  if (!$self->{'id'} && ($url =~ m#\/([^\/]+)\/?$#));
		$self->{'fccid'} = ($html =~ m#\"callLetters\"\s*\:\s*\"([^\"]+)\"#i) ? $1 : '';
		$self->{'title'} = ($html =~ m#\"description\"\s*\:\s*\"([^\"]+)\"#) ? $1 : $url;
		$self->{'title'} =~ s#http[s]?\:\/\/www\.iheart\.com\/live\/##;
		$self->{'imageurl'} = ($html =~ m#\"image_src\"\s+href=\"([^\"]+)\"#) ? $1 : '';
		$self->{'iconurl'} = $self->{'imageurl'} ? $self->{'imageurl'} . '?ops=fit(100%2C100)' : '';
		# INNER LOOP: MATCH STREAM URLS BY TYPE PATTEREN REGEX UNTIL WE FIND ONE THAT'S ACCEPTABLE (NOT EXCLUDED TYPE):
		print STDERR "-3: PATTERN=${streampattern}_stream=\n"  if ($DEBUG);
INNER:  while ($streamhtml =~ s#(${streampattern}_stream)\"\s*\:\s*\"([^\"]+)\"##)
		{
print STDERR "----INNER: type=$streampattern=\n"  if ($DEBUG);
			$self->{'streamtype'} = substr($1, 1);
			$self->{'streamurl'} = $2;
			foreach my $xp (@skipStreams) {
				next INNER  if ($self->{'streamtype'} =~ /$xp/);  #REJECTED STREAM-TYPE.
			}

			# WE NOW HAVE A STREAM THAT MATCHES OUR CONSTRAINTS:
			# IF IT'S A ".pls" (PLAYLIST) STREAM, WE NEED TO FETCH THE LIST OF ACTUAL STREAMS:
			# streamurl WILL STILL CONTAIN THE PLAYLIST STREAM ITSELF!
			if ($self->{'streamurl'} && $self->{'streamtype'} =~ /pls/) {
				$self->{'plsid'} = $1  if ($self->{'streamurl'} =~ m#\/([^\/]+)\.pls$#i);
				print STDERR "---4: PLS stream id=".$self->{'plsid'}."= URL=".$self->{'streamurl'}."\n"  if ($DEBUG);
				$response = $ua->get($self->{'streamurl'});
				if ($response->is_success) {
					$html = $response->decoded_content;
				} else {
					$html = '';
					print STDERR $response->status_line  if ($DEBUG);
				}
				while ($html =~ s#File\d+\=(\S+)##) {
					#push @streams, $1;
					$streams{$1} = $weight  unless (defined $streams{$1});
					print STDERR "-----5: Adding PLS stream ($1) ($weight)!\n"  if ($DEBUG);
					++$self->{'cnt'};
					--$weight;
				}
			}
			else  #NON-pls STREAM, WE'LL HAVE A LIST CONTAINING A SINGLE STREAM:
			{
				#push @streams, $self->{'streamurl'};
				$streams{$self->{'streamurl'}} = $weight  unless (defined $streams{$self->{'streamurl'}});
				#$self->{'streams'} = [$self->{'streamurl'}];
				print STDERR "-----6: Adding ".$self->{'streamtype'}." stream (".$self->{'streamurl'}.") ($weight)!\n"  if ($DEBUG);
				++$self->{'cnt'};
				--$weight
			}
		}
		last  if ($streamtype eq 'any');  #"any" SHOULD ALWAYS BE THE LAST ONE TO TRY!
		$weight -= 100;
	}
	return undef  unless ($self->{'cnt'});   #STEP 2 FAILED - NO PLAYABLE STREAMS FOUND, PUNT!

	#$self->{'streams'} = \@streams;  #WE'LL HAVE A LIST OF 'EM TO RANDOMLY CHOOSE ONE FROM:
	#$self->{'total'} = $self->{'cnt'};
	$self->{'total'} = 0;
	foreach my $s (sort {$streams{$b} <=> $streams{$a}} keys %streams) {
		push @{$self->{'streams'}}, $s;
		print STDERR "++++ ADDING STREAM(".$streams{$s}."): $s\n"  if ($DEBUG);
		++$self->{'total'};
	}
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
	return 'IHeartRadio';  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
}

sub getID
{
	my $self = shift;
	return $self->{'id'} || $self->{'fccid'}  if (defined($_[0]) && $_[0] !~ /fcc/i);
	return $self->{'fccid'} || $self->{'id'};  #URL TO THE STATION'S CALL LETTERS OR IHEART-ID.
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
