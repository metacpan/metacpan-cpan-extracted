=head1 NAME

StreamFinder::InternetRadio - Fetch actual raw streamable URLs from radio-station websites on Internet-radio.com

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

	use StreamFinder::InternetRadio;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $station = new StreamFinder::InternetRadio($ARGV[0]);

	die "Invalid URL or no streams found!\n"  unless ($station);

	my $firstStream = $station->get();

	print "First Stream URL=$firstStream\n";

	my $url = $station->getURL();

	print "Stream URL=$url\n";

	my $stationTitle = $station->getTitle();
	
	print "Title=$stationTitle\n";
	
	my $stationDescription = $station->getTitle('desc');
	
	print "Title=$stationDescription\n";
	
	my $stationID = $station->getID();

	print "Station ID=$stationID\n";
	
	my $genre = $station->{'genre'};  #NOTE: MAY RETURN A COMMA-SEPARATED LIST.

	print "Genre=$genre\n"  if ($genre);
	
	my $stream_count = $station->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $station->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::InternetRadio accepts a valid radio station ID or URL on 
Internet-radio.com and returns the actual stream URL(s), and title for that 
station.  The purpose is that one needs one of these URLs in order to have the 
option to stream the station in one's own choice of media player software 
rather than using their web browser and accepting any / all flash, ads, 
javascript, cookies, trackers, web-bugs, and other crapware that can come with 
that method of play.  The author uses his own custom all-purpose media player 
called "fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
Internet-radio.com streams.

One or more streams can be returned for each station.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-notrim> [ => 0|1 ]] [, I<-secure> [ => 0|1 ]]
[, I<-debug> [ => 0|1|2 ]])

Accepts an Internet-radio.com station ID or URL and creates and returns a new 
station object, or I<undef> if the URL is not a valid Internet-radio.com 
station or no streams are found.  The URL can be the full URL, 
ie. www.Internet-radio.com/station/B<station-id>, or just I<station-id>.

The optional I<-notrim> argument can be either 0 or 1 (I<false> or I<true>).  
If 0 (I<false>) then stream URLs are trimmed of excess "ad" parameters 
(everything after the first "?" or "&" character, ie. "?ads.cust_params=premium" 
is removed, including the "?".  Otherwise, the stream URLs are returned as-is.  

DEFAULT I<-notrim> (if not given) is 0 (I<false>) and URLs are trimmed.  If 
I<-notrim> is specified without argument, the default is 1 (I<true>).  Try 
using I<-notrim> if stream will not play without the extra arguments.

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
[site]:  The site name (InternetRadio).  [url]:  The url searched for streams.  
[time]: Perl timestamp when the line was logged.  [title], [artist], [album], 
[description], [year], [genre], [total], [albumartist]:  The corresponding field data 
returned (or "I<-na->", if no value).

=item $station->B<get>()

Returns an array of strings representing all stream URLs found.

=item $station->B<getURL>([I<options>])

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

NOTE:  Most, if not all streams returned by InternetRadio ARE "playlists" 
(.pls, and a few .m3u), and thus using "nopls" may be needed to get to the 
specific (playable) stream.

=item $station->B<count>()

Returns the number of streams found for the station.

=item $station->B<getID>()

Returns the station's Radio.net ID (alphanumeric).

=item $station->B<getTitle>(['desc'])

Returns the station's title, or (long description). 

NOTE:  Internet-radio.com does NOT currently provide a long description for 
any of their stations, so "description" will always be the "title". 

=item $station->B<getIconURL>()

Returns the URL for the station's "cover art" icon image, if any.

NOTE:  Internet-radio.com does NOT currently provide any cover-art for any of 
their stations.

=item $station->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.

NOTE:  Internet-radio.com does NOT currently provide any cover-art for any of 
their stations.

=item $station->B<getImageURL>()

Returns the URL for the station's "cover art" (usually larger) 
banner image.

NOTE:  Internet-radio.com does NOT currently provide any cover-art for any of 
their stations.

=item $station->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual station's banner image (binary data).

NOTE:  Internet-radio.com does NOT currently provide any cover-art for any of 
their stations.

=item $station->B<getType>()

Returns the station's type ("InternetRadio").

=back

=head1 CONFIGURATION FILES

The default root location directory for StreamFinder configuration files 
is "~/.config/StreamFinder".  To use an alternate location directory, 
specify it in the "I<STREAMFINDER>" environment variable, ie.:  
B<$ENV{STREAMFINDER} = "/etc/StreamFinder">.

=over 4

=item ~/.config/StreamFinder/InternetRadio/config

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

InternetRadio

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-InternetRadio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-InternetRadio>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::InternetRadio

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-InternetRadio>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-InternetRadio>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-InternetRadio>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-InternetRadio/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2021 Jim Turner.

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

package StreamFinder::InternetRadio;

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

	my $self = $class->SUPER::new('InternetRadio', @_);
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});
	$self->{'notrim'} = 0;
	while (@_) {
		if ($_[0] =~ /^\-?notrim$/o) {
			shift;
			$self->{'notrim'} = (defined $_[0]) ? shift : 1;
		} else {
			shift;
		}
	}

	(my $url2fetch = $url);
	if ($url =~ /^https?\:/) {
		$self->{'id'} = $1  if ($url2fetch =~ m#\/([^\/]+)\/?$#);
	} else {
		$self->{'id'} = $url;
		$url2fetch = 'https://internet-radio.com/station/' . $url;
	}
	$url2fetch .= '/'  unless ($url2fetch =~ m#\/$#);  #NOTE:  INTERNETRADIO *REQUIRES* THE TRAILING SLASH!
	my $html = '';
	print STDERR "-0(InternetRadio): URL=$url2fetch= TIMEOUT=".$self->{'timeout'}."= AGENTOPS=".join('|',@{$self->{'_userAgentOps'}})."=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
print STDERR "--SUCCESS!\n"  if ($DEBUG);
	} else {
		my $server_error = $response->status_line;
		print STDERR "f:${server_error}\n"  if ($DEBUG);
		my $no_wget = system('wget','-V');
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
print STDERR "--NO HTML, PUNT!\n"  unless ($html);
	return undef  unless ($html);  #STEP 1 FAILED, INVALID STATION URL, PUNT!

	$self->{'title'} = $1  if ($html =~ m#\<(?:h1|title)\>([^\<]+)#si);
	if ($html =~ m#\<br\>Genres\s*\:\s*(.+?)\<\/div\>#si) {
		my $goodpart = $1;
		$self->{'genre'} = ($goodpart =~ s#^([^\<]+)\<##s) ? $1 : '';
		if ($self->{'genre'}) {
			$self->{'genre'} =~ s/ $//;
			$self->{'genre'} .= ', ';
		}
		while ($goodpart =~ s#\'startpage\'\,\s*\'([^\']+)\'\)\;##s) {
			my $one = $1;
print STDERR "----ONE=$one=\n"  if ($DEBUG);
			$self->{'genre'} .= $one . ', '  unless ($one =~ m#[\:\/\;]#o);
		}
		$self->{'genre'} =~ s/\, $//  if ($self->{'genre'});
print STDERR "-GENRE=".$self->{'genre'}."=\n-goodpart left=$goodpart=\n";
	}
	if ($html =~ m#\<br\>Website\s*\:\s*(.+?)\<\/div\>#s) {
		my $goodpart = $1;
		$self->{'albumartist'} = $1  if ($goodpart =~ m#\>(http[^\<]+)#s);
	}
	$self->{'imageurl'} = $self->{'iconurl'} = '';
	$self->{'description'} = $self->{'title'};  #Internet-radio.com DOES NOT PROVIDE ICONS OR DESCRIPTIONS!
	$self->{'title'} =~ s#\s*\-\s*Internet Radio##;

	my %streamHash = ();  #PREVENT DUPLICATES.
	while ($html =~ s#\,\s*\'play\w+\'\,\s*\'(http[^\']+)##s) {
		my $stream = $1;
		$stream =~ s/\.(pls|m3u)[\?\&].+$/\.$1/  unless ($self->{'notrim'});   #STRIP OFF EXTRA GARBAGE PARMS, COMMENT OUT IF STARTS FAILING!
		unless ($self->{'secure'} && $stream !~ /^https/o) {
print STDERR "----FOUND STREAM=$stream=\n"  if ($DEBUG);
			$streamHash{$stream} = $stream;
		}
	}
	@{$self->{'streams'}} = keys %streamHash;
	$self->{'cnt'} = scalar @{$self->{'streams'}};
	foreach my $field (qw(description title genre)) {
		$self->{$field} = HTML::Entities::decode_entities($self->{$field});
		$self->{$field} = uri_unescape($self->{$field});
		$self->{$field} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	}
	print STDERR "-2: ID=".$self->{'id'}."=\ntitle=".$self->{'title'}."=\ngenre=".$self->{'genre'}."=\ndesc=".$self->{'description'}."=\nalbum_artist=".$self->{'albumartist'}."=\n"  if ($DEBUG);
	$self->{'total'} = $self->{'cnt'};
	$self->{'Url'} = ($self->{'total'} > 0) ? $self->{'streams'}->[0] : '';
	print STDERR "--SUCCESS: 1st stream=".$self->{'Url'}."= total=".$self->{'total'}."=\n"
			if ($DEBUG && $self->{'cnt'} > 0);
	$self->_log($url);

	bless $self, $class;   #BLESS IT!

	return $self;
}

1
