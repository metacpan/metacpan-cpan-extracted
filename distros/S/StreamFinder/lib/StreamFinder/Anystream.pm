=head1 NAME

StreamFinder::Anystream - Fetch any raw streamable URLs from an HTML page.

=head1 AUTHOR

This module is Copyright (C) 2017-2021 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::Anystream;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $station = new StreamFinder::Anystream($ARGV[0]);

	die "Invalid URL or no streams found!\n"  unless ($station);

	my $firstStream = $station->get();

	print "First Stream URL=$firstStream\n";

	my $url = $station->getURL();

	print "Stream URL=$url\n";

	my $stream_count = $station->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $station->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::Anystream accepts any valid html URL 
and returns any actual stream URL(s) found.  StreamFinder::Anystream is intended 
mainly as a "last resort" search of webpages that do not match any of the supported 
websites handled (better) by the other site-specific StreamFinder modules.
The purpose is that one needs one of these URLs in order to have the option to 
stream the station in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of play.  The author uses his own custom all-purpose media player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
streams.  NOTE:  It is recommended to use the main StreamFinder module or 
one of the other StreamFinder submodules for searching supported sites, as this 
module does not return "station" (website)-specific or stream-specific metadata 
as those modules can and do for their supported sites!  The main StreamFinder 
module will first try to use the proper matching submodule supporting the website 
(if one exists) before trying this one last.

One or more streams can be returned.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [, I<-keep> => "type1,type2?..." | [type1,type2?...] ] 
[, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ]])

Accepts an HTML URL (webpage) and creates and returns a new station 
object, or I<undef> if the URL contains any valid stream URLs (matching the list of 
default extensions).  The URL must be the full URL.

The optional I<-keep> argument can be either a comma-separated string or an array 
reference ([...]) of stream types (extensions) to keep (include) and returned in 
order specified (type1, type2...).  Each "type" (extension) can be one of:  
"mp3", "m4a", "mp4", "pls" (playlist), etc.  
NOTE:  Since these are actual extensions used to identify streams, there is NO 
"any/all/stream/playlist" catch-all options as used by some of the other 
(more specific) StreamFinder-supported sites!  Streams will be returned sorted by 
extension in the order specified in this list.

DEFAULT I<-keep> list is:  "mp3,ogg,flac,mp4,m4a,mpd,m3u8,m3u,pls", meaning that 
all mp3 streams found (if any), followed by all "ogg" streams, etc.

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  If 1 
then only secure ("https://") streams will be returned.

DEFAULT I<-secure> is 0 (false) - return all streams (http and https).

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

=item $station->B<count>()

Returns the number of streams found for the station.

=item $station->B<getID>()

Returns the station's ID (alphanumeric).
NOTE:  Since this module only looks for any streams found on any 
specifed website, this function always returns the base name of 
the website being searched.

=item $station->B<getTitle>(['desc'])

Returns the station's title, or (long description).
NOTE:  Since this module only looks for any streams found on any 
specifed website, this function always returns the base name of 
the website being searched, or the full URL passed in with 
"https?://" prepended if missing ('desc').

=item $station->B<getIconURL>()

Returns the URL for the station's "cover art" icon image, if any.  
NOTE:  Since this module only looks for any streams found on any 
specifed website, this function always returns an empty string!

=item $station->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.
NOTE:  Since this module only looks for any streams found on any 
specifed website, this function always returns an empty array!

=item $station->B<getImageURL>()

Returns the URL for the station's "cover art" (usually larger) 
banner image.
NOTE:  Since this module only looks for any streams found on any 
specifed website, this function always returns an empty string!

=item $station->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual station's banner image (binary data).
NOTE:  Since this module only looks for any streams found on any 
specifed website, this function always returns an empty array!

=item $station->B<getType>()

Returns the station's type ("Anystream").

=back

=head1 CONFIGURATION FILES

=over 4

=item ~/.config/StreamFinder/Anystream/config

Optional text file for specifying various configuration options 
for a specific site (submodule).  Each option is specified on a 
separate line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used only by the specific 
(submodule) specified.  Valid options include 
I<-debug> => [0|1|2], and most of the L<LWP::UserAgent> options.  
Blank lines and lines starting with a "#" sign are ignored.

Options specified here override any specified in I<~/.config/StreamFinder/config>.

Among options valid for Anystream streams is the I<-keep> option 
previously described in the B<new()> function.

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

Anystream

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-Anystream at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Anystream>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Anystream

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Anystream>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Anystream>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Anystream>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Anystream/>

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

package StreamFinder::Anystream;

use strict;
use warnings;
use URI::Escape;
use HTML::Entities ();
use LWP::UserAgent ();
use vars qw(@ISA @EXPORT);

my $DEBUG = 0;
my $bummer = ($^O =~ /MSWin/);
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

	my @okStreams;

	my $homedir = $bummer ? $ENV{'HOMEDRIVE'} . $ENV{'HOMEPATH'} : $ENV{'HOME'};
	$homedir ||= $ENV{'LOGDIR'}  if ($ENV{'LOGDIR'});
	$homedir =~ s#[\/\\]$##;
	foreach my $p ("${homedir}/.config/StreamFinder/config", "${homedir}/.config/StreamFinder/Anystream/config") {
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
	$uops{'secure'} = 0    unless (defined $uops{'secure'});
	$DEBUG = $uops{'debug'}  if (defined $uops{'debug'});

	while (@_) {
		if ($_[0] =~ /^\-?debug$/o) {
			shift;
			$DEBUG = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
		} elsif ($_[0] =~ /^\-?keep$/o) {
			shift;
			if (defined $_[0]) {
				my $keeporder = shift;
				@okStreams = (ref($keeporder) =~ /ARRAY/) ? @{$keeporder} : split(/\,\s*/, $keeporder);
			}
		} elsif ($_[0] =~ /^\-?secure$/o) {
			shift;
			$uops{'secure'} = (defined $_[0]) ? shift : 1;
		}
	}	
	if (!defined($okStreams[0]) && defined($uops{'keep'})) {
		@okStreams = (ref($uops{'keep'}) =~ /ARRAY/) ? @{$uops{'keep'}} : split(/\,\s*/, $uops{'keep'});
	}
	@okStreams = (qw(mp3 ogg flac mp4 m4a mpd m3u8 m3u pls))  unless (defined $okStreams[0]);

	my $url2fetch = $url;
	$url2fetch = 'https://' . $url  unless ($url =~ m#^https?\:\/\/#);
	$self->{'id'} = ($url2fetch =~ m#\/\/([^\/\?\&\#]+)#) ? $1 : 'no_id';
	$url2fetch =~ s#\/$##;

	$self->{'title'} = '';
	$self->{'artist'} = '';
	$self->{'album'} = '';
	$self->{'description'} = '';
	$self->{'created'} = '';
	$self->{'year'} = '';
	$self->{'genre'} = '';
	$self->{'iconurl'} = '';
	$self->{'streams'} = [];
	$self->{'cnt'} = 0;
	$self->{'Url'} = '';
	$self->{'playlist'} = '';
	$self->{'albumartist'} = $url2fetch;
	my $html = '';
	print STDERR "-0(Anystream): URL=$url2fetch=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new(@userAgentOps);		
	$ua->timeout($uops{'timeout'});
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
	$self->{'title'} = $self->{'id'} || $url;
	$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
	$self->{'title'} = uri_unescape($self->{'title'});
	$self->{'description'} = $url2fetch;
	$self->{'description'} = HTML::Entities::decode_entities($self->{'description'});
	$self->{'description'} = uri_unescape($self->{'description'});
	$self->{'albumartist'} = $url;
	print STDERR "-2: title=".$self->{'title'}."=\n"  if ($DEBUG);
	$self->{'cnt'} = 0;
	my $streams = '';
	my $streamExts = join('|',@okStreams);
	print STDERR "--EXTS=$streamExts=\n"  if ($DEBUG);
	while ($html =~ s#((?:https?\:\/)?\/?[^\s\'\"\:\<\>\[\]\{\}]+?)\.($streamExts)##s) {
		my $ext = $2;
		my $streamURL = $1.'.'.$ext;
		print STDERR "--1: streamURL=$streamURL=\n"  if ($DEBUG);
		if ($streamURL =~ m#^\/#o) {  #STREAM URL STARTS WITH "/", ASSUME ABSOLUTE TO BASE PAGE URL ("TITLE"):
			my $prefix = ($url2fetch =~ m#^(https?)#o) ? $1 : 'http';
			$streamURL = $prefix . '://' . $self->{'title'} . $streamURL;
			print STDERR "--2a: title=".$self->{'title'}."= stream=$streamURL=\n"  if ($DEBUG);
		} elsif ($streamURL !~ /^http/o) {  #NO PREFIX, ASSUME RELATIVE TO THE FETCHED URL ("LONG DESC."):
			(my $prefix = $self->{'description'}) =~ s#[\&\?\=\/].*$##;
		print STDERR "--2b: desc=".$prefix."= stream=$streamURL=\n"  if ($DEBUG);
			$streamURL = $prefix . '/' . $streamURL;
		}  #OTHERWISE STREAM URL IS A FULL URL (NO CHANGE).
		$streams .= "$ext=$streamURL|"  unless ($uops{'secure'} && $streamURL !~ /^https/o);
	}
	print STDERR "==streams=$streams=\n"  if ($DEBUG);
	my $stindex = 0;
	my $savestreams = $streams;
	my %havestreams = ();
	my ($one, $ext);
	foreach my $streamtype (@okStreams) {
		$streams = $savestreams;
		while ($streams =~ /^([^\=]*)\=([^\|]+)/o) {
			$ext = $1; $one = $2;
			if ($ext =~ /^${streamtype}$/i && !defined($havestreams{"$ext|$one"})) {
				$self->{'streams'}->[$stindex++] = $one;
				$havestreams{"$ext|$one"}++;
			}
			$streams =~ s/^[^\|]*\|//o;
		}
	}
	$self->{'cnt'} = scalar @{$self->{'streams'}};
	$self->{'total'} = $self->{'cnt'};

	print STDERR "-SUCCESS: 1st stream=".${$self->{'streams'}}[0]."= total=".$self->{'total'}."=\n"  if ($DEBUG);
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
	my $self = shift;
	my $arglist = (defined $_[0]) ? join('|',@_) : '';
	my $idx = ($arglist =~ /\b\-?random\b/) ? int rand scalar @{$self->{'streams'}} : 0;
	if (($arglist =~ /\b\-?nopls\b/ && ${$self->{'streams'}}[$idx] =~ /\.(pls)$/i)
			|| ($arglist =~ /\b\-?noplaylists\b/ && ${$self->{'streams'}}[$idx] =~ /\.(pls|m3u8?)$/i)) {
		my $plType = $1;
		my $firstStream = ${$self->{'streams'}}[$idx];
		print STDERR "-getURL($idx): NOPLAYLISTS and (".${$self->{'streams'}}[$idx].")\n"  if ($DEBUG);
		my $ua = LWP::UserAgent->new(@userAgentOps);		
		$ua->timeout($uops{'timeout'});
		$ua->cookie_jar({});
		$ua->env_proxy;
		my $html = '';
		my $response = $ua->get($firstStream);
		if ($response->is_success) {
			$html = $response->decoded_content;
		} else {
			print STDERR $response->status_line  if ($DEBUG);
			my $no_wget = system('wget','-V');
			unless ($no_wget) {
				print STDERR "\n..trying wget...\n"  if ($DEBUG);
				$html = `wget -t 2 -T 20 -O- -o /dev/null \"$firstStream\" 2>/dev/null `;
			}
		}
		my @lines = split(/\r?\n/, $html);
		my @plentries = ();
		my $firstTitle = '';
		my $plidx = ($arglist =~ /\b\-?random\b/) ? 1 : 0;
		if ($plType =~ /pls/i) {  #PLS:
			foreach my $line (@lines) {
				if ($line =~ m#^\s*File\d+\=(.+)$#o) {
					push (@plentries, $1);
				} elsif ($line =~ m#^\s*Title\d+\=(.+)$#o) {
					$firstTitle ||= $1;
				}
			}
			$self->{'title'} ||= $firstTitle;
			print STDERR "-getURL(PLS): title=$firstTitle= pl_idx=$plidx=\n"  if ($DEBUG);
		} elsif ($arglist =~ /\b\-?noplaylists\b/) {  #m3u*:
			(my $urlpath = ${$self->{'streams'}}[$idx]) =~ s#[^\/]+$##;
			foreach my $line (@lines) {
				if ($line =~ m#^\s*([^\#].+)$#o) {
					my $urlpart = $1;
					$urlpart =~ s#^\s+##o;
					$urlpart =~ s#^\/##o;
					push (@plentries, ($urlpart =~ m#https?\:#) ? $urlpart : ($urlpath . '/' . $urlpart));
					last  unless ($plidx);
				}
			}
			print STDERR "-getURL(m3u?): pl_idx=$plidx=\n"  if ($DEBUG);
		}
		if ($plidx && $#plentries >= 0) {
			$plidx = int rand scalar @plentries;
		} else {
			$plidx = 0;
		}
		$firstStream = (defined($plentries[$plidx]) && $plentries[$plidx]) ? $plentries[$plidx]
				: ${$self->{'streams'}}[$idx];

		return $firstStream;
	}

	return ${$self->{'streams'}}[$idx];
}

sub count
{
	my $self = shift;
	return $self->{'total'};  #TOTAL NUMBER OF PLAYABLE STREAM URLS FOUND.
}

sub getType
{
	my $self = shift;
	return 'Anystream';  #STATION TYPE (FOR PARENT StreamFinder MODULE).
}

sub getID
{
	my $self = shift;
	return $self->{'id'};  #URL TO THE STATION'S ID.
}

sub getTitle
{
	my $self = shift;
	return $self->{'description'}  if (defined($_[0]) && $_[0] =~ /^\-?(?:long|desc)/i);
	return $self->{'title'};  #STATION'S TITLE(DESCRIPTION), IF ANY.
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
	my $ua = LWP::UserAgent->new(@userAgentOps);		
	$ua->timeout($uops{'timeout'});
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
