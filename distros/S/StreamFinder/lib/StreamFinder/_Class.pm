=head1 NAME

StreamFinder::_Class - Base module containing default methods common to all StreamFinder submodules.

=head1 AUTHOR

This module is Copyright (C) 2017-2021 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

NOTE:  This module is for internal use only by the other StreamFinder modules 
and should not be used directly.  Please see the main module (L<StreamFinder>) 
POD documentation for documentation for all the methods and how to use.

=cut

package StreamFinder::_Class;

use strict;
use warnings;
use URI::Escape;
use HTML::Entities ();
use LWP::UserAgent ();
use vars qw(@ISA @EXPORT);

my $DEBUG = 0;
my $bummer = ($^O =~ /MSWin/);
my $AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:91.0) Gecko/20100101 Firefox/91.0";

sub new
{
	my $class = shift;
	my $objname = shift;

	my $self = {'_objname' => $objname};

	my $homedir = $bummer ? $ENV{'HOMEDRIVE'} . $ENV{'HOMEPATH'} : $ENV{'HOME'};
	$homedir ||= $ENV{'LOGDIR'}  if ($bummer && $ENV{'LOGDIR'});
	$homedir =~ s#[\/\\]$##;
	my $configdir = (defined $ENV{STREAMFINDER}) ? $ENV{STREAMFINDER} : "${homedir}/.config/StreamFinder";
	$configdir =~ s#[\/\\]$##;
	@{$self->{'_userAgentOps'}} = ();
	foreach my $p ("${configdir}/config", "${configdir}/${objname}/config") {
		if (open IN, $p) {
			my ($atr, $val);
			while (<IN>) {
				chomp;
				next  if (/^\s*\#/o);
				($atr, $val) = split(/\s*\=\>\s*/o, $_, 2);
				eval "\$self->{'$atr'} = $val";  #CATCH JSON-LIKE ARGS, IE. "arg => {key => value, ...}"
				eval "\$self->{'$atr'} = \"\Q$val\E\""  if ($@);  #CATCH UNESCAPED ARGS, IE. "arg => str[with brackets,commas,etc.]"
			}
			close IN;
		}
	}
	foreach my $i (qw(agent from conn_cache default_headers local_address ssl_opts max_size
			max_redirect parse_head protocols_allowed protocols_forbidden requests_redirectable
			proxy no_proxy)) {
		push @{$self->{'_userAgentOps'}}, $i, $self->{$i}  if (defined $self->{$i});
	}
	push (@{$self->{'_userAgentOps'}}, 'agent', $AGENT)
			unless (defined $self->{'agent'});
	$self->{'timeout'} = 10  unless (defined $self->{'timeout'});
	$self->{'secure'} = 0    unless (defined $self->{'secure'});
	$self->{'log'} = '';
	$self->{'logfmt'} = '[time] [url] - [site]: [title] ([total])';

	while (@_) {
		if ($_[0] =~ /^\-?debug$/o) {
			shift;
			$self->{'debug'} = (defined($_[0]) && $_[0] =~/^[0-9]$/) ? shift : 1;
		} elsif ($_[0] =~ /^\-?secure$/o) {
			shift;
			$self->{'secure'} = (defined $_[0]) ? shift : 1;
		} elsif ($_[0] =~ /^\-?log$/o) {
			shift;
			$self->{'log'} = (defined $_[0]) ? shift : '';
		} elsif ($_[0] =~ /^\-?logfmt$/o) {
			shift;
			$self->{'logfmt'} = shift  if (defined $_[0]);
		} else {
			shift;
		}
	}
	$DEBUG = $self->{'debug'}  if (defined $self->{'debug'});
	$self->{'title'} = '';
	$self->{'artist'} = '';
	$self->{'album'} = '';
	$self->{'description'} = '';
	$self->{'created'} = '';
	$self->{'year'} = '';
	$self->{'genre'} = '';
	$self->{'iconurl'} = '';
	$self->{'imageurl'} = '';
	$self->{'articonurl'} = '';
	$self->{'artimageurl'} = '';
	$self->{'streams'} = [];
	$self->{'cnt'} = 0;
	$self->{'playlist_cnt'} = 0;
	$self->{'total'} = 0;
	$self->{'Url'} = '';
	$self->{'playlist'} = '';
	$self->{'albumartist'} = '';

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
		my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
		$ua->timeout($self->{'timeout'});
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
			$self->{'title'} = HTML::Entities::decode_entities($self->{'title'});
			$self->{'title'} = uri_unescape($self->{'title'});
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
	return $self->{'playlist_cnt'}  if (defined($_[0]) && $_[0] =~ /playlist/i);
	return $self->{'total'};  #TOTAL NUMBER OF PLAYABLE STREAM URLS FOUND.
}

sub getType
{
	my $self = shift;
	return $self->{'_objname'};  #STATION TYPE (FOR PARENT StreamFinder MODULE).
}

sub getID
{
	my $self = shift;
	return $self->{'fccid'}  if (defined($_[0]) && $_[0] =~ /fcc/i && defined($self->{'fccid'}));  #STATION'S CALL LETTERS OR IHEARTRADIO-ID.
	return $self->{'id'};
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
	return (defined($_[0]) && $_[0] =~ /^\-?artist/i)
			? $self->{'articonurl'} : $self->{'iconurl'};  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
}

sub getIconData
{
	my $self = shift;

	my $whichurl = (defined($_[0]) && $_[0] =~ /^\-?artist/i)
			? 'articonurl' : 'iconurl';
	return ()  unless ($self->{$whichurl});

	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $art_image = '';
	my $response = $ua->get($self->{$whichurl});
	if ($response->is_success) {
		$art_image = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
		my $no_wget = system('wget','-V');
		unless ($no_wget) {
			print STDERR "\n..trying wget...\n"  if ($DEBUG);
			my $iconUrl = $self->{$whichurl};
			$art_image = `wget -t 2 -T 20 -O- -o /dev/null \"$iconUrl\" 2>/dev/null `;
		}
	}
	return ()  unless ($art_image);

	(my $image_ext = $self->{$whichurl}) =~ s/^.+\.//;
	$image_ext =~ s/[^A-Za-z].*$//;

	return ($image_ext, $art_image);
}

sub getImageURL
{
	my $self = shift;
	return $self->{'imageurl'};  #URL TO THE STATION'S|CHANNEL'S BANNER IMAGE, IF ANY.
	return (defined($_[0]) && $_[0] =~ /^\-?artist/i)
			? $self->{'artimageurl'} : $self->{'imageurl'};  #URL TO THE STATION'S|CHANNEL'S BANNER IMAGE, IF ANY.
}

sub getImageData
{
	my $self = shift;

	my $whichurl = (defined($_[0]) && $_[0] =~ /^\-?artist/i)
			? 'artimageurl' : 'imageurl';
	return ()  unless ($self->{$whichurl});

	my $ua = LWP::UserAgent->new(@{$self->{'_userAgentOps'}});		
	$ua->timeout($self->{'timeout'});
	$ua->cookie_jar({});
	$ua->env_proxy;
	my $art_image = '';
	my $response = $ua->get($self->{$whichurl});
	if ($response->is_success) {
		$art_image = $response->decoded_content;
	} else {
		print STDERR $response->status_line  if ($DEBUG);
		my $no_wget = system('wget','-V');
		unless ($no_wget) {
			print STDERR "\n..trying wget...\n"  if ($DEBUG);
			my $iconUrl = $self->{$whichurl};
			$art_image = `wget -t 2 -T 20 -O- -o /dev/null \"$iconUrl\" 2>/dev/null `;
		}
	}
	return ()  unless ($art_image);
	my $image_ext = $self->{$whichurl};
	$image_ext = ($self->{$whichurl} =~ /\.(\w+)$/) ? $1 : 'png';
	$image_ext =~ s/[^A-Za-z].*$//;
	return ($image_ext, $art_image);
}

sub _log
{
	my $self = shift;
	my $inurl = shift;

	if ($self->{'log'} && open(LOG, '>>'.$self->{'log'})) {
		my $logline = $self->{'logfmt'};
		if ($logline =~ m/\[time\]/) {
			my $time = time;
			$logline =~ s/\[time\]/$time/;
		}
		$logline =~ s/\[stream\]/$self->{'total'} ? $$self{'Url'}: '-no streams!-'/e;
		$logline =~ s/\[site\]/$$self{'_objname'}/;
		$logline =~ s/\[url\]/$inurl/;
		foreach my $f (qw(title artist album description created year genre iconurl total albumartist)) {
			my $val = $self->{$f} || '-na-';
			$logline =~ s/\[$f\]/$val/;
		}
		my $sep = $bummer ? "\r\n" : "\n";
		print LOG $logline . $sep;
		close LOG;
	}
}

1
