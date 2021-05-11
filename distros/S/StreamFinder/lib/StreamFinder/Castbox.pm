=head1 NAME

StreamFinder::Castbox - Fetch actual raw streamable podcast URLs on castbox.com

=head1 AUTHOR

This module is Copyright (C) 2021 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	#!/usr/bin/perl

	use strict;

	use StreamFinder::Castbox;

	die "..usage:  $0 URL\n"  unless ($ARGV[0]);

	my $podcast = new StreamFinder::Castbox($ARGV[0]);

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

StreamFinder::Castbox accepts a valid podcast ID or URL on 
Castbox.com and returns the actual stream URL(s), title, and cover art icon.  
The purpose is that one needs one of these URLs in order to have the option to 
stream the podcast in one's own choice of media player software rather than 
using their web browser and accepting any / all flash, ads, javascript, 
cookies, trackers, web-bugs, and other crapware that can come with that method 
of play.  The author uses his own custom all-purpose media player called 
"fauxdacious" (his custom hacked version of the open-source "audacious" 
audio player).  "fauxdacious" can incorporate this module to decode and play 
Castbox.com streams.

One or more stream URLs can be returned for each podcast.  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ] ... ])

Accepts a www.castbox.com podcast URL and creates and returns a 
a new podcast object, or I<undef> if the URL is not a valid podcast, or no 
streams are found.  The URL MUST be the full URL, ie. 
https://castbox.fm/episode/I<title>-idB<channel-id>-idB<episode-id>, or 
https://castbox.fm/channel/idB<channel-id> 
as I know of no way to look up a podcast on Castbox with just an episode ID.
If no I<episode-id> is specified, the first (latest) episode for the channel 
is returned.

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  If 1 
then only secure ("https://") streams will be returned.

DEFAULT I<-secure> is 0 (false) - return all streams (http and https).

=item $podcast->B<get>(['playlist'])

Returns an array of strings representing all stream URLs found.
If I<"playlist"> is specified, then an extended m3u playlist is returned 
instead of stream url(s).  NOTE:  If an author / channel page url is given, 
rather than an individual podcast episode's url, get() returns the first 
(latest?) podcast episode found, and get("playlist") returns an extended 
m3u playlist containing the urls, titles, etc. for all the podcast 
episodes found on that page url.

=item $podcast->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  There currently are no valid I<options>.

=item $podcast->B<count>()

Returns the number of streams found for the podcast.

=item $podcast->B<getID>()

Returns the podcast's Castbox ID (default).  For podcasts, the Castbox ID 
is a single value.  For individual podcast episodes it's two values 
separated by a slash ("/").

=item $podcast->B<getTitle>(['desc'])

Returns the podcast's title, or (long description).  Podcasts 
on Castbox can have separate descriptions, but for podcasts, 
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

Returns the podcast's type ("Castbox").

=back

=head1 CONFIGURATION FILES

=over 4

=item ~/.config/StreamFinder/Castbox/config

Optional text file for specifying various configuration options 
for a specific site (submodule).  Each option is specified on a 
separate line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used only by the specific 
(submodule) specified.  Valid options include 
I<-debug> => [0|1|2], and most of the L<LWP::UserAgent> options.  
Blank lines and lines starting with a "#" sign are ignored.

Options specified here override any specified in I<~/.config/StreamFinder/config>.

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

castbox

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-iheartradio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Castbox>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Castbox

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Castbox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Castbox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Castbox>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Castbox/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2021 Jim Turner.

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

package StreamFinder::Castbox;

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

	my $homedir = $bummer ? $ENV{'HOMEDRIVE'} . $ENV{'HOMEPATH'} : $ENV{'HOME'};
	$homedir ||= $ENV{'LOGDIR'}  if ($ENV{'LOGDIR'});
	$homedir =~ s#[\/\\]$##;
	my (@okStreams, @skipStreams, @okStreamsClassic, @skipStreamsClassic);
	foreach my $p ("${homedir}/.config/StreamFinder/config", "${homedir}/.config/StreamFinder/Castbox/config") {
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
		} elsif ($_[0] =~ /^\-?secure$/o) {
			shift;
			$uops{'secure'} = (defined $_[0]) ? shift : 1;
		} else {
			shift;
		}
	}
	$self->{'id'} = '';
	my $urlroot = '';
	(my $url2fetch = $url);
	if ($url2fetch =~ m#^(https?\:\/\/castbox\.\w+)#) {
		$urlroot = $1;
		$self->{'id'} = ($url =~ m#\-id(\d+)\-id(\d+)#) ? "${1}/$2" : '';
		$self->{'id'} ||= $1  if ($url =~ m#id(\d+)#);   #NO EPISODE SPECIFIED
	} else {  #MUST PROVIDE URL, NO KNOWN WAY TO LOOK UP WITH JUST ID#?!
		print STDERR "w:Url ($url) is NOT a valid Castbox podcast url!\n"  if ($DEBUG);
		return undef;
	}

	my $html = '';
	print STDERR "-0(Castbox): FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new(@userAgentOps);		
	$ua->timeout($uops{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $response;
	$self->{'title'} = '';
	$self->{'artist'} = '';
	$self->{'album'} = '';
	$self->{'description'} = '';
	$self->{'created'} = '';
	$self->{'year'} = '';
	$self->{'genre'} = 'Podcast';
	$self->{'iconurl'} = '';
	$self->{'streams'} = [];
	$self->{'cnt'} = 0;
	$self->{'Url'} = '';
	$self->{'playlist'} = '';
	$self->{'albumartist'} = $url2fetch;
	my @epiTitles = ();
	my @epiStreams = ();
	if ($self->{'id'} !~ m#\/#) {  #NO SPECIFIC EPISODE GIVEN, TRY TO FIND 1ST (LATEST) ONE:
		$response = $ua->get($url2fetch);
		if ($response->is_success) {
			$html = $response->decoded_content;
		} else {
			print STDERR $response->status_line  if ($DEBUG);
		}

		print STDERR "-1a: html=$html=\n"  if ($DEBUG > 1);
		if ($html =~ m#\<div\s+class\=\"ep\-item\-cover\"\>\s*\<a\s+href\=\"([^\"]+)#s) {
			$url2fetch = $1;
			$url2fetch = "https://castbox.fm$url2fetch"  if ($url2fetch !~ /^http/);
			$self->{'id'} = ($url2fetch =~ m#\-id(\d+)\-id(\d+)#) ? "${1}/$2" : '';
			$self->{'description'} = $1  if ($html =~ s#\<div\s+class\=\"des\-con\"\>(?:\<div\>)?([^\<]+)##s);
			$self->{'description'} ||= $1  if ($html =~ s#\<meta\s+name\=\"description\"\s+content\=\"([^\"]+)\"\s*\/?\>##s);
			$self->{'description'} ||= $1  if ($html =~ s#\<meta\s+property\=\"(?:og|twitter)\:description\"\s+content\=\"([^\"]+)\"\s*\/"\>##s);
			$self->{'iconurl'} = ($html =~ s#\<meta\s+property\=\"(?:og|twitter)\:image\"\s+content\=\"([^\"]+)\"\s*\/\>##s) ? $1 : '';
			$self->{'iconurl'} ||= $1  if ($html =~ s#\"\,\"image\"\:\"([^\"]+)\"\}\}\]\}##s);
			$self->{'imageurl'} = $self->{'iconurl'};
			$html =~ s#^.+?\_\_INITIAL\_STATE\_\_##s;
			$html = uri_unescape($html);
			$html =~ s#^.+?\"eps\"\:\[##s;
			$html =~ s#\]\,\"epStatusCid\".+$##s;
			while ($html =~ s#\{([^\}]+)\}##s) {
				my $goodstuff = $1;
				my $stream = '';
				my $title = '';
				if ($goodstuff =~ s#\"url\"\:\"([^\"]+)\"##s) {
					$stream = $1;
				} elsif ($goodstuff =~ s#\"urls\"\:\[\"([^\"]+)\"##s) {
					$stream = $1;
				}
				if ($stream && $goodstuff =~ s#\"title\"\:\"([^\"]+)\"##s) {
					my $one = $1;
					unless ($uops{'secure'} && $stream !~ /^https/o) {
						push @epiTitles, $one;
						push @epiStreams, $stream;
					}
				}
			}
			$html = '';
		}
		return undef  unless ($self->{'id'} =~ m#\/#);  #MUST HAVE AN EPISODE BY NOW!

		print STDERR "-1a: no episode specified, found first ep=".$self->{'id'}."=\n"  if ($DEBUG);
		print STDERR "-1(Castbox): FETCHING URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	}

	$response = $ua->get($url2fetch);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html && $self->{'id'});  #STEP 1 FAILED, INVALID PODCAST URL, PUNT!

	my %dups = ();
	if ($html =~ s#\<audio[^\>]*\>(.+?)\<\/audio\>##s) {
		my $audiostuff = $1;
		while ($audiostuff =~ s#\s+src\=\"([^\"]+)\"##s) {
			my $audiourl = $1;
			unless ($dups{$audiourl} || ($uops{'secure'} && $audiourl !~ /^https/o)) {
				push @{$self->{'streams'}}, $audiourl;
				$self->{'cnt'}++;
				$dups{$audiourl} = 1;
			}
		}
	}
	$self->{'total'} = $self->{'cnt'};
	if ($self->{'total'} < 1 && $#epiStreams >= 0) {
		push @{$self->{'streams'}}, $epiStreams[0];
		$self->{'total'} = $self->{'cnt'} = 1;
	}
	return undef  unless ($self->{'total'} > 0);

	%dups = ();
	$self->{'title'} = ($html =~ s#\<meta\s+property\=\"(?:og|twitter)\:title\"\s+content\=\"([^\"]+)\"\s*\/?\>##s) ? $1 : '';
	$self->{'title'} ||= $1  if ($html =~ s#\<meta\s+name\=\"title\"\s+content\=\"([^\"]+)\"\s*\/?\>##s);
	$self->{'title'} ||= $1  if ($html =~ s#\<TITLE\>\s*([^\|\<]+)##s);
	$self->{'title'} ||= $epiTitles[0]  if ($#epiTitles >= 0);
	if (!$self->{'description'} && $html =~ m#class\=\"trackinfo\-des\"\>(.+?)\<\/div\>#s) {
		my $desc = $1;
		$desc = $1  if ($desc =~ m#\<div[^\>]*\>(.+)$#s);
		$self->{'description'} = $desc;
	}
	$self->{'description'} ||= $1  if ($html =~ s#\<meta\s+name\=\"description\"\s+content\=\"([^\"]+)\"\s*\/?\>##s);
	$self->{'description'} ||= $1  if ($html =~ s#\<meta\s+property\=\"(?:og|twitter)\:description\"\s+content\=\"([^\"]+)\"\s*\/"\>##s);
	if ($html =~ s#\>\s*Update\:\s+([^\<]+)\<##s) {
		my $datestuff = $1;
		$self->{'year'} = $1  if ($datestuff =~ /(\d\d\d\d)\s*$/);
		$self->{'created'} = $1  if ($datestuff =~ /(\d\d\d\d\-\d\d\-\d\d)\s*$/);
	}
	$self->{'year'} ||= $1  if ($html =~ s#\<span\s+class\=\"item\s+icon\s+date\"\>(\d\d\d\d)##s);
	$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
	$self->{'title'} = uri_unescape($self->{'title'});
	$self->{'title'} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	$self->{'description'} = HTML::Entities::decode_entities($self->{'description'});
	$self->{'description'} = uri_unescape($self->{'description'});
	$self->{'description'} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
	$self->{'iconurl'} ||= ($html =~ s#\<meta\s+property\=\"(?:og|twitter)\:image\"\s+content\=\"([^\"]+)\"\s*\/\>##s) ? $1 : '';
	$self->{'iconurl'} ||= $1  if ($html =~ s#\"\,\"image\"\:\"([^\"]+)\"\}\}\]\}##s);
	$self->{'imageurl'} ||= $self->{'iconurl'};
	$self->{'album'} = $1  if ($html =~ m#\<h1\s+class\=\"author ellipsis\"\>([^\<]+)#);
#	if ($html =~ s#\"\s+class\=\"breadcrumb\-text\"\>\s*\<a\s+href\=\"(\/channel\/[^\"]+)\"\>([^\<]+)\<\/\a\>\<\/span\>##s) {
	if ($html =~ s#\"\s+class\=\"breadcrumb\-text\"\>\s*\<a\s+href\=\"(\/channel\/[^\"]+)\"\>([^\<]+)##s) {
		$self->{'albumartist'} = $urlroot . $1;
		$self->{'artist'} = $2;
	}
	print STDERR "-(all)count=".$self->{'cnt'}."= iconurl=".$self->{'iconurl'}."= TITLE=".$self->{'title'}."= DESC=".$self->{'description'}."= YEAR=".$self->{'year'}."= artist=".$self->{'artist'}."= albart=".$self->{'albumartist'}."=\n"  if ($DEBUG);
	print STDERR "-SUCCESS: 1st stream=".${$self->{'streams'}}[0]."=\n"  if ($DEBUG);
	if ($self->{'total'} > 0) {
		$self->{'playlist'} = "#EXTM3U\n";
		if ($#epiTitles >= 0) {
			for (my $i=0;$i<=$#epiTitles;$i++) {
				$self->{'playlist'} .= "#EXTINF:-1, " . $epiTitles[$i]
						. "\n#EXTART:" . $self->{'artist'} . "\n" . $epiStreams[$i] . "\n";
			}
		} else {
			$self->{'playlist'} .= "#EXTINF:-1, " . $self->{'title'}
					. "\n#EXTART:" . $self->{'artist'} . "\n" . ${$self->{'streams'}}[0] . "\n";
		}
	}

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub get
{
	my $self = shift;

	return wantarray ? ($self->{'playlist'}) : $self->{'playlist'}  if (defined($_[0]) && $_[0] =~ /playlist/i);
	return wantarray ? @{$self->{'streams'}} : ${$self->{'streams'}}[0];
}

sub getURL   #LIKE GET, BUT ONLY RETURN THE SINGLE ONE W/BEST BANDWIDTH AND RELIABILITY:
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
	return 'Castbox';  #PODCAST TYPE (FOR PARENT StreamFinder MODULE).
}

sub getID
{
	my $self = shift;
	return $self->{'fccid'}  if (defined($_[0]) && $_[0] =~ /fcc/i);  #PODCAST'S CALL LETTERS OR IHEARTRADIO-ID.
	return $self->{'id'};
}

sub getTitle
{
	my $self = shift;
	return $self->{'description'}  if (defined($_[0]) && $_[0] =~ /^\-?(?:long|desc)/i);
	return $self->{'title'};  #PODCAST'S TITLE(DESCRIPTION), IF ANY.
}

sub getIconURL
{
	my $self = shift;
	return $self->{'iconurl'};  #URL TO THE PODCAST'S THUMBNAIL ICON, IF ANY.
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
	return $self->{'imageurl'};  #URL TO THE PODCAST'S BANNER IMAGE, IF ANY.
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
