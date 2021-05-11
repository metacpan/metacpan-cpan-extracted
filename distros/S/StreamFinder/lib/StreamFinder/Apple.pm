=head1 NAME

StreamFinder::Apple - Fetch actual raw streamable URLs from Apple 
podcasts on podcasts.apple.com

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

	use StreamFinder::Apple;

	die "..usage:  $0 ID|URL\n"  unless ($ARGV[0]);

	my $podcast = new StreamFinder::Apple($ARGV[0]);

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

	print "PODCAST ID=$podcastID\n";
	
	my $artist = $podcast->{'artist'};

	print "Artist=$artist\n"  if ($artist);
	
	my $genre = $podcast->{'genre'};

	print "Genre=$genre\n"  if ($genre);
	
	my $icon_url = $podcast->getIconURL();

	if ($icon_url) {   #SAVE THE ICON TO A TEMP. FILE:

		my ($image_ext, $icon_image) = $podcast->getIconData();

		if ($icon_image && open IMGOUT, ">/tmp/${podcastID}.$image_ext") {

			binmode IMGOUT;

			print IMGOUT $icon_image;

			close IMGOUT;

		}

	}

	my $stream_count = $podcast->count();

	print "--Stream count=$stream_count=\n";

	my @streams = $podcast->get();

	foreach my $s (@streams) {

		print "------ stream URL=$s=\n";

	}

=head1 DESCRIPTION

StreamFinder::Apple accepts a valid podcast or episode URL on 
podcasts.apple.com, and returns the actual stream URL(s), title, and cover 
art icon for that podcast.  The purpose is that one needs one of these URLs 
in order to have the option to stream the station in one's own choice of 
media player software rather than using their web browser and accepting any / 
all flash, ads, javascript, cookies, trackers, web-bugs, and other crapware 
that can come with that method of play.  The author uses his own custom 
all-purpose media player called "fauxdacious" (his custom hacked version of 
the open-source "audacious" audio player.  "fauxdacious" incorporates this 
module to decode and play podcasts.apple.com streams.

NOTE:  The URL must be either a podcast site, format:  
https://podcasts.apple.com/I<country>/podcast/idB<podcast#> 
(returns stream(s) for all "episodes" for that site, OR a specific podcast / 
"episode" page site, format:  
https://podcasts.apple.com/I<country>/podcast/idB<podcast#>?i=B<episode#> 
(returns a single stream for that specific podcast).  

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<ID>|I<url> [I<-secure> [ => 0|1 ]] [, I<-debug> [ => 0|1|2 ]])

Accepts a podcasts.apple.com ID or URL and creates and 
returns a new podcast object, or I<undef> if the URL is not a valid podcast, 
album, etc. or no streams are found.  The URL can be the full URL, 
ie. https://podcasts.apple.com/podcast/idI<podcast-id>, 
https://podcasts.apple.com/podcast/idB<podcast-id>?i=B<episode-id>, or just 
I<podcast-id>, or I<podcast-id>/I<episode-id>.  

The optional I<-secure> argument can be either 0 or 1 (I<false> or I<true>).  If 1 
then only secure ("https://") streams will be returned.

DEFAULT I<-secure> is 0 (false) - return all streams (http and https).

=item $podcast->B<get>(['playlist'])

Returns an array of strings representing all stream urls found.
If I<"playlist"> is specified, then an extended m3u playlist is returned 
instead of stream url(s).  NOTE:  If an author / channel page url is given, 
rather than an individual podcast episode's url, get() returns the first 
(latest?) podcast episode found, and get("playlist") returns an extended 
m3u playlist containing the urls, titles, etc. for all the podcast 
episodes found on that page url.

=item $podcast->B<getURL>([I<options>])

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

=item $podcast->B<count>()

Returns the number of streams found for the podcast / episode / album / song.  
Episodes and songs usually return 1, whereas podcasts and albums usually 1 
for each episode / sample song clip in the podcast / album respectively.

=item $podcast->B<getID>()

Returns the station's Apple ID (numeric).  For podcasts and albums, this 
is a single numeric value.  For episodes and songs, it's two numbers 
separated by a slash ("/").

=item $podcast->B<getTitle>(['desc'])

Returns the podcast's, album's, episode's or song clip's title, 
or (long description).  

=item $podcast->B<getIconURL>()

Returns the url for the podcast's / album's "cover art" icon image, 
if any.

=item $podcast->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual icon image (binary data), if any.

=item $podcast->B<getImageURL>()

Returns the url for the podcast's / album's "cover art" banner image, 
which for Apple is always the icon image, as Apple does not support 
a separate banner image at this time.

=item $podcast->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc.) and the actual station's banner image (binary data).

=item $podcast->B<getType>()

Returns the station's type ("Apple").

=back

=head1 CONFIGURATION FILES

=over 4

=item ~/.config/StreamFinder/Apple/config

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

apple podcasts

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

=head1 BUGS

Please report any bugs or feature requests to C<bug-streamFinder-apple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=StreamFinder-Apple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc StreamFinder::Apple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=StreamFinder-Apple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/StreamFinder-Apple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/StreamFinder-Apple>

=item * Search CPAN

L<http://search.cpan.org/dist/StreamFinder-Apple/>

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

package StreamFinder::Apple;

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
	foreach my $p ("${homedir}/.config/StreamFinder/config", "${homedir}/.config/StreamFinder/Apple/config") {
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
	(my $url2fetch = $url);
	if ($url2fetch =~ m#^https?\:\/\/podcasts\.apple\.#) {
#EXAMPLE1:my $url = 'https://podcasts.apple.com/us/podcast/wnbc-sec-shorts-josh-snead/id1440412195?i=1000448441439';
#EXAMPLE2:my $url = 'https://podcasts.apple.com/us/podcast/good-bull-hunting-for-texas-a-m-fans/id1440412195';
#xxxEXAMPLE3:my $url = 'https://music.apple.com/us/album/big-legged-woman/723550112';
		$self->{'id'} = ($url =~ m#\/(?:id)?(\d+)(?:\?i\=(\d+))?\/?#) ? $1 : '';
		$self->{'id'} .= '/'. $2  if (defined $2);
	} elsif ($url2fetch !~ m#^https?\:\/\/#) {
		my ($id, $podcastid) = split(m#\/#, $url2fetch);
		$self->{'id'} = $id;
		$url2fetch = 'https://podcasts.apple.com/podcast/id' . $id;
		$url2fetch .= '?i=' . $podcastid  if ($podcastid);
	}

	print STDERR "--URL=$url2fetch= ID=".$self->{'id'}."=\n"  if ($DEBUG);
	return undef  unless ($self->{'id'});

	my $html = '';
	print STDERR "-0(Apple): ID=".$self->{'id'}."= AGENT=".join('|',@userAgentOps)."=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new(@userAgentOps);
	$ua->timeout($uops{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	print STDERR "i:FETCHING URL ($url2fetch)...\n"  if ($DEBUG);
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
	return undef  unless ($html);

	$self->{'title'} = '';
	$self->{'artist'} = '';
	$self->{'album'} = '';
	$self->{'description'} = '';
	$self->{'created'} = '';
	$self->{'year'} = '';
	$self->{'iconurl'} = '';
	$self->{'streams'} = [];
	$self->{'cnt'} = 0;
	$self->{'Url'} = '';
	$self->{'playlist'} = '';
	$self->{'albumartist'} = $url2fetch;
	$self->{'genre'} = '';
	my @epiTitles = ();
	my ($pre, $post) = split(/\"included\"\:/, $html, 2);
	$html = '';
	return undef  unless ($pre && $post);

	$self->{'iconurl'} = ($pre =~ m#\<img\s+class\=\".*?src\=\"([^\"]+)#s) ? $1 : '';
	if ($self->{'iconurl'} !~ /^http/) {
		$self->{'iconurl'} = ($pre =~ /\s+srcset\=\"([^\"\s]+)/s) ? $1 : '';
	}
	$self->{'imageurl'} = $self->{'iconurl'};
	if ($pre =~ m#\<span\s+class\=\"product\-header\_\_identity(.+?)\<\/span\>#s) {
		my $span = $1;
		#x $self->{'artist'} = $1  if ($span =~ m#\"\>\s*([^\<]+)\<\/#s);
		$self->{'artist'} = $1  if ($span =~ m#\>\s*([^\<]+)\<\/a#s);
		if ($self->{'artist'} !~ /\w/) {
			$self->{'artist'} = $1  if ($span =~ m#\>\s*([^\<]+)#s);
		}
		$self->{'artist'} =~ s/\s+$//;
		$self->{'albumartist'} = $1  if ($span =~ m#href\=\"([^\"]+)\"\s+class\=\"link#is);
	}
	if ($pre =~ m#\<li\s+class\=\"tracklist\-footer\_\_item\"\>([^\<]+)#) {
		$self->{'album'} = $1;
		$self->{'album'} =~ s/^\s+//s;
		$self->{'album'} =~ s/\s+$//s;
	}
	if ($pre =~ m#\"assetUrl\"\:\"([^\"]+)\"#s) {   #INVIDUAL EPISODE:
		print STDERR "---EPISODE---\n"  if ($DEBUG);
		my $stream = $1;
		$self->{'streams'}->[0] = $stream  unless ($uops{'secure'} && $stream !~ /^https/o);
		my $rest = $2;
		$self->{'title'} = $1  if ($pre =~ m#\"mediaKind\"\:\"[^\"]*\"\,\"name\"\:\"([^\"]+)\"#s);
		if ($self->{'title'}) {
			my $title = HTML::Entities::decode_entities($self->{'title'});
			$title = uri_unescape($title);
			$title =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
			@epiTitles = ($title)  if ($self->{'streams'}->[0]);
		}
		if ($pre =~ m#episode-description\>(.+?)\<\/section\>#s) {
			$self->{'description'} = $1;
			$self->{'description'} =~ s#\<p[^\>]*\>(.+?)\<\/p\>#$1#s;
		}
		$self->{'description'} ||= $1  if ($pre =~ m#\"description\"\:\{\"standard\"\:\"([^\"]+)\"#s);
		$self->{'description'} ||= $1  if ($pre =~ m#\"short\"\:\"([^\"]+)\"#s);
		$self->{'created'} = $1  if ($pre =~ m#\"datePublished\"\:\"([^\"]+)#s);
	} else {   #PAGE (multiple episodes):
		print STDERR "---PAGE (multiple episodes)---\n"  if ($DEBUG);
		if ($pre =~ m#type\=\".*?json\"\>([^\<]+)#) {
			my $json = $1;
			$self->{'title'} = $1  if ($json =~ m#\"name\"\:\"([^\"]+)\"#s);
			$self->{'description'} = $1  if ($json =~ m#\"description\"\:\"([^\"]+)\"#s);
			$self->{'created'} = $1  if ($json =~ m#\"datePublished\"\:\"([^\"]+)\"#s);
		}
		while ($post =~ s#\"assetUrl\"\:\"([^\"]+)\".+?\,\"name\"\:\"([^\"]+)\"##s) {
			my $stream = $1;
			my $title = HTML::Entities::decode_entities($2);
			$title = uri_unescape($title);
			$title =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
			unless ($uops{'secure'} && $stream !~ /^https/o) {
				push @{$self->{'streams'}}, $stream;
				push @epiTitles, $title;
			}
		}
	}
	$self->{'year'} = $1  if ($self->{'created'} =~ /(\d\d\d\d)/);
	if ($pre =~ m#\<li\s+class\=\"product\-header\_\_list\_\_item\"\>(.*?)\<\/ul\>#s) {
		my $prodlistitemdata = $1;
		$self->{'genre'} = $1  if ($prodlistitemdata =~ s#genre\"?\>\s*([^\<]+)\<\/##s);
		$self->{'year'} = $1  if ($prodlistitemdata =~ m#\>([\d]+)\D*\<\/time\>#s);
	}
	$self->{'genre'} ||= $1  if ($pre =~ m#\<li\s+class\=\"inline\-list\_\_item[^\>]+\>(.*?)\<\/li\>#s);
	if ($self->{'genre'})	{
		$self->{'genre'} =~ s/^\s+//;
		$self->{'genre'} =~ s/\s+$//;
		$self->{'genre'} = HTML::Entities::decode_entities($self->{'genre'})  if (defined $self->{'genre'});
		$self->{'genre'} = uri_unescape($self->{'genre'});
		$self->{'genre'} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
	} else {
		$self->{'genre'} = 'Podcast';
	}
	$self->{'cnt'} = scalar @{$self->{'streams'}};
	$self->{'Url'} = ($self->{'cnt'} > 0) ? $self->{'streams'}->[0] : '';
	$self->{'total'} = $self->{'cnt'};
	$self->{'imageurl'} = $self->{'iconurl'};
	if ($self->{'description'} =~ /\w/) {
		$self->{'description'} =~ s/\s+$//;
		$self->{'description'} =~ s/^\s+//;
	} else {
		$self->{'description'} = $self->{'title'};
	}
	foreach my $i (qw(title artist description genre)) {
		$self->{$i} = HTML::Entities::decode_entities($self->{$i});
		$self->{$i} = uri_unescape($self->{$i});
		$self->{$i} =~ s/(?:\%|\\?u?00)([0-9A-Fa-f]{2})/chr(hex($1))/egs;
	}
	print STDERR "-SUCCESS: 1st stream=".${$self->{'streams'}}[0]."=\n"  if ($DEBUG);
	if ($self->{'total'} > 0) {
		$self->{'playlist'} = "#EXTM3U\n";
		for (my $i=0;$i<$self->{'total'};$i++) {
			last  if ($i > $#epiTitles);
			$self->{'playlist'} .= "#EXTINF:-1, " . $epiTitles[$i]
					. "\n#EXTART:" . $self->{'artist'} . "\n";
			$self->{'playlist'} .= "#EXTGENRE:" . $self->{'genre'} . "\n"  if ($self->{'genre'});
			$self->{'playlist'} .= ${$self->{'streams'}}[$i] . "\n";
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
		if ($firstStream =~ /\breciva\b/ && defined $self->{'_reciva_ssl_opts'}) {
			foreach my $i (keys %{$self->{'_reciva_ssl_opts'}}) {
				$ua->ssl_opts($i, $self->{'_default_ssl_opts'}->{$i});
				print STDERR "--SSL OPTS SET2 ($i) BACK TO (".$self->{'_default_ssl_opts'}->{$i}.")!\n"  if ($DEBUG);
			}
		}
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
	return 'Apple';  #STATION TYPE (FOR PARENT StreamFinder MODULE).
}

sub getID
{
	my $self = shift;
	return $self->{'id'};  #STATION'S APPLE-ID.
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
	if ($self->{'iconurl'} =~ /\breciva\b/ && defined $self->{'_reciva_ssl_opts'}) {
		foreach my $i (keys %{$self->{'_reciva_ssl_opts'}}) {
			$ua->ssl_opts($i, $self->{'_default_ssl_opts'}->{$i});
			print STDERR "--SSL OPTS SET3 ($i) BACK TO (".$self->{'_default_ssl_opts'}->{$i}.")!\n"  if ($DEBUG);
		}
	}
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
	if ($self->{'imageurl'} =~ /\breciva\b/ && defined $self->{'_reciva_ssl_opts'}) {
		foreach my $i (keys %{$self->{'_reciva_ssl_opts'}}) {
			$ua->ssl_opts($i, $self->{'_default_ssl_opts'}->{$i});
			print STDERR "--SSL OPTS SET4 ($i) BACK TO (".$self->{'_default_ssl_opts'}->{$i}.")!\n"  if ($DEBUG);
		}
	}
	my $art_image = '';
	my $response = $ua->get($self->{'imageurl'});
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
	my $image_ext = $self->{'imageurl'};
	$image_ext = ($self->{'imageurl'} =~ /\.(\w+)$/) ? $1 : 'png';
	$image_ext =~ s/[^A-Za-z].*$//;
	return ($image_ext, $art_image);
}

1
