package PEF::Front::Cache::Null;
use strict;
use warnings;

sub get_cache {
	return;
}

sub set_cache {
	my ($key, $obj, $expires) = @_;
	return;
}

sub remove_cache_key {
	my $key = $_[0];
	return;
}

1;

