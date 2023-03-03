=head1 NAME

StreamFinder::Goodpods - Fetch actual raw streamable URLs on goodpods.com

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

	use StreamFinder::Goodpods;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $podcast = new StreamFinder::Goodpods($ARGV[0]);

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
	
	my $artist = $podcast->{'artist'};

	print "Artist=$artist\n"  if ($artist);
	
	my $genre = $podcast->{'genre'};

	print "Genre=$genre\n"  if ($genre);
	
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

StreamFinder::Goodpods accepts a valid podcast ID or URL on 
goodpods.com and returns the actual stream URL(s), title, and cover art icon.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the podcast in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of play.  The author uses his own custom all-purpose media player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
goodpods.com streams.

One or more stream URLs can be returned for each podcast.

NOTE:  Unlike many other playlist sites StreamFinder supports, Goodpods does 
not currently support fetching podcast (channel) pages and returning a 
playlist of episodes or the first episode - only individual episode pages are 
currently supported (The podcast-ID must include both podcast and episode ID 
separated by a slash ("/").

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ]])

Accepts a goodpods.com podcast ID or URL and creates and returns a 
a new podcast object, or I<undef> if the URL is not a valid podcast, or no streams 
are found.  The URL can be the full URL, ie. 
https://goodpods.com/podcasts/B<podcast-id#>/B<episode-id#>, or just 
B<podcast-id#>/B<episode-id#>.

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  If 1 
then only secure ("https://") streams will be returned.

DEFAULT I<-secure> is 0 (false) - return all streams (http and https).

Additional options:

I<-log> => "I<logfile>"

Specify path to a log file.  If a valid and writable file is specified, A line will be 
appended to this file every time one or more streams is successfully fetched for a url.

DEFAULT I<-none-> (no logging).

I<-logfmt> specifies a format string for lines written to the log file.

DEFAULT "I<[time] [url] - [site]: [title] ([total])>".  

The valid field I<[variables]> are:  [stream]: The url of the first/best stream found.  
[site]:  The site name (Goodpods).  [url]:  The url searched for streams.  
[time]: Perl timestamp when the line was logged.  [title], [artist], [album], 
[description], [year], [genre], [total], [albumartist]:  The corresponding field data 
returned (or "I<-na->", if no value).

=item $podcast->B<get>()

Returns an array of strings representing all stream URLs found.
NOTE:  Goodpods does not currently support returning a playlist.

=item $podcast->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  There currently are no valid I<options>.

=item $podcast->B<count>()

Returns the number of streams found for the podcast.

=item $podcast->B<getID>()

Returns the podcast's Goodpods ID (default).  For podcasts, the Goodpods ID 
is a single value.  For individual podcast episodes it's two values 
separated by a slash ("/").

=item $podcast->B<getTitle>(['desc'])

Returns the podcast's title, or (long description).  Podcasts 
on Goodpods can have separate descriptions, but for podcasts, 
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

=item $podcast->B<getImageURL>()

Returns the URL for the podcast's "cover art" (usually larger) 
banner image.

=item $podcast->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual podcast's banner image (binary data).

=item $podcast->B<getType>()

Returns the podcast's type ("Goodpods").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/Goodpods/config

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

podcastaddict

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-iheartradio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Goodpods>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Goodpods

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Goodpods>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Goodpods>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Goodpods>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Goodpods/>

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

package StreamFinder::Goodpods;

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

	my $self = $class->SUPER::new('Goodpods', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});
	$self->{'id'} = '';
	(my $url2fetch = $url);
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $html = '';
	my $response;

	if ($url =~ /^https?\:/) {
		$self->{'id'} = $1  if ($url =~ m#\/([a-z\-]+\d+\/[a-z\-]+\d+)\/?$#);
	} else {
		$self->{'id'} = $url;
		$url2fetch = 'https://goodpods.com/podcasts/' . $url;
	}
	unless ($self->{'id'} =~ m#\d+\/[a-z\-]+\d+#) {
		print STDERR "e:".$self->{'id'}." is not a valid Goodpods episode ID!\n";
		return undef;
	}

	$html = '';
	print STDERR "-0(Goodpods): FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	$response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html);  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!

	$self->{'genre'} = 'Podcast';  #Goodpods.com DOES NOT CURRENTLY INCLUDE A GENRE/CATEGORY.
	print STDERR "---ID=".$self->{'id'}."=\n"  if ($DEBUG);
	$self->{'title'} = $1  if ($html =~ m#\,\"title\"\:\"([^\"]+)#s);
	$self->{'title'} ||= $1  if ($html =~ m#\<title\>(.+?)\<\/title\>#si);
	$self->{'title'} ||= $1  if ($html =~ m#\<meta\s+property\=\"og\:title\"\s+content\=\"([^\"]+)#s);
	$self->{'iconurl'} = $1  if ($html =~ m#\<meta\s+property\=\"og\:image\"\s+content\=\"([^\"]+)#s);
	$self->{'iconurl'} ||= $1  if ($html =~ m#\,\"image\"\:\"([^\"]+)#s);
	($self->{'albumartist'} = 'https://goodpods.com/podcasts/'.$self->{'id'}) =~ s#\/[^\/]+$##;
	#NOTE:  Goodpods.com DOES NOT (USUALLY) INCLUDE THE PODCAST ARTIST'S NAME IN EPISODE PAGES, 
	#SO WE PUT THE PODCAST NAME IN THE ARTIST FIELD (WHICH WOULD NORMALLY GO IN THE ALBUM FIELD)!
	#(FOR REFERENCE, NORMALLY THE "ARTIST" IS THE PODCAST'S ARTIST'S NAME, AND ALBUM IS THE 
	#PODCAST'S NAME (AN ARTIST CAN HAVE MULTIPLE PODCASTS & A PODCAST CAN HAVE MULT. EPISODES)!):
	if ($html =~ m#\,\"parent_podcast_artist\"\:\"([^\"]+)#s) { #RARE CASE, WE HAVE ARTIST'S NAME!:
		$self->{'artist'} = $1;
		$self->{'album'} ||= $1  if ($html =~ m#\,\"parent_podcast_title\"\:\"([^\"]+)#s);
	} else {
		$self->{'artist'} ||= $1  if ($html =~ m#\,\"parent_podcast_title\"\:\"([^\"]+)#s);
	}
	$self->{'description'} = $1  if ($html =~ m#\,\"description\"\:\"([^\"]+)#s);
	$self->{'description'} ||= $1  if ($html =~ m#\<meta\s+name\=\"description\"\s+content\=\"([^\"]+)#s);
	$self->{'description'} ||= $1  if ($html =~ m#\<meta\s+property\=\"og\:description\"\s+content\=\"([^\"]+)#s);
	if ($html =~ m#\,\"pub_date\"\:\"([^\"]+)#s) {
		$self->{'created'} = $1;
		$self->{'year'} = ($self->{'created'} =~ /(\d\d\d\d)/) ? $1 : '';
	}
	$self->{'imageurl'} = $self->{'iconurl'}; #Goodpods.com DOES NOT SUPPORT A SEPARATE BANNER IMAGE.
	#NOW FETCH ANY STREAMS:
	my $protocol = $self->{'secure'} ? '' : '?';
	my ($audiostream, $videostream);  #HAVEN'T SEEN ANY VIDEO ONES YET, BUT THEY MIGHT HAVE SOME? (SO WE TRY):
	$audiostream = $1  if ($html =~ m#\<meta\s+property\=\"og\:audio\"\s+content\=\"(https${protocol}\:[^\"]+)#s);
	$videostream = $1  if ($html =~ m#\<meta\s+property\=\"og\:video\"\s+content\=\"(https${protocol}\:[^\"]+)#s);
	$audiostream = $1  if (!defined($audiostream) && $html =~ m#\,\"audio_url\"\:\"(https${protocol}\:[^\"]+)#s);
	$videostream = $1  if (!defined($videostream) && $html =~ m#\,\"video_url\"\:\"(https${protocol}\:[^\"]+)#s);
	push (@{$self->{'streams'}}, $videostream)  if (defined $videostream);
	push (@{$self->{'streams'}}, $audiostream)  if (defined $audiostream);
	$self->{'total'} = $self->{'cnt'} = scalar @{$self->{'streams'}};

	print STDERR "-(all)count=".$self->{'total'}."= ID=".$self->{'id'}."= iconurl="
			.$self->{'iconurl'}."= TITLE=".$self->{'title'}."= DESC=".$self->{'description'}
			."= YEAR=".$self->{'year'}."= ICON=".$self->{'iconurl'}."=\n"  if ($DEBUG);
	return undef  unless ($self->{'cnt'} > 0);

	$self->_log($url);     #LOG IT.

	bless $self, $class;   #BLESS IT!

	return $self;
}

#Goodpods.com DOES NOT INCLUDE THE ARTIST (CHANNEL)'S ICON IMAGE IN EPISODE
#PAGES, SO IF USER ASKS FOR IT, WE HAVE TO FETCH THE CHANNEL'S PAGE TO GET IT:
sub getIconURL
{
	my $self = shift;
	return $self->{'iconurl'}  unless (defined($_[0]) && $_[0] =~ /^\-?artist/i);

	unless ($self->{'articonurl'}) {
		my $html = '';
		return ''  unless ($self->{'albumartist'} && $self->{'albumartist'} =~ m#^https?\:\/\/#);

		my $url2fetch = $self->{'albumartist'};
		print STDERR "-0(Fetch Goodpods channel page for art. icon from $url2fetch): \n"  if ($DEBUG);
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

		$self->{'articonurl'} = ($html =~ m#\<meta\s+property\=\"og\:image\"\s+content\=\"([^\"]+)#s) ? $1 : '';
		print STDERR "--ART ICON URL=".$self->{'articonurl'}."=\n"  if ($DEBUG);
	}
	return $self->{'articonurl'};
}

1
