package MojoX::Plugin::AnyCache::Backend::Memcached::Client;

use strict;
use warnings;
use Mojo::Base 'MojoX::Plugin::AnyCache::Backend';

use EV;
use AnyEvent;
use Memcached::Client;

has 'memcached';

has 'support_async' => sub { 1 };
has 'get_ttl_support' => sub { 0 };

sub get_memcached {
	my ($self) = @_;
	
	if(!$self->memcached) {
		my %opts = ();
		$opts{servers} = $self->config->{servers} if exists $self->config->{servers};
		$self->memcached(Memcached::Client->new(%opts));
	}
	return $self->memcached;
}

sub get { 
	my ($cb, $self) = (pop, shift);
	#$self->get_memcached->get(@_, sub { $cb->(shift) });
    my $i = $self->get_memcached;
    
    $i->get(@_, sub { $cb->(shift) });
}

sub set {
	my ($cb, $self, $key, $value, $ttl) = (pop, shift, shift, shift, shift);

	$self->get_memcached->set($key, $value, $ttl, @_, sub { $cb->() });
	$self->get_memcached->set(":TTL:$key", time + $ttl, $ttl, @_, sub {} ) if $ttl && $self->get_ttl_support;
}

sub incr {
	my ($cb, $self) = (pop, shift);
	$self->get_memcached->incr(@_, sub { $cb->() });
}

sub decr {
	my ($cb, $self) = (pop, shift);
	$self->get_memcached->decr(@_, sub { $cb->() });
}

sub del {
	my ($cb, $self) = (pop, shift);
	$self->get_memcached->delete(@_, sub { $cb->() });
}

sub ttl {
	my ($cb, $self, $key) = (pop, shift, shift);
	die("get_ttl_support not enabled") if !$self->get_ttl_support;
	$self->get(":TTL:$key", @_, sub {
		my ($time) = @_;
		$cb->($time -= time);
	});
}

1;
