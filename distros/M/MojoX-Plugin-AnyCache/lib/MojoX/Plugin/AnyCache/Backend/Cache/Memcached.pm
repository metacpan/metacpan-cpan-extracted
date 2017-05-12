package MojoX::Plugin::AnyCache::Backend::Cache::Memcached;

use strict;
use warnings;
use Mojo::Base 'MojoX::Plugin::AnyCache::Backend';

use Cache::Memcached;

has 'memcached';

has 'support_sync' => sub { 1 };
has 'get_ttl_support' => sub { 0 };

sub get_memcached {
	my ($self) = @_;
	if(!$self->memcached) {
		my %opts = ();
		$opts{servers} = $self->config->{servers} if exists $self->config->{servers};
		$self->memcached(Cache::Memcached->new(%opts));
	}
	return $self->memcached;
}

sub get { shift->get_memcached->get(@_) }
sub set { 
	my ($self, $key, $value, $ttl) = (shift, shift, shift, shift);
	$self->get_memcached->set($key, $value, $ttl, @_);
	$self->get_memcached->set(":TTL:$key", time + $ttl, $ttl, @_) if $ttl && $self->get_ttl_support;
}
sub incr { shift->get_memcached->incr(@_) }
sub decr { shift->get_memcached->decr(@_) }
sub del { shift->get_memcached->delete(@_) }
sub ttl {
	my ($self, $key) = (shift, shift);
	die("get_ttl_support not enabled") if !$self->get_ttl_support;
	$self->get(":TTL:$key", @_) - time;
}

1;