=head1 NAME

StreamFinder::Facebook - Fetch actual raw streamable URLs from videos on facebook.com

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

	use StreamFinder::Facebook;

	my $station = new StreamFinder::Facebook(<url>);

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

StreamFinder::Facebook accepts a valid Facebook video URL and
returns the actual stream URL for that video.  The purpose is that one needs 
this URL in order to have the option to stream the video in one's own choice 
of audio player software rather than using their web browser and accepting 
any / all flash, ads, javascript, cookies, trackers, web-bugs, and other 
crapware that can come with that method of playing.  The author uses his own 
custom all-purpose media player called "fauxdacious" (his custom hacked 
version of the open-source "audacious" audio player).  "fauxdacious" can 
incorporate this module to decode and play Facebook.com videos.

NOTE:  You must create the hidden file: ~/.config/.fbdata consisting of two 
lines:  the first containing your Facebook login id, ie. 
youremail\@emailservice.com; and the second line, your Facebook password!

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, "debug" [ => 0|1|2 ]])

Accepts a facebook.com URL and creates and returns a new station object, or 
I<undef> if the URL is not a valid facebook station or no streams are found.

=item $station->B<get>()

Returns an array of strings representing all stream urls found.

=item $station->B<getURL>()

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  

=item $station->B<count>()

Returns the number of streams found for the video.

=item $station->B<getID>()

Returns the video's Facebook ID (numeric).

=item $station->B<getTitle>()

Returns the video's title (description).  

=item $station->B<getIconURL>()

Returns the url for the video's "cover art" icon image, if any.

=item $station->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc. and the actual icon image (binary data), if any.

=item $station->B<getImageURL>()

Returns the url for the video's "cover art" banner image.

=item $station->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc. and the actual station's banner image (binary data).

=item $station->B<getType>()

Returns the stream's type ("Facebook").

=back

=head1 KEYWORDS

facebook

=head1 DEPENDENCIES

youtube-dl
LWP::UserAgent

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-facebook at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Facebook>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Facebook

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Facebook>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Facebook>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Facebook>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Facebook/>

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

package StreamFinder::Facebook;

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
	while (@_) {
		if ($_[0] =~ /^\-?debug$/o) {
			shift;
			$DEBUG = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
		}
	}	

	my $self = {};
	return undef  unless ($url);

	my $fbid = '';
	my $fbpw = '';
	if (open (IN, "<$ENV{HOME}/.config/.fbdata")) {  #FACEBOOK REQUIRES YOUR LOGIN CRADENTIALS!
		$fbid = <IN>;
		chomp $fbid;
		$fbpw = <IN>;
		chomp $fbpw;
		close IN;
	}
	return undef  unless ($fbid && $fbpw);
	print STDERR "-0(Facebook): URL=$url=\n"  if ($DEBUG);

	my $meta_data = '';
	my %metadata;
	$self->{'id'} = $1  if ($url =~ m#\/(\d+)\/?$#);
	$self->{'artist'} = $1  if ($url =~ m#\/(\w+)\/videos#);
	$self->{'title'} = 'Facebook';
	$_ = `youtube-dl --username "$fbid" --password "$fbpw" --get-url --get-thumbnail -f mp4 "$url"`;
	print STDERR "--cmd=facebook-dl --username \"$fbid\" --password \"$fbpw\" --get-url --get-thumbnail -f mp4 \"$url\"=\n"  if ($DEBUG);
	my @urls = split(/\r?\n/);
	while (@urls && $urls[0] !~ m#\:\/\/#o) {
		shift @urls;
	}
	return undef  unless ($urls[0]);
	$self->{'Url'} = $urls[0];
	chomp $self->{'Url'};
	$self->{'streams'} = [$self->{'Url'}];
	$self->{'cnt'} = 1;
	$self->{'total'} = $self->{'cnt'};
	$self->{'iconurl'} = ($#urls >= 1) ? $urls[$#urls] : '';
	print STDERR "-count=".$self->{'cnt'}."= iconurl=".$self->{'iconurl'}."=\n"  if ($DEBUG);
	print STDERR "--SUCCESS: stream url=".$self->{'Url'}."=\n"  if ($DEBUG);

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub get
{
	my $self = shift;

	return wantarray ? @{$self->{'streams'}} : $self->{'Url'};
}

sub getURL   #LIKE GET, BUT ONLY RETURN THE SINGLE ONE W/BEST BANDWIDTH AND RELIABILITY:
{
	my $self = shift;
	return $self->{'Url'};
}

sub count
{
	my $self = shift;
	return $self->{'total'};  #TOTAL NUMBER OF PLAYABLE STREAM URLS FOUND.
}

sub getType
{
	my $self = shift;
	return 'Facebook';  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
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
	return $self->getIconData();
}

1
