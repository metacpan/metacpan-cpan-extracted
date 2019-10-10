=head1 NAME

StreamFinder::Reciva - Fetch actual raw streamable URLs from radio-station websites on Reciva.com

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
	
	my $genre = $station->{'genre'};

	print "Genre=$genre\n"  if ($genre);
	
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

StreamFinder::Reciva accepts a valid radio station ID or URL on 
radios.reciva.com and returns the actual stream URL(s), title, and cover 
art icon for that station.  The purpose is that one needs one of these URLs 
in order to have the option to stream the station in one's own choice of 
media player software rather than using their web browser and accepting any / 
all flash, ads, javascript, cookies, trackers, web-bugs, and other crapware 
that can come with that method of playing.  The author uses his own custom 
all-purpose media player called "fauxdacious" (his custom hacked version of 
the open-source "audacious" audio player.  "fauxdacious" incorporates this 
module to decode and play reciva.com streams.

One or more streams can be returned for each station.

NOTE:  reciva.com STILL uses the ancient SSL TLSv1, which LWP::UserAgent 
no longer plays nice with without coaxing!  Therefore, if you don't have 
the fallback B<wget> installed, ie. M$-Windows users, etc. you will need to 
create a simple text config file named "~/.config/StreamFinder/Reciva/config 
and add the following line:

'reciva_ssl_opts' => {verify_hostname => 0, SSL_version => 'TLSv1'}

(See also L<CONFIGURATION FILES> below).  I'm NOT making that the default, 
since, they could FIX this at ANY TIME, breaking StreamFinder::Reciva!  
These options will ONLY be applied to reciva.com URLs, NOT the streams, 
etc. that are on other sites.  To specify opts for all URLs accessed by 
StreamFinder::Reciva, use 'ssl_opts' instead of 'reciva_ssl_opts'.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url> [, "debug" [ => 0|1|2 ]])

Accepts a reciva.com station ID or URL and creates and returns a new station 
object, or I<undef> if the URL is not a valid Reciva station or no streams 
are found.  The URL can be the full URL, 
ie. https://radios.reciva.com/station/I<station-id>, or just I<station-id>.

=item $station->B<get>()

Returns an array of strings representing all stream URLs found.

=item $station->B<getURL>([I<options>])

Similar to B<get>() except it only returns a single stream representing 
the first valid stream found.  

Current options are:  I<"random"> and I<"noplaylists">.  By default, the 
first ("best"?) stream is returned.  If I<"random"> is specified, then 
a random one is selected from the list of streams found.  
If I<"noplaylists"> is specified, and the stream to be returned is a 
"playlist" (.pls or .m3u? extension), it is first fetched and the first entry 
in the playlist is returned.  This is needed by Fauxdacious Mediaplayer.

=item $station->B<count>()

Returns the number of streams found for the station.

=item $station->B<getID>()

Returns the station's Reciva ID (numeric).

=item $station->B<getTitle>()

Returns the station's title (description).

=item $station->B<getIconURL>()

Returns the URL for the station's "cover art" icon image, if any.

=item $station->B<getIconData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc. and the actual icon image (binary data), if any.

=item $station->B<getImageURL>()

Returns the URL for the station's "cover art" banner image, which for 
Reciva stations is always the icon image, as Reciva does not support 
a separate banner image at this time.

=item $station->B<getImageData>()

Returns a two-element array consisting of the extension (ie. "png", 
"gif", "jpeg", etc. and the actual station's banner image (binary data).

=item $station->B<getType>()

Returns the station's type ("Reciva").

=back

=head1 CONFIGURATION FILES

=over 4

=item ~/.config/StreamFinder/Reciva/config

Optional text file for specifying various configuration options 
for a specific site (submodule).  Each option is specified on a 
separate line in the format below:

'option' => 'value' [,]

and the options are loaded into a hash used only by the specific 
(submodule) specified.  Valid options include 
I<-debug> => [0|1|2], and most of the L<LWP::UserAgent> options.  
Blank lines and lines starting with a "#" sign are ignored.

Among options valid for Reciva streams is the *.reciva.com - specific 
SSL options currently needed to access their servers described in 
the B<new()> function:

'reciva_ssl_opts' => {verify_hostname => 0, SSL_version => 'TLSv1'}

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

reciva

=head1 DEPENDENCIES

L<URI::Escape>, L<HTML::Entities>, L<LWP::UserAgent>

=head1 RECCOMENDS

wget

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

package StreamFinder::Reciva;

use strict;
use warnings;
use URI::Escape;
use HTML::Entities ();
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

	foreach my $p ("$ENV{HOME}/.config/StreamFinder/config", "$ENV{HOME}/.config/StreamFinder/Reciva/config") {
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
#	push (@userAgentOps, 'ssl_opts', {verify_hostname => 0, SSL_version => 'TLSv1'})
#			unless (defined $uops{'ssl_opts'});  #THIS STUPID SIGHT FORCES USE OF ANCIENT TLSv1?!
	$uops{'timeout'} = 10  unless (defined $uops{'timeout'});
	$DEBUG = $uops{'debug'}  if (defined $uops{'debug'});

	while (@_) {
		if ($_[0] =~ /^\-?debug$/o) {
			shift;
			$DEBUG = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
		}
	}	

	unless ($url =~ /^https?\:/) {
		$self->{'id'} = $url;
		$url = 'https://radios.reciva.com/station/' . $url;  #UNALTERED URL FOR ICON
	}
	(my $url2 = $url) =~ s#station\/(\d+).*$#streamer\?stationid\=$1\&streamnumber=0#;  #ALTERED URL (FOR STEP 2)
	$self->{'id'} ||= $1  if ($1);
	$self->{'id'} ||= $1  if ($url2 =~ /(\d\d+)/);
	return undef  unless ($self->{'id'});


	#NOTE:  THIS IS A 2-STEP FETCH:  1) FETCH THE UNALTERED URL TO GET THE ICON, 2) FETCH ALTERED ONE FOR STREAMS!:
	my $html = '';
	print STDERR "-0(Reciva): ID=".$self->{'id'}."= AGENT=".join('|',@userAgentOps)."=\n"  if ($DEBUG);
	my $ua = LWP::UserAgent->new(@userAgentOps);
	if (defined $uops{'reciva_ssl_opts'}) {
		my @sslkeys = $ua->ssl_opts();
		for (my $i=0;$i<=$#sslkeys;$i++) {
			$self->{'_default_ssl_opts'}->{$sslkeys[$i]} = $ua->ssl_opts($sslkeys[$i]);
		}
		my %reciva_ssl_ops = %{$uops{'reciva_ssl_opts'}};
		foreach my $i (keys %reciva_ssl_ops) {
			$i =~ s/^reciva_//o;
			$self->{'_reciva_ssl_opts'}->{$i} = $reciva_ssl_ops{$i};
			$ua->ssl_opts($i, $reciva_ssl_ops{$i});
		}
	}
	$ua->timeout($uops{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	print STDERR "i:STEP 1: FETCHING URL ($url)...\n"  if ($DEBUG);
	my $response = $ua->get($url);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
		my $no_wget = system('wget','-V');
		unless ($no_wget) {
			print STDERR "\n..trying wget0...\n"  if ($DEBUG);
			$html = `wget -t 2 -T 20 -O- -o /dev/null \"$url\" 2>/dev/null `;
		}
	}
	print STDERR "-1: html=$html=\n"  if ($DEBUG > 1);
	$self->{'title'} = '';
	$self->{'iconurl'} = '';
	if ($html) {  #STEP 1 SUCCEEDED, FETCH ICON URL:
		my $stationID = $self->{'id'};
		$self->{'iconurl'} = ($html =~ m#stationid\=\"\d+\"\s+href\=\"\/station\/${stationID}\"\>\s*\<img\s+src\=\"([^\"]*)#s) ? $1 : '';
		$self->{'imageurl'} = $self->{'iconurl'};
		$html =~ s/\\\"/\&quot\;/gs;
		$self->{'title'} = ($html =~ m#\<th\s+class\=\"stationName\s+spec\"\s+>\s*([^\<]+)#) ? $1 : '';
		my $genreDiv = ($html =~ m#\<div\s+class\=\"genre\"\>(.+?)\<\/#s) ? $1 : '';
		$genreDiv =~ s#^\s*\<[^\>]*\>?##s;
		print STDERR "--GENRE:=$genreDiv=\n"  if ($DEBUG);
		$self->{'genre'} = $genreDiv  if ($genreDiv =~ /\w/);
		print STDERR "i:ICONURL FOUND=".$self->{'iconurl'}."= TITLE=".$self->{'title'}."=\n"  if ($DEBUG);
		$html = '';
	}
	$self->{'imageurl'} = $self->{'iconurl'};

	print STDERR "i:STEP 2: FETCHING URL ($url2)...\n"  if ($DEBUG);
	$response = $ua->get($url2);
	if ($response->is_success) {
		$html = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
		my $no_wget = system('wget','-V');
		unless ($no_wget) {
			print STDERR "\n..trying wget1...\n"  if ($DEBUG);
			$html = `wget -t 2 -T 20 -O- -o /dev/null \"$url2\" 2>/dev/null `;
		}
	}
	print STDERR "-2: html=$html=\n"  if ($DEBUG > 1);
	return undef  unless ($html);  #STEP 1 FAILED, INVALID STATION URL, PUNT!

	my @streams;
	$self->{'cnt'} = 0;
	$html =~ s/\\\"/\&quot\;/gs;
	$self->{'title'} = $1  if (!$self->{'title'} && $html =~ m#Playing:\s*([^\<]+)#);
	$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
	$self->{'title'} = uri_unescape($self->{'title'});
	$self->{'description'} = $self->{'title'};
	my $stream = '';
	my $plshtml = '';
	if (defined $self->{'_reciva_ssl_opts'}) {
		foreach my $i (keys %{$self->{'_reciva_ssl_opts'}}) {
			$ua->ssl_opts($i, $self->{'_default_ssl_opts'}->{$i});
			print STDERR "--SSL OPTS SET2 ($i) BACK TO (".$self->{'_default_ssl_opts'}->{$i}.")!\n"  if ($DEBUG);
		}
	}
	while ($html =~ s/\<iframe\s+src\=\"(\w+\:\/[^\"]+)//io) {  #FIND ONE (OR MORE) STREAM URLS:
		$stream = $1;
		if ($stream =~ /\.pls/io) {
			print STDERR "---fetching pls stream ($stream) for unrolling...\n"  if ($DEBUG);
			$response = $ua->get($stream);
			if ($response->is_success) {
				$plshtml = $response->decoded_content;
			} else {
				$plshtml = '';
				print STDERR $response->status_line  if ($DEBUG);
				my $no_wget = system('wget','-V');
				unless ($no_wget) {
					print STDERR "\n..trying wget2...\n"  if ($DEBUG);
					$plshtml = `wget -t 2 -T 20 -O- -o /dev/null \"$stream\" 2>/dev/null `;
				}
			}
			if ($plshtml)	{
				while ($plshtml =~ s#File\d+\=(\S+)##) {
					print STDERR "-----5: Adding PLS stream ($1)!\n"  if ($DEBUG);
					push @streams, $1;
					++$self->{'cnt'};
				}
			} else {
				print STDERR "-----5a: Adding stream ($stream) !\n"  if ($DEBUG);
				push @streams, $stream;  #COUNDN'T FETCH, LET "-noplaylists" SORT IT OUT!
				++$self->{'cnt'};   #NUMBER OF Streams FOUND
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
			print STDERR "---fetching livestream ($stream)...\n"  if ($DEBUG);
			$response = $ua->get($stream);
			if ($response->is_success) {
				$plshtml = $response->decoded_content;
			} else {
				$plshtml = '';
				print STDERR $response->status_line  if ($DEBUG);
				my $no_wget = system('wget','-V');
				unless ($no_wget) {
					print STDERR "\n..trying wget3...\n"  if ($DEBUG);
					$plshtml = `wget -t 2 -T 20 -O- -o /dev/null \"$stream\" 2>/dev/null `;
				}
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
	my $self = shift;
	my $arglist = (defined $_[0]) ? join('|',@_) : '';
	my $idx = ($arglist =~ /\b\-?random\b/) ? int rand scalar @{$self->{'streams'}} : 0;
	if ($arglist =~ /\b\-?noplaylists\b/ && ${$self->{'streams'}}[$idx] =~ /\.(pls|m3u8?)$/i) {
		my $plType = $1;
		my $firstStream = ${$self->{'streams'}}[$idx];
		print STDERR "-getURL($idx): NOPLAYLISTS and (".${$self->{'streams'}}[$idx].")\n"  if ($DEBUG);
		my $ua = LWP::UserAgent->new(@userAgentOps);	
		$ua->timeout($uops{'timeout'});
		$ua->cookie_jar({});
		$ua->env_proxy;
		if ($firstStream =~ /\breciva\b/ && defined $self->{'_reciva_ssl_opts'}) {
			foreach my $i (keys %{$self->{'_reciva_ssl_opts'}}) {
				$ua->ssl_opts($i, $self->{'_reciva_ssl_opts'}->{$i});
				print STDERR "--SSL OPTS SET4 ($i) TO (".$self->{'_reciva_ssl_opts'}->{$i}.")!\n"  if ($DEBUG);
			}
		}
		my $html = '';
		my $response = $ua->get($firstStream);
		if ($response->is_success) {
			$html = $response->decoded_content;
		} else {
			print STDERR $response->status_line  if ($DEBUG);
			my $no_wget = system('wget','-V');
			unless ($no_wget) {
				print STDERR "\n..trying wget4...\n"  if ($DEBUG);
				$html = `wget -t 2 -T 20 -O- -o /dev/null \"$firstStream\" 2>/dev/null `;
			}
		}
		my @lines = split(/\r?\n/, $html);
		$firstStream = '';
		if ($plType =~ /pls/) {  #PLS:
			my $firstTitle = '';
			foreach my $line (@lines) {
				if ($line =~ m#^\s*File\d+\=(.+)$#) {
					$firstStream ||= $1;
				} elsif ($line =~ m#^\s*Title\d+\=(.+)$#) {
					$firstTitle ||= $1;
				}
			}
			$self->{'title'} ||= $firstTitle;
			print STDERR "-getURL(PLS): first=$firstStream= title=$firstTitle=\n"  if ($DEBUG);
		} else {  #m3u8:
			(my $urlpath = ${$self->{'streams'}}[$idx]) =~ s#[^\/]+$##;
			foreach my $line (@lines) {
				if ($line =~ m#^\s*([^\#].+)$#) {
					my $urlpart = $1;
					$urlpart =~ s#^\s+##;
					$urlpart =~ s#^\/##;
					$firstStream = ($urlpart =~ m#https?\:#) ? $urlpart : ($urlpath . '/' . $urlpart);
					last;
				}
			}
			print STDERR "-getURL(m3u?): first=$firstStream=\n"  if ($DEBUG);
		}
		return $firstStream || ${$self->{'streams'}}[$idx];
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
	return 'Reciva';  #STATION TYPE (FOR PARENT StreamFinder MODULE).
}

sub getID
{
	my $self = shift;
	return $self->{'id'};  #STATION'S RECIVA-ID.
}

sub getTitle
{
	my $self = shift;
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
			$ua->ssl_opts($i, $self->{'_reciva_ssl_opts'}->{$i});
			print STDERR "--SSL OPTS SET5 ($i) TO (".$self->{'_reciva_ssl_opts'}->{$i}.")!\n"  if ($DEBUG);
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
			print STDERR "\n..trying wget5...\n"  if ($DEBUG);
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
			$ua->ssl_opts($i, $self->{'_reciva_ssl_opts'}->{$i});
			print STDERR "--SSL OPTS SET6 ($i) TO (".$self->{'_reciva_ssl_opts'}->{$i}.")!\n"  if ($DEBUG);
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
			print STDERR "\n..trying wget6...\n"  if ($DEBUG);
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
