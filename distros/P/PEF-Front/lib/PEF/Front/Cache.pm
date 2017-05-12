package PEF::Front::Cache;
use strict;
use warnings;
use Cache::FastMmap;
use PEF::Front::Config;
use Time::Duration::Parse;
use Time::HiRes 'time';
use Data::Dumper;

use base 'Exporter';
our @EXPORT = qw{
  get_cache
  make_request_cache_key
  remove_cache_key
  set_cache
};

my $cache;
my $dumper;

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
	$dumper = Data::Dumper->new([]);
	$dumper->Indent(0);
	$dumper->Pair(":");
	$dumper->Useqq(1);
	$dumper->Terse(1);
	$dumper->Deepcopy(1);
	$dumper->Sortkeys(1);
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

sub make_request_cache_key {
	my ($vreq, $cache_attr) = @_;
	$cache_attr = {key => 'method', expires => $cache_attr} if not ref $cache_attr;
	my @keys;
	if (ref ($cache_attr->{key}) eq 'ARRAY') {
		@keys = grep { exists $vreq->{$_} } @{$cache_attr->{key}};
	} elsif (not exists $cache_attr->{key}) {
		@keys = ('method');
	} else {
		@keys = ($cache_attr->{key});
	}
	$dumper->Values([{map { $_ => $vreq->{$_} } @keys}]);
	return $dumper->Dump;
}

1;

__END__

=head1 NAME

B<PEF::Front::Cache> - Data cache

=head1 DESCRIPTION

This class is used to store cached method responses and 
any other information.

=head1 FUNCTIONS

=head2 make_request_cache_key($vreq, $cache_attr)

Makes key string for caching model method response.

=head2 get_cache($key_string)

Returns value from cache for given C<$key_string>.

=head2 set_cache($key_string, $value)

Sets value in cache for given C<$key_string>.

=head2 remove_cache_key($key_string)

Deletes cache value for given C<$key_string> if exists.

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
