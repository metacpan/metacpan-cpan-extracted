# Copyright (c) 2008 Behan Webster. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

package TVDB::API;

require 5.008008;
use strict;

use Compress::Zlib;
use DBM::Deep;
use Data::Dumper;
use Debug::Simple;
use Encode qw(encode decode);
use IO::Uncompress::Unzip;
use LWP;
use Storable;
use XML::Simple;

use vars qw($VERSION %Defaults %Url);

$VERSION = "0.33";

# TheTVDB Urls
%Url = (
	defaultURL	=> 'http://thetvdb.com',
	getSeriesID	=> '%s/api/GetSeries.php?seriesname=%s&language=%s',	# defaultURL, series_name, language
	getMirrors	=> '%s/api/%s/mirrors.xml',			# defaultURL, apikey
	bannerURL	=> '%s/banners/',				# baseBannerURL, append bannerFilename.ext
	apiURL		=> '%s/api/%s',					# mirrorURL, apikey
	getLanguages	=> '%s/languages.xml',				# apiURL
	getSeries	=> '%s/series/%s/%s.xml',			# apiURL, seriesid, language
	getSeriesAll	=> '%s/series/%s/all/%s.%s',			# apiURL, seriesid, language, (xml|zip)
	getSeriesActors	=> '%s/series/%s/actors.xml',			# apiURL, seriesid
	getSeriesBanner	=> '%s/series/%s/banners.xml',			# apiURL, seriesid
	getEpisode	=> '%s/series/%s/default/%s/%s/%s.xml',		# apiURL, seriesid, season, episode, language
	getEpisodeDVD	=> '%s/series/%s/dvd/%s/%s/%s.xml',		# apiURL, seriesid, season, episode, language
	getEpisodeAbs	=> '%s/series/%s/absolute/%s/%s.xml',		# apiURL, seriesid, absolute_episode, language
	getEpisodeID	=> '%s/episodes/%s/%s.xml',			# apiURL, episodeid, language
	getUpdates	=> '%s/updates/updates_%s.%s',			# apiURL, (day|week|month|all), (xml|zip)

	getEpisodeByAirDate	=> '%s/api/GetEpisodeByAirDate.php?apikey=%s&seriesid=%s&airdate=%s&language=%s',
	getRatingsForUser	=> '%s/api/GetRatingsForUser.php?apikey=%s&accountid=%s&seriesid=%s',
	getRatingsForUserAll	=> '%s/api/GetRatingsForUser.php?apikey=%s&accountid=%s',
);

%Defaults = (
	maxSeason		=> 50,
	maxEpisode		=> 50,
	minUpdateTime	=> 3600*6,		# 6 hours 
	minBannerTime	=> 3600*24*7,	# 1 week 
	minEpisodeTime	=> 3600*24*7,	# 1 week 
);

###############################################################################
sub new {
	my $self = bless {};
	%{$self->{conf}} = %Defaults;

	my $args;
	if (ref $_[0] eq 'HASH') {
		# Subroutine arguments by hashref
		$args = shift;
	} else {
		# Traditional subroutine arguments
		$args = {};
		($args->{apikey}, $args->{lang}, $args->{cache}, $args->{banner}, @{$args->{mirrors}}) = @_;
	}
	# Argument defaults
	$args->{cache}     ||= "$ENV{HOME}/.tvdb.db";
	$args->{apikey}    ||= die 'You need to get an apikey from http://thetvdb.com/?tab=apiregister';
	$args->{useragent} ||= "TVDB::API/$VERSION";

	$self->setCacheDB($args->{cache});
	$self->setApiKey($args->{apikey});
	$self->{ua} = LWP::UserAgent->new;
	$self->{ua}->env_proxy();
	$self->setUserAgent($args->{useragent});
	$self->{xml} = XML::Simple->new(
		ForceArray => ['Actor', 'Banner', 'Episode', 'Mirror', 'Series'],
		SuppressEmpty => 1,
	);

	if (@{$args->{mirrors}}) {
		$self->setMirrors(@{$args->{mirrors}});
	} else {
		$self->chooseMirrors();
	}

	# The following must be after setCacheDB/setApiKey/setUserAgent/xml/setMirrors
	$self->setLang($args->{lang});
	$self->setBannerPath($args->{banner}) if $args->{banner};

	return $self;
}

###############################################################################
sub setApiKey {
	my ($self, $apikey) = @_;
	$self->{apikey} = $apikey;
	$self->_updateUrls();
}
sub setLang {
	my $self = shift;
	my $lang = shift || 'en';
	my $langs = $self->getAvailableLanguages();
	&verbose(3, "TVDB::API: Setting language to: $lang => $langs->{$lang}->{name}\n");
	$self->{lang} = $lang;
}
sub setMirrors {
	my $self = shift;
	$self->{mirror} = shift || $Url{defaultURL};
	$self->{banner} = shift || $self->{mirror} || '';
	$self->{zip} = shift || $self->{mirror} || '';
	&verbose(3, "TVDB::API: Setting mirrors to: xml:$self->{mirror} banner:$self->{banner} zip:$self->{zip}\n");
	$self->_updateUrls();
}
sub _updateUrls {
	my ($self) = @_;
	$self->{apiURL} = sprintf $Url{apiURL}, $self->{mirror}, $self->{apikey};
	$self->{bannerURL} = sprintf $Url{bannerURL}, $self->{banner};
	$self->{zipURL} = sprintf $Url{apiURL}, $self->{zip}, $self->{apikey};
}
sub setUserAgent {
	my ($self, $userAgent) = @_;
	$self->{ua}->agent($userAgent);
}
sub setBannerPath {
	my ($self, $path) = @_;
	$self->{bannerPath} = $path;
	mkdir $path;
	return -d $path;
}

###############################################################################
sub setCacheDB {
	my ($self, $cache) = @_;
	$self->{cachefile} = $cache;
	$self->{cache} = DBM::Deep->new(
		file => $cache,
		#filter_store_key => \&_compressCache,
		filter_store_value => \&_compressCache,
		#filter_fetch_key => \&_decompressCache,
		filter_fetch_value => \&_decompressCache,
		utf8 => 1,
	);
}
sub _compressCache {
	# Escape UTF-8 chars and gzip data
	return Compress::Zlib::memGzip(encode('utf8',$_[0])) ;
}
sub _decompressCache {
	# Decompress data and then unescape UTF-8 chars
	return decode('utf8',Compress::Zlib::memGunzip($_[0])) ;
}
sub dumpCache {
	my ($self) = @_;
	my $cache = $self->{cache};
	print Dumper($cache);
}

###############################################################################
sub setConf {
	my ($self, $key, $value) = @_;
	if (ref $key eq 'HASH') {
		while (my ($k, $v) = each %$key) {
			$self->{conf}->{$k} = $v;
		}
	} else {
		$self->{conf}->{$key} = $value;
	}
}
sub getConf {
	my ($self, $key) = @_;
	return $self->{conf}->{$key} if $key && defined $self->{conf}->{$key};
	return $self->{conf};
}

###############################################################################
# Download binary data
sub _download {
	my ($self, $fmt, $url, @parm) = @_;

	# Make URL
	$url = sprintf($fmt, $url, @parm);
	&verbose(2, "TVDB::API: download: $url\n");
	utf8::encode($url);

	# Make sure we only download once even in a session
	return $self->{dload}->{$url} if defined $self->{dload}->{$url};

	# Download URL
	my $req = HTTP::Request->new(GET => $url);
	my $res = $self->{ua}->request($req);

	if ($res->content =~ /(?:404 Not Found|The page your? requested does not exist)/i) {
		&warning("TVDB::API: download $url, 404 Not Found\n");
		$self->{dload}->{$url} = 0;
		return undef;
	}
	$self->{dload}->{$url} = $res->content;
	return $res->content;
}
# Download Xml, remove empty tags, parse XML, and return hashref
sub _downloadXml {
	my ($self, $fmt, @parm) = @_;

	# Download XML file
	my $xml = $self->_download($fmt, $self->{apiURL}, @parm, 'xml');
	return undef unless $xml;

	# Remove empty tags
	$xml =~ s/(<[^\/\s>]*\/>|<[^\/\s>]*><\/[^>]*>)//gs;

	# Return process XML into hashref
	return $self->{xml}->XMLin($xml);
}
# Download Xml, remove empty tags, parse XML, and return hashref
sub _downloadApikeyXml {
	my ($self, $fmt, @parm) = @_;

	# Download XML file
	my $xml = $self->_download($fmt, $self->{mirror}, $self->{apikey}, @parm);
	return undef unless $xml;

	$xml =~ s/seriesid>/id>/g;

	# Remove empty tags
	$xml =~ s/(<[^\/\s>]*\/>|<[^\/\s>]*><\/[^>]*>)//gs;

	# Return process XML into hashref
	return $self->{xml}->XMLin($xml);
}
# Download Zip file, decompress into one Xml file, remove empty tags, parse XML, and return hashref
sub _downloadZip {
	my ($self, $fmt, @parm) = @_;

	# Download XML file
	my $zip = $self->_download($fmt, $self->{zipURL}, @parm, 'zip');
	return undef unless $zip;

	# Uncompress ZIP
	my $url = sprintf($fmt, $self->{zipURL}, @parm, 'zip');
	my $obj = new IO::Uncompress::Unzip \$zip, MultiStream => 1, Transparent => 1
		or die "IO::Uncompress::Unzip failed: $url\n";
	local $/ = undef;
	my $xml = <$obj>;

	# Make en.xml/banners.xml/actors.xml into one xml file
	if ($xml =~ s/<\/Data><\?xml.*?Banners>|<\/Banners><\?xml.*?Actors>//gs) {
		$xml =~ s/<\/Actors>$/<\/Data>/s;
	}

	# Remove empty tags
	$xml =~ s/(<[^\/\s>]*\/>|<[^\/\s>]*><\/[^>]*>)//gs;

	&debug(4, "download Zip: $url\n", XML => \$xml);

	# Return process XML into hashref
	return $self->{xml}->XMLin($xml);
}

###############################################################################
sub getAvailableMirrors {
	my ($self, $nocache) = @_;

	my $cache = $self->{cache};
	if ($nocache || not defined $cache->{Mirror}) {
		# Get list of mirrors
		my $xml = $self->_download($Url{getMirrors}, $Url{defaultURL}, $self->{apikey});
		my $data = XMLin($xml, ForceArray=>['Mirror']);

		# Break into lists of mirror types: xml/banner/zip
		$self->{cache}->{Mirror} = {};
		while (my ($key,$value) = each %{$data->{Mirror}}) {
			my ($typemask, $url) = ($value->{typemask}, $value->{mirrorpath});
			if ($typemask >= 4) { $typemask -= 4; push @{$cache->{Mirror}->{xml}}, $url; }
			if ($typemask >= 2) { $typemask -= 2; push @{$cache->{Mirror}->{banner}}, $url; }
			if ($typemask >= 1) { $typemask -= 1; push @{$cache->{Mirror}->{zip}}, $url; }
		}
	}

	# Return hashref of arrays
	return $cache->{Mirror};
}
sub _rand {
	my ($list) = @_;
	# Return random entry from array
	return $list->[int(rand($#$list + 1))];
}
sub chooseMirrors {
	my ($self, $nocache) = @_;
	my $mirrors = $self->getAvailableMirrors($nocache);
	$self->setMirrors(
		&_rand($mirrors->{xml}),
		&_rand($mirrors->{banner}),
		&_rand($mirrors->{zip}),
	);
}

###############################################################################
sub getAvailableLanguages {
	my ($self, $nocache) = @_;

	if ($nocache || not defined $self->{cache}->{Language}) {
		# Download languags XML and process into a hashref
		my $xml = $self->_download($Url{getLanguages}, $self->{apiURL});
		my $data = XMLin($xml, KeyAttr => 'abbreviation');
		$self->{cache}->{Language} = $data->{Language};
	}

	return $self->{cache}->{Language};
}

sub _mtime {
	my ($filename) = @_;
	my @stat = stat($filename);
	return $stat[9];
}

###############################################################################
sub getUpdates {
	my $self = shift;
	my $period = lc shift || 'guess';

	# Determin which update xml file to download
	my $now = time;
	if ($period =~ /^(guess|now)$/) {
		my $diff = $now - $self->{cache}->{Update}->{lastupdated};
		if ($period eq 'guess' && $diff <= $self->{conf}->{minUpdateTime}) {
			# We've updated recently (within 6 hours)
			return;
		} elsif ($diff <= 86400) {	# 1 day in seconds
			$period = 'day';
		} elsif ($diff <= 604800) {	# 1 week in seconds
			$period = 'week';
		} elsif ($diff <= 2592000) {	# 1 month in seconds
			$period = 'month';
		} else  {
			$period = 'all';
		}
	}
	unless ($period =~/^(day|week|month|all)$/) {
		die "Invalid period when calling getUpdates: $period\n";
	}

	# Download appropriate update file
	&verbose(1, "TVDB::API: Downloading $period updates\n");
	my $updates = $self->_downloadZip($Url{getUpdates}, $period);
	return undef unless $updates;

	# Series updates
	my $series = $self->{cache}->{Series};
	while (my ($sid,$data) = each %{$updates->{Series}}) {
		# Don't update if we don't already have this series
		next unless defined $series->{$sid};
		# Only update if there is a more recent version
		if ($data->{time} > $series->{$sid}->{lastupdated}) {
			if ($period eq 'all') {
				# all updates don't include Episodes, so the complete series record is downloaded
				$self->getSeriesAll($sid, 1);
			} else {
				$self->getSeries($sid, 1);
			}
		}
	}

	# Episodes updates
	my $episodes = $self->{cache}->{Episode};
	while (my ($eid,$ep) = each %{$updates->{Episode}}) {
		# Don't update if we don't already have this series
		next unless defined $series->{$ep->{Series}};
		# Get it if we don't already have it
		unless (defined $episodes->{$eid}
			# Or, update if there is a more recent version
			and $ep->{time} > $episodes->{$eid}->{lastupdated}
		) {
			$self->getEpisodeId($eid, 1);
		}
	}

	# Banners updates
	my $banners = $self->{cache}->{Banner};
	if (defined $self->{bannerPath}) {
		for my $banner (@{$updates->{Banner}}) {
			# Don't update if we don't already have this series
			next unless defined $series->{$banner->{Series}};
			# Don't update if we haven't already downloaded this banner
			my $filename = "$self->{bannerPath}/$banner->{path}";
			next unless -f $filename;
			# Don't update if it isn't newer
			next unless -z $filename || $banner->{time} > &_mtime($filename);
			$self->getBanner($banner->{path}, undef, 1);
		}
	}

	# Save when we last updated, now that we've successfully done so
	$self->{cache}->{Update}->{lastupdated} = $now;
	$self->{cache}->{Update}->{lasttime} = $updates->{time};
}

###############################################################################
# Fill in the blank
sub getPossibleSeriesId {
	my ($self, $name) = @_;

	&verbose(2, "TVDB::API: Get possbile series id for $name\n");
	my $xml = $self->_download($Url{getSeriesID}, $Url{defaultURL}, $name, $self->{lang});
	return undef unless $xml;
	my $data = XMLin($xml, ForceArray=>['Series'], KeyAttr=>{});

	# Build hashref to return
	my $ret = {};
	for my $series (@{$data->{Series}}) {
		my $sid = $series->{id};
		if (defined $ret->{$sid}) {
			$ret->{$sid}->{altlanguage} = {};
			$ret->{$sid}->{altlanguage}->{$series->{language}} = $series;
		} else {
			$ret->{$sid} = $series;
		}
	}

	return $ret;
}

###############################################################################
# Fill in the blank
sub getSeriesId {
	my ($self, $name, $nocache) = @_;
	return undef unless defined $name;

	# see if $name is a series id already
	return $name if $name =~ /^\d+$/ && $name > 70000;

	# See if it's in the series cache
	my $cache = $self->{cache};
	if (!$nocache && defined $cache->{Name2Sid}->{$name}) {
		#print "From SID Cache: $name -> $cache->{Name2Sid}->{$name}\n";
		return undef unless $cache->{Name2Sid}->{$name};
		return $cache->{Name2Sid}->{$name};
	}

	my $data = $self->getPossibleSeriesId($name);

	# Look through list of possibilities
	if ($data) {
		while (my ($sid,$series) = each %$data) {
			if ($series->{SeriesName} =~ /^(The )?\Q$name\E(, The)?$/i) {
				$cache->{Name2Sid}->{$name} = $sid;
				return $sid;
			}
		}
	}

	# Nothing found, assign 0 to name so we cache this result
	&warning("TBDB::API: No series id found for: $name\n");
	$cache->{Name2Sid}->{$name} = 0; # Not undef as that messes up DBM::Deep
	return undef;
}

###############################################################################
# Get series/lang.xml for series
sub getSeries {
	my ($self, $name, $nocache) = @_;
	&debug(2, "getSeries: $name, $nocache\n");

	my $sid = $self->getSeriesId($name, $nocache?$nocache-1:0);
	return undef unless $sid;

	my $series = $self->{cache}->{Series};
	if (defined $series->{$sid} && $series->{$sid}->{Seasons}) {
		# Get updated series data
		if ($nocache) {
			&verbose(1, "TVDB::API: Updating series: $sid => $series->{$sid}->{SeriesName}\n");
			my $data = $self->_downloadXml($Url{getSeries}, $sid, $self->{lang});
			return undef unless $data;

			# Copy updated series into cache
			while (my ($key,$value) = each %{$data->{Series}->{$sid}}) {
				$series->{$sid}->{$key} = $value;
			}

		# From cache
		} else {
			&debug(2, "From Series Cache: $sid\n");
		}

	# Get full series data
	} else {
		$self->getSeriesAll($sid, 1);
	}

	return $series->{$sid};
}

###############################################################################
# Get series/all/lang.zip for series
sub getSeriesAll {
	my ($self, $name, $nocache) = @_;
	&debug(2, "getSeriesAll: $name, $nocache\n");

	my $sid = $self->getSeriesId($name, $nocache?$nocache-1:0);
	return undef unless $sid;

	# Get series data
	my $series = $self->{cache}->{Series};
	if (!$nocache && defined $series->{$sid} && $series->{$sid}->{Seasons}) {
		&debug(2, "From Series Cache: $sid\n");

	# Download full series data
	} else {
		&verbose(1, "TVDB::API: Downloading full series: $sid".(defined $series->{$sid}?" => $series->{$sid}->{SeriesName}":'')."\n");
		my $data = $self->_downloadZip($Url{getSeriesAll}, $sid, $self->{lang});
		return undef unless $data;

		# Copy series into cache
		#@{$series->{$sid}}{keys %{$data->{Series}->{$sid}}} = values %{$data->{Series}->{$sid}};
		if (defined $series->{$sid}) {
			while (my ($key,$value) = each %{$data->{Series}->{$sid}}) {
				$series->{$sid}->{$key} = $value;
			}
		} else {
			$self->{cache}->{Series}->{$sid} = $data->{Series}->{$sid};
		}

		# Copy episodes into cache
		while (my ($eid,$ep) = each %{$data->{Episode}}) {
			$series->{$sid}->{Seasons} = [] unless $series->{$sid}->{Seasons};
			#print "Season: $ep->{SeasonNumber} $series->{$sid}->{Seasons}->[$ep->{SeasonNumber}]\n";
			$series->{$sid}->{Seasons}->[$ep->{SeasonNumber}]->[$ep->{EpisodeNumber}] = $eid;
			$self->{cache}->{Episode}->{$eid} = $ep;
		}

		# Save actors
		$series->{$sid}->{Actor} = $data->{Actor};

		# Save banners
		$series->{$sid}->{Banner} = $data->{Banner};
	}

	return $series->{$sid};
}

###############################################################################
sub getSeriesName {
	my ($self, $sid, $nocache) = @_;

	my $series = $self->getSeries($sid, $nocache);
	return undef unless $series;

	return $series->{SeriesName};
}

###############################################################################
# Get series/actors.xml for Series
sub getSeriesActors {
	my ($self, $name, $nocache) = @_;

	my $sid = $self->getSeriesId($name, $nocache?$nocache-2:0);
	return undef unless $sid;
	my $series = $self->getSeries($sid, $nocache?$nocache-1:0);
	return undef unless $series;

	# Get actors data
	if ($nocache or not $series->{Actor}) {
		&verbose(1, "TVDB::API: Get actors: $series->{SeriesName}\n");
		my $data = $self->_downloadXml($Url{getSeriesActors}, $sid);
		return undef unless $data;

		# Copy updated series into cache
		$self->{cache}->{Series}->{$sid}->{Actor} = $data->{Actor};

	# From cache
	} else {
		&debug(2, "From Actors Cache: $series->{SeriesName}\n");
	}

	return $series->{Actor};
}

###############################################################################
sub getSeriesActorsSorted {
	my ($self, $name, $nocache) = @_;
	my $data = $self->getSeriesActors($name, $nocache);
	my @sorted = sort {
		$a->{SortOrder} <=> $b->{SortOrder}
		&& $a->{Role} cmp $b->{Role}
		&& $a->{Name} cmp $b->{Name}
	} values %$data;
	return \@sorted;
}

###############################################################################
# Get series/banners.xml for Series
sub getSeriesBanners {
	my ($self, $name, $type, $type2, $value, $nocache) = @_;

	my $sid = $self->getSeriesId($name, $nocache?$nocache-2:0);
	return undef unless $sid;
	my $series = $self->getSeries($sid, $nocache?$nocache-1:0);
	return undef unless $series;

	# Get banner data
	if ($nocache or not $series->{Banner}) {
		&verbose(1, "TVDB::API: Get banners: $series->{SeriesName}\n");
		my $data = $self->_downloadXml($Url{getSeriesBanner}, $sid);
		return undef unless $data;

		# Copy updated series into cache
		$self->{cache}->{Series}->{$sid}->{Banner} = $data->{Banner};

	# From cache
	} else {
		&debug(2, "From Banners Cache: $series->{SeriesName}\n");
	}

	# Search banners
	my %banners;
	while (my ($id,$banner) = each %{$series->{Banner}}) {
		next unless $banner->{Language} =~ /$self->{lang}|en/;
		next unless !$type || $banner->{BannerType} eq $type;
		next unless !$type2 || $banner->{BannerType2} eq $type2;
		next unless !$value || $type eq 'season' && $banner->{Season} eq $value;
		$banners{$id} = $banner;
	}

	return \%banners;
}

###############################################################################
# Get info for Series
sub getSeriesInfo {
	my ($self, $name, $info, $nocache) = @_;

	my $data = $self->getSeries($name, $nocache);
	return undef unless $data;

	# Check that info is available
	unless (defined $data->{$info}) {
		#&warning("TBDB::API: No $info found for series $name\n");
		return undef;
	}

	return $data->{$info};
}

###############################################################################
sub getSeriesBanner {
	my ($self, $name, $buffer, $nocache) = @_;
	my $banner = $self->getSeriesInfo($name, 'banner', $nocache?$nocache-1:0);
	return undef unless $banner;
	return $self->getBanner($banner, $buffer, $nocache);
}
sub getSeriesFanart {
	my ($self, $name, $buffer, $nocache) = @_;
	my $banner = $self->getSeriesInfo($name, 'fanart', $nocache?$nocache-1:0);
	return undef unless $banner;
	return $self->getBanner($banner, $buffer, $nocache);
}
sub getSeriesPoster {
	my ($self, $name, $buffer, $nocache) = @_;
	my $banner = $self->getSeriesInfo($name, 'poster', $nocache?$nocache-1:0);
	return undef unless $banner;
	return $self->getBanner($banner, $buffer, $nocache);
}
sub getSeriesOverview {
	my ($self, $name, $nocache) = @_;
	return $self->getSeriesInfo($name, 'Overview', $nocache);
}

###############################################################################
sub _makedir {
	my $dir = shift;
	return unless $dir;

	# mkdir piece at a time
	unless( -d $dir ) {
		my $path;
		for my $part (split '/', $dir) {
			$path .= "$part/";
			unless (-e $path) {
				&debug([2,2,1], "mkdir $path\n");
				mkdir $path;
			}
		}
	}
}

###############################################################################
# get named banner. Download if not already. Read from cache if buffer provided.
sub getBanner {
	my ($self, $banner, $buffer, $nocache) = @_;

	return unless defined $self->{bannerPath};

	my $filename = "$self->{bannerPath}/$banner";

	# See if we tried to get this during the last week and failed
	if (-z $filename && (time - &_mtime($filename) < $self->{conf}->{minBannerTime})) {
		&verbose(2, "TVDB::API: download of $banner failed before\n");
		return undef;
	}

	if ($nocache || ! -s $filename) {
		my $buf;
		my $gfx = $buffer ? $buffer : \$buf;

		# Download banner (create zero length file if nothing downloaded)
		&verbose(1, "TVDB::API: Get banner $banner\n");
		$$gfx = $self->_download($self->{bannerURL}.$banner);
		&_makedir($1) if $filename =~ m|^(.*)/[^/]+$|;
		open(GFX, "> $filename") || die "$filename:$!";
		print GFX $$gfx;
		return undef unless $$gfx;

	} elsif ($buffer && -s $filename) {
		# get Banner from cache
		&debug(2, "From Banner Cache: $banner\n");
		open(GFX, "< $filename") || die "$filename:$!";
		local $/ = undef;
		$$buffer = <GFX>;
	}
	close GFX;

	return $banner;
}

###############################################################################
sub getMaxSeason {
	my ($self, $name, $nocache) = @_;
	$self->getUpdates(); # Update available episodes/seasons
	my $series = $self->getSeriesAll($name, $nocache?$nocache-1:0);
	return undef unless $series;
	return $#{$series->{Seasons}};
}

###############################################################################
sub getSeason {
	my ($self, $name, $season, $nocache) = @_;
	if ($season < 0 || $season > $self->{conf}->{maxSeason}) {
		&warning("TBDB::API: Invalid season $season for $name\n");
		return undef;
	}
	my $series = $self->getSeriesAll($name, $nocache?$nocache-1:0);
	return undef unless $series && $series->{Seasons};
	unless ($series->{Seasons}->[$season]) {
		$self->getUpdates();
		unless ($series->{Seasons}->[$season]) {
			&warning("TBDB::API: No season $season found for $name\n");
			#$series->{Seasons}->[$season] = 0;
			return undef;
		}
	}
	return $series->{Seasons}->[$season];
}

###############################################################################
sub getSeasonBanners {
	my ($self, $name, $season, $nocache) = @_;
	my $data = $self->getSeriesBanners($name, 'season', 'season', $season, $nocache);
	my @banners;
	while (my ($id,$banner) = each %$data) {
		push @banners, $banner->{BannerPath};
	}
	return sort @banners;
}
sub getSeasonBanner {
	my ($self, $name, $season, $buffer, $nocache) = @_;
	my @banners = $self->getSeasonBanners($name, $season, $nocache?$nocache-1:0);
	return undef unless @banners;
	return $self->getBanner($banners[0], $buffer, $nocache);
}

###############################################################################
sub getSeasonBannersWide {
	my ($self, $name, $season, $nocache) = @_;
	my $data = $self->getSeriesBanners($name, 'season', 'seasonwide', $season, $nocache);
	my @banners;
	while (my ($id,$banner) = each %$data) {
		push @banners, $banner->{BannerPath};
	}
	return sort @banners;
}
sub getSeasonBannerWide {
	my ($self, $name, $season, $buffer, $nocache) = @_;
	my @banners = $self->getSeasonBannersWide($name, $season, $nocache?$nocache-1:0);
	return undef unless @banners;
	return $self->getBanner($banners[0], $buffer, $nocache);
}

###############################################################################
sub getMaxEpisode {
	my ($self, $name, $season, $nocache) = @_;
	$self->getUpdates(); # Update available episodes/seasons
	my $data = $self->getSeason($name, $season, $nocache);
	return undef unless $data;
	return $#$data;
}

###############################################################################
sub getEpisode {
	my ($self, $name, $season, $episode, $nocache) = @_;
	if ($episode < 0 || $episode > $self->{conf}->{maxEpisode}) {
		&warning("TBDB::API: Invalid episode $episode in season $season for $name\n");
		return undef;
	}
	my $sid = $self->getSeriesId($name);
	my $data = $self->getSeason($sid, $season, $nocache?$nocache-1:0);
	return undef unless $data;

	# See if we have to update the episode record
	my $cache = $self->{cache};
	my $series = $cache->{Series};
	my $eid = $data->[$episode] if defined $data->[$episode];
	if (ref($eid) ne '' && (time - $eid->{lasttried}) < $self->{conf}->{minEpisodeTime}) {
		&verbose(2, "TBDB::API: No episode $episode found for season $season of $name (cached)\n");
		return undef;
	}
	unless (!$nocache && $eid && !ref($eid) && $cache->{Episode}->{$eid}) {
		# Download episode
		&verbose(1, "TVDB::API: Updating episode $episode from season $season for $name\n");
		my $new = $self->_downloadXml($Url{getEpisode}, $sid, $season, $episode, $self->{lang});

		if ($new) {
			# Save episode in cache
			($eid, my $ep) = each %{$new->{Episode}};
			$series->{$sid}->{Seasons} = [] unless $series->{$sid}->{Seasons};
			$series->{$sid}->{Seasons}->[$season]->[$episode] = $eid;
			$cache->{Episode}->{$eid} = $ep;
		} else {
			$eid = 0;
			$series->{$sid}->{Seasons}->[$season]->[$episode] = {};
			$series->{$sid}->{Seasons}->[$season]->[$episode]->{lasttried} = time;
		}
	}

	# Check again (if it's been updated)
	unless ($eid && defined $cache->{Episode}->{$eid}) {
		&warning("TBDB::API: No episode $episode found for season $season of $name\n");
		return undef;
	}

	return $cache->{Episode}->{$eid};
}

###############################################################################
sub getEpisodeAbs {
	my ($self, $name, $abs, $nocache) = @_;
	if ($abs < 0 || $abs > $self->{conf}->{maxEpisode}*$self->{conf}->{maxSeason}) {
		&warning("TBDB::API: Invalid absolute episode $abs for $name\n");
		return undef;
	}
	my $sid = $self->getSeriesId($name);
	return undef unless $sid;
	my $series = $self->getSeriesAll($sid, $nocache?$nocache-1:0);
	return undef unless $series;

	# Look for episode in cache
	my $cache = $self->{cache};
	unless ($nocache) {
		foreach my $season (@{$series->{Seasons}}) {
			foreach my $eid (@$season) {
				next unless $eid;
				my $ep = $cache->{Episode}->{$eid};
				return $ep if $ep->{absolute_number} eq $abs;
			}
		}
	}

	# Download absolute episode
	&verbose(1, "TVDB::API: Updating absolute episode $abs for $name\n");
	my $new = $self->_downloadXml($Url{getEpisodeAbs}, $sid, $abs, $self->{lang});
	if ($new) {
		# Save episode in cache
		my ($eid, $ep) = each %{$new->{Episode}};
		$series->{$sid}->{Seasons} = [] unless $series->{$sid}->{Seasons};
		$series->{$sid}->{Seasons}->[$ep->{SeasonNumber}]->[$ep->{EpisodeNumber}] = $eid;
		$cache->{Episode}->{$eid} = $ep;
		return $cache->{Episode}->{$eid};
	}

	&warning("TBDB::API: No absolute episode $abs found for $name\n");
	return undef;
}

###############################################################################
sub getEpisodeDVD {
	my ($self, $name, $season, $episode, $nocache) = @_;
	my $epmajor = int($episode);
	if ($epmajor < 0 || $epmajor > $self->{conf}->{maxEpisode}) {
		&warning("TBDB::API: Invalid DVD episode $episode in DVD season $season for $name\n");
		return undef;
	}
	my $sid = $self->getSeriesId($name);
	return undef unless $sid;
	my $data = $self->getSeason($sid, $season, $nocache?$nocache-1:0);
	return undef unless $data;

	# Look for episode in cache
	my $cache = $self->{cache};
	my $series = $cache->{Series};
	unless ($nocache) {
		foreach my $eid (@$data) {
			next unless $eid;
			my $ep = $cache->{Episode}->{$eid};
			my $de = $ep->{DVD_episodenumber};
			return $ep if $de eq $episode
		   			|| int($de) eq $episode
		   			|| int($de) eq $epmajor;
		}
	}

	# Download DVD episode
	&verbose(1, "TVDB::API: Updating DVD episode $episode from DVD season $season for $name\n");
	my $new = $self->_downloadXml($Url{getEpisodeDVD}, $sid, $season, $episode, $self->{lang});
	if ($new) {
		# Save episode in cache
		my ($eid, $ep) = each %{$new->{Episode}};
		$series->{$sid}->{Seasons} = [] unless $series->{$sid}->{Seasons};
		$series->{$sid}->{Seasons}->[$ep->{SeasonNumber}]->[$ep->{EpisodeNumber}] = $eid;
		$cache->{Episode}->{$eid} = $ep;
		return $cache->{Episode}->{$eid};
	}

	&warning("TBDB::API: No DVD episode $episode found for DVD season $season of $name\n");
	return undef;
}

###############################################################################
sub getEpisodeId {
	my ($self, $eid, $nocache) = @_;
	my $cache = $self->{cache};
	unless (!$nocache && defined $cache->{Episode}->{$eid}) {
		# Download episode
		&verbose(1, "TVDB::API: Updating episode id $eid\n");
		my $new = $self->_downloadXml($Url{getEpisodeID}, $eid, $self->{lang});
		return undef unless $new;

		# Save episode in cache
		$cache->{Episode}->{$eid} = $new->{Episode}-{$eid};
	}

	return $cache->{Episode}->{$eid};
}

###############################################################################
sub getEpisodeByAirDate {
	my ($self, $name, $airdate, $nocache) = @_;
	my $sid = $self->getSeriesId($name, $nocache?$nocache-1:0);

	my $cache = $self->{cache};

	# Download episode
	&verbose(1, "TVDB::API: Get episode for $name ($sid) on $airdate\n");
	my $new = $self->_downloadApikeyXml($Url{getEpisodeByAirDate}, $sid, $airdate, $self->{lang});
	return undef unless $new;

	return $new->{Episode};
}

###############################################################################
sub getEpisodeInfo {
	my ($self, $name, $season, $episode, $info, $nocache) = @_;

	my $data = $self->getEpisode($name, $season, $episode, $nocache);
	return undef unless $data;

	# Check that info is available
	unless (defined $data->{$info}) {
		#&warning("TBDB::API: No $info found for episode $episode of season $season of $name\n");
		return undef;
	}

	return $data->{$info};
}

###############################################################################
sub getEpisodeBanner {
	my ($self, $name, $season, $episode, $buffer, $nocache) = @_;
	my $banner = $self->getEpisodeInfo($name, $season, $episode, 'filename', $nocache?$nocache-1:0);
	return undef unless $banner;
	return $self->getBanner($banner, $buffer, $nocache);
}
sub getEpisodeName {
	my ($self, $name, $season, $episode, $nocache) = @_;
	return $self->getEpisodeInfo($name, $season, $episode, 'EpisodeName', $nocache);
}
sub getEpisodeOverview {
	my ($self, $name, $season, $episode, $nocache) = @_;
	return $self->getEpisodeInfo($name, $season, $episode, 'Overview', $nocache);
}

###############################################################################
sub getRatingsForUser {
	my ($self, $user, $name, $nocache) = @_;

	# Download ratings
	my $data;
	if ($name) {
		my $sid = $self->getSeriesId($name, $nocache?$nocache-1:0);
		&verbose(1, "TVDB::API: Get rating for $user for $name ($sid)\n");
		$data = $self->_downloadApikeyXml($Url{getRatingsForUser}, $user, $sid);
	} else {
		&verbose(1, "TVDB::API: Get rating for $user\n");
		$data = $self->_downloadApikeyXml($Url{getRatingsForUserAll}, $user);
	}
	return undef unless $data;

	return $data;
}

###############################################################################
__END__

=head1 NAME

TVDB::API - API to www.thetvdb.com

=head1 SYNOPSIS

  use TVDB::API;

  my $tvdb = TVDB::API::new([[$apikey], $language]);

  $tvdb->setApiKey($apikey);
  $tvdb->setLang('en');
  $tvdb->setUserAgent("TVDB::API/$VERSION");
  $tvdb->setBannerPath("/foo/bar/banners");
  $tvdb->setCacheDB("$ENV{HOME}/.tvdb.db");

  my $hashref = $tvdb->getConf();
  my $value = $tvdb->getConf($key);
  $tvdb->setConf($key, $value);
  $tvdb->setConf({key1=>'value1', key2=>'value2'});

  my $hashref = $tvdb->getAvailableMirrors([$nocache]);
  $tvdb->setMirrors($mirror, [$banner, [$zip]]);
  $tvdb->chooseMirrors([$nocache]);
  $tvdb->getAvailableLanguages([$nocache]);

  $tvdb->getUpdates([$period]);

  my $series_id = $tvdb->getPossibleSeriesId($series_name, [$nocache]);
  my $series_id = $tvdb->getSeriesId($series_name, [$nocache]);
  my $name = $tvdb->getSeriesName($series_id, [$nocache]);
  my $hashref = $tvdb->getSeries($series_name, [$nocache]);
  my $hashref = $tvdb->getSeriesAll($series_name, [$nocache]);
  my $hashref = $tvdb->getSeriesActors($series_name, [$nocache]);
  my $hashref = $tvdb->getSeriesActorsSorted($series_name, [$nocache]);
  my $hashref = $tvdb->getSeriesBanners($series_name, $type, $type2, $value, [$nocache]);
  my $hashref = $tvdb->getSeriesInfo($series_name, key, [$nocache]);
  my $string = $tvdb->getSeriesBanner($series_name, [$buffer, [$nocache]]);
  my $string = $tvdb->getSeriesFanart($series_name, [$buffer, [$nocache]]);
  my $string = $tvdb->getSeriesPoster($series_name, [$buffer, [$nocache]]);
  my $string = $tvdb->getSeriesOverview($series_name, [$nocache]);

  my $path = $tvdb->getBanner($banner, [$buffer, [$nocache]]);

  my $int = $tvdb->getMaxSeason($series, [$nocache]);
  my $hashref = $tvdb->getSeason($series, $season, [$nocache]);
  my @picture_names = $tvdb->getSeasonBanners($series, $season, [$nocache]);
  my $string = $tvdb->getSeasonBanner($series, $season, [$buffer, [$nocache]]);
  my @picture_names = $tvdb->getSeasonBannersWide($series, $season, [$nocache]);
  my $string = $tvdb->getSeasonBannerWide($series, $season, [$buffer, [$nocache]]);

  my $int = $tvdb->getMaxEpisode($series, $season, [$nocache]);
  my $hashref = $tvdb->getEpisode($series, $season, $episode, [$nocache]);
  my $hashref = $tvdb->getEpisodeAbs($series, $absEpisode, [$nocache]);
  my $hashref = $tvdb->getEpisodeDVD($series, $DVDseason, $DVDepisode, [$nocache]);
  my $hashref = $tvdb->getEpisodeId($episodeid, [$nocache]);
  my $hashref = $tvdb->getEpisodeByAirDate($series, $airdate, [$nocache]);
  my $string = $tvdb->getEpisodeInfo($series, $season, $episode, $info, [$nocache]);
  my $string = $tvdb->getEpisodeBanner($series, $season, $episode, [$buffer, [$nocache]]);
  my $string = $tvdb->getEpisodeName($series, $season, $episode, [$nocache]);
  my $string = $tvdb->getEpisodeOverview($series, $season, $episode, [$nocache]);

  my $hashref = $tvdb->getRatingsForUser($userid, $series, [$nocache]);

  $tvdb->dumpCache();

=head1 DESCRIPTION

This module provides an API to the TVDB database through the new published API.

=over 4

=item $tvdb = TVDB::API::new([APIKEY, [LANGUAGE]])

Create a TVDB::API object using C<APIKEY> and using a default language
of C<LANGUAGE>. Both these arguments are optional.

New can also be called with a hashref as the first argument.

  $tvdb = TVDB::API::new({ apikey    => $apikey,
                           lang      => 'en',
                           cache     => 'filename',
                           banner    => 'banner/path',
                           useragent => 'My useragent'
                        });

=item setApiKey(APIKEY);

Set the C<APIKEY> to be used to access the web api for thetvdb.com

=item setLang(LANGUAGE);

Set the C<LANGUAGE> to use when downloading data from thetvdb.com

=item setUserAgent(USERAGENT);

Set the C<USERAGENT> to be used when downloading information from thetvdb.com

=item setBannerPath(PATH);

Set the path in which to save downloaded banner graphics files.

=item setCacheDB("$ENV{HOME}/.tvdb.db");

Set the name of the database file to be used to save data from thetvdb.com

=item getAvailableMirrors([NOCACHE]);

Get the list of mirror sites available from thetvdb.com. It returns a hashref
of arrays.  If C<NOCACHE> is non-zero, then the mirrors are downloaded again
even if they are in the cache database already.

Returns:
  {
    xml => @xml_mirrors,
    banner => @banner_mirrors,
    zip => @zip_mirrors,
  }

=item setMirrors(MIRROR, [BANNER, [ZIP]])

Set the mirror site(s) to be used to download tv info. If C<BANNER> or C<ZIP>
or not specified, then C<MIRROR> is used instead.

=item chooseMirrors([NOCACHE])

Choose a random mirror from the list of available mirrors.  If C<NOCACHE> is
non-zero, then the mirrors are downloaded again even if they are in the cache
database already.

=item getConf([KEY])

Get configurable values by C<KEY>.  If no C<KEY> is specified, a hashref of all
values is returned.

=item setConf(KEY, VALUE) or setConf({KEY=>VALUE, ...})

Set configurable values by C<KEY>/C<VALUE> pair.  If a hashref is passed in,
all C<KEY>/C<VALUE> pairs in the hashref will be configured.

    maxSeason       => 50,          # Maximum allowed season
    maxEpisode      => 50,          # Maximum allowed episode
    minUpdateTime   => 3600*6,      # Used by getUpdate('now')
    minBannerTime   => 3600*24*7,   # Used by getBanner()
    minEpisodeTime  => 3600*24*7,   # Used by getEpisode()

=item getAvailableLanguages([NOCACHE])

Get a list of available languages, and return them in a hashref.  If C<NOCACHE>
is non-zero, then the available languages are downloaded again even if they are
in the cache database already.

=item getUpdates([PERIOD])

Get appropriate updates (day/week/month/all) from thetvdb.com based on the
specified C<PERIOD>.  It then downloads updates for series, episodes, and
banners which have already been downloaded.

=over 4

=item C<day>

Get the updates for the last 24 hours (86400 seconds).

=item C<week>

Get the updates for the last week (7 days, or 604800 seconds).

=item C<month>

Get the updates for the last month (30 days, or 2592000 seconds).

=item C<all>

Get all updates available.

=item C<now>

Based on the last update performed, determine whether to do a day, week, month
or all update.

=item C<guess>

Like C<now>, based on the last update performed; determine whether to do a day,
week, month or all update.  However, if the last update was performed in the
last 6 hours (setable as C<minUpdateTime> with setConf()), do nothing. This is
the default C<PERIOD>.

=back

=item getPossibleSeriesId(SERIESNAME)

Get a list of possible series ids for C<SERIESNAME> from thetvtb.com. This
will return a hashref of possibilities.

=item getSeriesId(SERIESNAME, [NOCACHE])

Get the series id (an integer) for C<SERIESNAME> from thetvtb.com. If
C<NOCACHE> is non-zero, then the series id is downloaded again even if it is in
the cache database already.

=item getSeriesName(SERIESID, [NOCACHE])

Get the series name (a string) for C<SERIESID>. If C<NOCACHE> is non-zero, then
the series name is downloaded again even if it is in the cache database
already.

=item getSeries(SERIESNAME, [NOCACHE])

Get the series info for C<SERIESNAME> from thetvtb.com, which is returned as a
hashref. If C<NOCACHE> is non-zero, then the series info is downloaded again
even if it is in the cache database already.

=item getSeriesAll(SERIESNAME, [NOCACHE])

Get the series info, and all episodes for C<SERIESNAME> from thetvtb.com, which
is returned as a hashref. If C<NOCACHE> is non-zero, then the series info and
episodes are downloaded again even if they are in the cache database already.

=item getSeriesActors(SERIESNAME, [NOCACHE])

Get the actors for C<SERIESNAME> from thetvtb.com, which is returned as a
hashref. If C<NOCACHE> is non-zero, then the list of actors are
downloaded again even if they are in the cache database already.

=item getSeriesActorsSorted(SERIESNAME, [NOCACHE])

Get the actors for C<SERIESNAME> from thetvtb.com, which is returned as an
arrayref sorted by SortOrder.  If C<NOCACHE> is non-zero, then the list of
actors are downloaded again even if they are in the cache database already.

=item getSeriesBanners(SERIESNAME, TYPE, TYPE2, VALUE, [NOCACHE])

Get the banners for C<SERIESNAME> from thetvtb.com. Info about the available
banners are returned in a hashref.  The actual banners can be downloaded
individually with C<getBanner> (see below).  If C<NOCACHE> is non-zero, then
the list of banners are downloaded again even if they are in the cache database
already.

if C<TYPE> is specified (series, season, poster, or fanart) then only return
banners of that type.  if C<TYPE2> is specified then only return banners of
that sub type.  If C<TYPE> is "series" then C<TYPE2> can be "text",
"graphical", or "blank".  If C<TYPE> is "season" then C<TYPE2> can be "season",
or "seasonwide" and C<VALUE> specifies the season number.  If C<TYPE> is
"fanart" then C<TYPE2> is the desired resolution of the image.

=item getSeriesInfo(SERIESNAME, KEY, [NOCACHE])

Return a string for C<KEY> in the hashref for C<SERIESNAME>.  If C<NOCACHE> is
non-zero, then the series is downloaded again even if it is in the cache database already.

=item getSeriesBanner(SERIESNAME, [BUFFER, [NOCACHE]])

Get the C<SERIESNAME> banner from thetvdb.com and save it in the C<BannerPath>
directory.  The cached banner is updated via C<getUpdates> when appropriate. If
a C<BUFFER> is provided (a scalar reference), the banner (newly downloaded, or
from the cache) is loaded into it. If C<NOCACHE> is non-zero, then the banner
is downloaded again even if it is in the C<BannerPath> directory already. It
will return the path of the banner relative to the C<BannerPath> directory.

=item getSeriesFanart(SERIESNAME, [BUFFER, [NOCACHE]])

Get the C<SERIESNAME> fan art from thetvdb.com and save it in the C<BannerPath>
directory.  The cached fan art is updated via C<getUpdates> when appropriate.
If a C<BUFFER> is provided (a scalar reference), the fan art (newly downloaded,
or from the cache) is loaded into it. If C<NOCACHE> is non-zero, then the fan
art is downloaded again even if it is in the C<BannerPath> directory already.
It will return the path of the fan art relative to the C<BannerPath> directory.

=item getSeriesPoster(SERIESNAME, [BUFFER, [NOCACHE]])

Get the C<SERIESNAME> poster from thetvdb.com and save it in the C<BannerPath>
directory.  The cached poster is updated via C<getUpdates> when appropriate.
If a C<BUFFER> is provided (a scalar reference), the poster (newly downloaded,
or from the cache) is loaded into it. If C<NOCACHE> is non-zero, then the
poster is downloaded again even if it is in the C<BannerPath> directory
already. It will return the path of the poster relative to the C<BannerPath>
directory.

=item getSeriesOverview(SERIESNAME, [NOCACHE])

Get the series overview from thetvdb.com and return it as a string. If
C<NOCACHE> is non-zero, then the banner is downloaded again even if it is in
the cache database already.

=item getBanner(BANNER, [BUFFER, [NOCACHE]])

Get the C<BANNER> from thetvdb.com and save it in the C<BannerPath> directory.
The cached banner is updated via C<getUpdates> when appropriate. If a C<BUFFER>
is provided (a scalar reference), the picture (newly downloaded, or from the
cache) is loaded into it. If C<NOCACHE> is non-zero, then the banner is
downloaded again even if it is in the C<BannerPath> directory already. It will
return the path of the picture relative to the C<BannerPath> directory.  In
this case it will just be the same as C<BANNER>.

The C<minBannerTime> configuration variable determines the maximum time a
banner download failure will be cached.  (see getConf()/setConf()).

=item getMaxSeason(SERIESNAME, [NOCACHE])

Return the number of the last season for C<SERIESNAME>.  If C<NOCACHE> is
non-zero, then any series info needed to calculate this is downloaded again
even if it is in the cache database already.

=item getSeason(SERIESNAME, SEASON, [NOCACHE])

Return a hashref of episodes in C<SEASON> for C<SERIESNAME>.  If C<NOCACHE> is
non-zero, then any episodes needed for this season is downloaded again even if
it is in the cache database already.

The C<maxSeason> configuration variable determines the maximum allowable season
(see getConf()/setConf()).

=item getSeasonBanners(SERIESNAME, SEASON, [NOCACHE])

Return an array of banner names for C<SEASON> for C<SERIESNAME>.  These names
can get used with C<getBanner()> to actually download the banner file. If
C<NOCACHE> is non-zero, then any data needed for this is downloaded again even
if it is in the cache database already.

=item getSeasonBanner(SERIESNAME, SEASON, [BUFFER, [NOCACHE]])

Get a random banner for C<SEASON> for C<SERIESNAME>.  The cached banner is
updated via C<getUpdates> when appropriate.  If a C<BUFFER> is provided (a
scalar reference), the banner (newly downloaded, or from the cache) is loaded
into it.  If C<NOCACHE> is non-zero, then the banner is downloaded again even
if it is in the C<BannerPath> directory already. It will return the path of the
banner relative to the C<BannerPath> directory.

=item getSeasonBannersWide(SERIESNAME, SEASON, [NOCACHE])

Return an array of wide banner names for C<SEASON> for C<SERIESNAME>.  These
names can get used with C<getBanner()> to actually download the banner file. If
C<NOCACHE> is non-zero, then any data needed for this is downloaded again even
if it is in the C<BannerPath> directory already.

=item getSeasonBannerWide(SERIESNAME, SEASON, [BUFFER, [NOCACHE]])

Get a random banner for C<SEASON> for C<SERIESNAME>.  The cached banner is
updated via C<getUpdates> when appropriate.  If a C<BUFFER> is provided (a
scalar reference), the banner (newly downloaded, or from the cache) is loaded
into it.  If C<NOCACHE> is non-zero, then the banner is downloaded again even
if it is in the C<BannerPath> directory already. It will return the path of the
banner relative to the C<BannerPath> directory.

=item getMaxEpisode(SERIESNAME, SEASON, [NOCACHE])

Return the number episodes in C<SEASON> for C<SERIESNAME>.  If C<NOCACHE> is
non-zero, then any series info needed to calculate this is downloaded again
even if it is in the cache database already.

The C<maxEpisode> configuration variable determines the maximum allowable
episode (see getConf()/setConf()).

=item getEpisode(SERIESNAME, SEASON, EPISODE, [NOCACHE])

Return a hashref for the C<EPISODE> in C<SEASON> for C<SERIESNAME>.  If
C<NOCACHE> is non-zero, then the episode is downloaded again even if it is in
the cache database already.

The C<minEpisodeTime> configuration variable determines the maximum time a
episode lookup failure will be cached.  (see getConf()/setConf()).

=item getEpisodeAbs(SERIESNAME, ABSEPISODE, [NOCACHE])

Return a hashref for the absolute episode (C<ABSEPISODE>) for C<SERIESNAME>.
If C<NOCACHE> is non-zero, then the episode is downloaded again even if it is
in the cache database already.

=item getEpisodeDVD(SERIESNAME, SEASON, EPISODE, [NOCACHE])

Return a hashref for the C<EPISODE> in C<SEASON> for C<SERIESNAME> in DVD
order.  If C<NOCACHE> is non-zero, then the episode is downloaded again even if
it is in the cache database already.

=item getEpisodeId(EPISODEID, [NOCACHE])

Return a hashref for the episode indicated by C<EPISODEID>.  If C<NOCACHE> is
non-zero, then the episode is downloaded again even if it is in the
cache database already.

=item getEpisodeByAirDate(SERIESNAME, AIRDATE [NOCACHE])

Return a hashref for the episode in C<SERIESNAME> on C<AIRDATE>. C<AIRDATE> can
be specified as:

    2008-01-01
    2008-1-1
    January 1, 2008
    1/1/2008

Currently this lookup is not cached.  However, if C<NOCACHE> is non-zero, then
the C<SERIESNAME> to seriesid lookup is downloaded again.

=item getEpisodeInfo(SERIESNAME, SEASON, EPISODE, KEY, [NOCACHE])

Return a string for C<KEY> in the hashref for C<EPISODE> in C<SEASON> for
C<SERIESNAME>.  If C<NOCACHE> is non-zero, then the episode is downloaded again
even if it is in the cache database already.

=item getEpisodeBanner(SERIESNAME, SEASON, EPISODE, [BUFFER, [NOCACHE]])

Get the episode banner for C<EPISODE> in C<SEASON> for C<SERIESNAME>.  The
cached banner is updated via C<getUpdates> when appropriate.  If a C<BUFFER> is
provided, the picture (newly downloaded, or from the cache) is loaded into it.
If C<NOCACHE> is non-zero, then the banner is downloaded again even if it is in
the C<BannerPath> directory already. It will return the path of the picture
relative to the C<BannerPath> directory.

=item getEpisodeName(SERIESNAME, SEASON, EPISODE, [NOCACHE])

Return the episode name for C<EPISODE> in C<SEASON> for C<SERIESNAME>.  If
C<NOCACHE> is non-zero, then the episode is downloaded again even if it is in
the cache database already.

=item getEpisodeOverview(SERIESNAME, SEASON, EPISODE, [NOCACHE])

Return the overview for C<EPISODE> in C<SEASON> for C<SERIESNAME>.  If
C<NOCACHE> is non-zero, then the episode is downloaded again even if it is in
the cache database already.

=item getRatingsForUser(USERID, SERIESNAME, [NOCACHE])

Get the series ratings for C<USERID>. If C<SERIESNAME> is specified, the
user/community ratings for the series and its episodes are returned in a
hashref.  If C<SERIESNAME> is not specified, then all the series rated by the
<USERID> will be returned in a hashref.  These lookups are not cached.

=item dumpCache()

Dump the cache database with Dumper to stdout.

=back

=head1 EXAMPLE

    use Data::Dumper;
    use TVDB::API;
    my $episode = $tvdb->getEpisode('Lost', 3, 5);
    print Dumper($episode);

    Produces:

    $episode = {
      'lastupdated' => '1219734325',
      'EpisodeName' => 'The Cost of Living',
      'seasonid' => '16270',
      'Overview' => 'A delirious Eko wrestles with past demons; some of the castaways go to the Pearl station to find a computerthey can use to locate Jack, Kate and Sawyer; Jack does not know who to trust when two of the Others are at odds with each other.',
      'filename' => 'episodes/73739-308051.jpg',
      'EpisodeNumber' => '5',
      'Language' => 'en',
      'Combined_season' => '3',
      'FirstAired' => '2006-11-01',
      'seriesid' => '73739',
      'Director' => 'Jack Bender',
      'SeasonNumber' => '3',
      'Writer' => 'Monica Owusu-Breen, Alison Schapker',
      'GuestStars' => '|Olalekan Obileye| Kolawole Obileye Junior| Alicia Young| Aisha Hinds| Lawrence Jones| Ariston Green| Michael Robinson| Jermaine|',
      'Combined_episodenumber' => '5'
    };

=head1 AUTHOR

S<Behan Webster E<lt>behanw@websterwood.comE<gt>>

=head1 COPYRIGHT

Copyright (c) 2008 Behan Webster. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
