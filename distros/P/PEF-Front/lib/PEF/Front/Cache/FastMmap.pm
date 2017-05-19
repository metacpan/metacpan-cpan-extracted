package PEF::Front::Cache::FastMmap;
use strict;
use warnings;
use Cache::FastMmap;
use PEF::Front::Config;
use Time::Duration::Parse;
use Time::HiRes 'time';
use Data::Dumper;

my $cache;

BEGIN {
	# empty grep means there's no config loaded - some statical
	# analyzing tools can break
	if (grep { /AppFrontConfig\.pm$/ } keys %INC) {
		$cache = Cache::FastMmap->new(
			share_file     => cfg_cache_file,
			cache_size     => cfg_cache_size,
			empty_on_exit  => 0,
			unlink_on_exit => 0,
			expire_time    => 0,
			init_file      => 1
		) or die "Can't create cache: $!";
	}
}

sub get_cache {
	my $key = $_[0];
	my $res = $cache->get($key);
	if ($res) {
		if ($res->[0] < time) {
			$cache->remove($key);
			return;
		}
		return $res->[1];
	} else {
		return;
	}
}

sub set_cache {
	my ($key, $obj, $expires) = @_;
	my $seconds = parse_duration($expires) || 60;
	$cache->set($key, [$seconds + time, $obj]);
}

sub remove_cache_key {
	my $key = $_[0];
	$cache->remove($key);
}


1;

