=head1 NAME

StreamFinder::Subsplash - Fetch actual raw streamable URLs on subsplash.com

=head1 AUTHOR

This module is Copyright (C) 2021-2024 by

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

StreamFinder::Subsplash accepts a valid podcast (sermon) ID or URL on 
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

=item B<new>(I<ID>|I<url> [, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ]])

Accepts a subsplash.com podcast (sermon) ID or URL and creates and returns a 
a new podcast object, or I<undef> if the URL is not a valid podcast, or no streams 
are found.  The URL can be the full URL, ie. 
https://subsplash.com/B<channel>/embed/mi/B<id>, or just 
I<channel>/B<id>.

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
[site]:  The site name (Subsplash).  [url]:  The url searched for streams.  
[time]: Perl timestamp when the line was logged.  [title], [artist], [album], 
[description], [year], [genre], [total], [albumartist]:  The corresponding field data 
returned (or "I<-na->", if no value).

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

=item $podcast->B<getIconURL>()

Returns the URL for the podcast's "cover art" icon image, if any.

=item $podcast->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.

=item $podcast->B<getImageURL>()

Returns the URL for the podcast's "cover art" (usually larger) 
banner image.

=item $podcast->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual podcast's banner image (binary data).

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

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-iheartradio at rt.cpan.org>, or through
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

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Subsplash>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Subsplash/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2021-2024 Jim Turner.

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

	$url =~ s#\\##g;
	my $url2fetch = HTML::Entities::decode_entities($url);
	my $channel = '';
	if ($url =~ /^https?\:/) {
		$self->{'id'} = "$1/$2"  if ($url2fetch =~ m#\/\+?([\-a-z0-9]+)\/(?:embed|media)\/m\w\/\+?([\-a-z0-9]+)#i);
		unless ($self->{'id'}) {
			my $url_x = $url2fetch;
			$self->{'id'} = $1  if ($url_x =~ s#\/\+?([a-z0-9]+)##);
			$self->{'id'} .= "/$1"  if ($url_x =~ s#\/\+?([\-a-z0-9]+)##);
		}
		($channel = $url2fetch) =~ s#\/(?:embed|media)\/.+$##;
	} else {
		$self->{'id'} = $url;
		my ($channelID, $id) = split(m#\/#, $url);
		$url2fetch = "https://subsplash.com/$channelID";
		$channel = $url2fetch;
		$url2fetch .= '/embed/mi/' . $id  if ($id);
	}
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
	return undef  unless ($html && $self->{'id'} && $self->{'id'} =~ m#\/#);  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!

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
	$self->{'albumartist'} = $channel;
	my %dups = ();
	my $stream = '';
	foreach my $tag ('video', 'audio') {
		if ($html =~ s#\<$tag\s+preload(.+?)\<\/$tag\>##s) {
			my $stuff = $1;
			$stream = $1  if ($stuff =~ m#\<source\s+src\=\"([^\"]+)#);
			unless (!$stream || ($self->{'secure'} && $stream !~ /^https/o)) {
				push @{$self->{'streams'}}, $stream;
				$self->{'cnt'}++;
			}
		}
	}

	return undef  unless ($self->{'cnt'} > 0);

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
			$self->{'imageurl'} = $self->{'iconurl'};
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
		my $copyright = $1;
		$self->{'year'} = $1  if ($copyright =~ /(\d\d\d\d)/);
	} elsif ($html =~ s#app\_\_footer\-copyright\"\>(.+)?\<\/div\>##s) {
		my $date = $1;
		$self->{'year'} = $1  if ($date =~ /(\d\d\d\d)/);
	}
	if ($html =~ m#\<div\s+class\=\"route\-media\-item\_\_basic\-info\"\>(.+?)\<\/div\>#s) {
		my $addtl = $1;
		if ($addtl =~ m#\<p\>\s*(.+?)\<\/p\>#s) {
			my $stuff = $1;
			if ($stuff =~ s#^\s*(.+?\d\d\d\d)##) {
				$self->{'created'} = $1;
				$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
				($self->{'artist'} = $stuff) =~ s#^[^\w]+##;
				$self->{'artist'} =~ s/\s+$//;
			}
		}
	} elsif ($html =~ s#kit\-player\_\_info\-text\-\-additional\"\>(.+?)\<\/div\>##s) { ## DEPRECIATED? ##:
		$self->{'artist'} = $1;
		$self->{'artist'} =~ s/^\s+//s;
		$self->{'artist'} =~ s/\s+$//s;
	}
	if ($html =~ m#\<div\s+class\=\"route\-media\-item\_\_more\-items\-title\"(.+?)\<\/div\>#s) {
		my $addtl = $1;
		if ($addtl =~ m#\<a[^\>]+\>\s*(.+?)\<\/a\>#s) {
			($self->{'album'} = $1) =~ s/\s+$//;
		}
	}
	foreach my $field (qw(title description artist)) {
		$self->{$field} = HTML::Entities::decode_entities($self->{$field});
		$self->{$field} = uri_unescape($self->{$field});
		$self->{$field} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	}
	$self->{'total'} = $self->{'cnt'};
	$self->{'id'} =~ s/[\+\-]//g;
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
