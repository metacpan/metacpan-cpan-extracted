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

	my $video = new StreamFinder::Facebook(<url>);

	die "Invalid URL or no streams found!\n"  unless ($video);

	my $firstStream = $video->get();

	print "First Stream URL=$firstStream\n";

	my $url = $video->getURL();

	print "Stream URL=$url\n";

	my $videoTitle = $video->getTitle();
	
	print "Title=$videoTitle\n";
	
	my $videoID = $video->getID();

	print "Video ID=$videoID\n";
	
	my $stream_count = $video->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $video->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::Facebook accepts a valid Facebook video URL and
returns the actual stream URL and title for that video.  The purpose is that 
one needs this URL in order to have the option to stream the video in one's 
own choice of media player software rather than on Facebook using their web 
browser and accepting any / all flash, ads, javascript, cookies, trackers, 
web-bugs, and other crapware that can come with that method of playing.  
The author uses his own custom all-purpose media player called "fauxdacious" 
(his custom hacked version of the open-source "audacious" audio player).  
"fauxdacious" can incorporate this module to decode and play 
Facebook.com videos.

NOTE:  You must create the config file: ~/.config/StreamFinder/Facebook/config 
containing the two lines:  

userid => 'yourFBlogin'

userpw => 'yourpassword'

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, "debug" [ => 0|1|2 ]])

Accepts a facebook.com URL and creates and returns a new video object, or 
I<undef> if the URL is not a valid facebook video or no streams are found.

=item $video->B<get>()

Returns an array of strings representing all stream urls found.

=item $video->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  

There are currently no I<options> supported for Facebook streams, anything 
specified here is currently ignored as there is currently only a single 
playable stream returned.

=item $video->B<count>()

Returns the number of streams found for the video.

=item $video->B<getID>()

Returns the video's Facebook ID (numeric).

=item $video->B<getTitle>()

Returns the video's title (description).  

=item $video->B<getIconURL>()

Returns the url for the video's "cover art" icon image, if any.

NOTE:  Not currently applicable to Facebook videos.

=item $video->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc. and the actual icon image (binary data), if any.

NOTE:  Not currently applicable to Facebook videos.

=item $video->B<getImageURL>()

Returns the url for the video's "cover art" banner image.

NOTE:  Not currently applicable to Facebook videos.

=item $video->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc. and the actual video's banner image (binary data).

NOTE:  Not currently applicable to Facebook videos.

=item $video->B<getType>()

Returns the video's type ("Facebook").

=back

=head1 CONFIGURATION FILES

NOTE:  If you are still using the old hidden text file: ~/.config/.fbdata, 
it will still work for now, but will eventually be REMOVED in a future 
release.  If you have both this file and the above specified in the new 
config file, the latter will overwrite the .fbdata values.

=over 4

=item ~/.config/StreamFinder/Facebook/config

Optional text file for specifying various configuration options 
for a specific site (submodule).  Each option is specified on a 
separate line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used only by the specific 
(submodule) specified.  Valid options include 
I<-debug> => [0|1|2], and most of the L<LWP::UserAgent> options.  
Blank lines and lines starting with a "#" sign are ignored.

Options specified here override any specified in I<~/.config/StreamFinder/config>.

Among options valid for Facebook streams are the I<-userid> and 
I<-userpw> options specifying the required Facebook login 
cradentials (formally stored in ~/.config/.fbdata).

=item ~/.config/StreamFinder/config

Optional text file for specifying various configuration options.  
Each option is specified on a separate line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used by all sites 
(submodules) that support them.  Valid options include 
I<-debug> => [0|1|2], and most of the L<LWP::UserAgent> options.

=back

NOTE:  Options specified in the options parameter list will override 
those corresponding options specified in these files.

=head1 KEYWORDS

facebook

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>, youtube-dl

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

my $DEBUG = 0;
my %uops = ();
my @userAgentOps = ();

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(get getURL getType getID getTitle getIconURL getIconData getImageURL getImageData);

sub new
{
	my $class = shift;
	my $url = shift;

	my $self = {};
	return undef  unless ($url);

	foreach my $p ("$ENV{HOME}/.config/StreamFinder/config", "$ENV{HOME}/.config/StreamFinder/Facebook/config") {
		if (open IN, $p) {
			my ($atr, $val);
			while (<IN>) {
				chomp;
				next  if (/^\s*\#/o);
				($atr, $val) = split(/\s*\=\>\s*/o, $_, 2);
				eval "\$uops{$atr} = $val";
			}
			close IN;
		}
	}
	foreach my $i (qw(agent from conn_cache default_headers local_address ssl_opts max_size
			max_redirect parse_head protocols_allowed protocols_forbidden requests_redirectable
			proxy no_proxy)) {
		push @userAgentOps, $i, $uops{$i}  if (defined $uops{$i});
	}
	push (@userAgentOps, 'agent', 'Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0')
			unless (defined $uops{'agent'});
	$uops{'timeout'} = 10  unless (defined $uops{'timeout'});
	$DEBUG = $uops{'debug'}  if (defined $uops{'debug'});

	while (@_) {
		if ($_[0] =~ /^\-?debug$/o) {
			shift;
			$DEBUG = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
		}
	}	

	my $fbid = '';
	my $fbpw = '';
	#DEPRECIATED:  USE $ENV{HOME}/.config/StreamFinder/Facebook/config!:
	if (open (IN, "<$ENV{HOME}/.config/.fbdata")) {  #FACEBOOK REQUIRES YOUR LOGIN CRADENTIALS!
		$fbid = <IN>;
		chomp $fbid;
		$fbpw = <IN>;
		chomp $fbpw;
		close IN;
	}
	#END DEPRECIATED

	$fbid = $uops{'userid'}  if (defined $uops{'userid'});
	$fbpw = $uops{'userpw'}  if (defined $uops{'userpw'});
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
	return 'Facebook';  #STATION TYPE (FOR PARENT StreamFinder MODULE).
}

sub getID
{
	my $self = shift;
	return $self->{'id'};  #VIDEO'S FACEBOOK-ID.
}

sub getTitle
{
	my $self = shift;
	return $self->{'title'};  #VIDEO'S TITLE(DESCRIPTION), IF ANY.
}

sub getIconURL
{
	my $self = shift;
	return $self->{'iconurl'};  #URL TO THE VIDEO'S THUMBNAIL ICON, IF ANY.
}

sub getIconData
{
	my $self = shift;
	return ()  unless ($self->{'iconurl'});
	my $ua = LWP::UserAgent->new(@userAgentOps);
	$ua->timeout($uops{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $art_image = '';
	my $response = $ua->get($self->{'iconurl'});
	if ($response->is_success) {
		$art_image = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
		my $no_wget = system('wget','-V');
		unless ($no_wget) {
			print STDERR "\n..trying wget...\n"  if ($DEBUG);
			my $iconUrl = $self->{'iconurl'};
			$art_image = `wget -t 2 -T 20 -O- -o /dev/null \"$iconUrl\" 2>/dev/null `;
		}
	}
	return ()  unless ($art_image);
	(my $image_ext = $self->{'iconurl'}) =~ s/^.+\.//;
	$image_ext =~ s/[^A-Za-z].*$//;
	return ($image_ext, $art_image);
}

sub getImageURL
{
	my $self = shift;
	return $self->{'imageurl'};  #URL TO THE VIDEO'S BANNER IMAGE, IF ANY.
}

sub getImageData
{
	my $self = shift;
	return $self->getIconData();
}

1
