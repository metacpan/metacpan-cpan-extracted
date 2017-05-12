package MojoX::Plugin::AnyCache::Backend::Mojo::Redis;

use strict;
use warnings;
use Mojo::Base 'MojoX::Plugin::AnyCache::Backend';
use Mojo::Util 'monkey_patch';

use Mojo::Redis;

has 'redis';

has 'support_async' => sub { 1 };

sub get_redis {
	my ($self) = @_;
	if(!$self->redis) {
		my %opts = ();
		$opts{server} = $self->config->{server} if exists $self->config->{server};

        if( my $protocol = $self->config->{redis_protocol} ) {
            eval "require $protocol; 1" // die "Failed to load configured redis protocol '$protocol': $@";
            monkey_patch "Mojo::Redis", protocol_redis => sub { $protocol };
        }

		$self->redis(Mojo::Redis->new(%opts));
	}
	return $self->redis;
}

sub get { 
	my ($cb, $self) = (pop, shift);
	$self->get_redis->get(@_, sub {
		my ($redis, $value) = @_;
		$cb->($value);
	});
}

sub set {
	my ($cb, $self) = (pop, shift);
	my ($key, $value, $ttl) = @_;
	$self->get_redis->set($key, $value, sub {
		my ($redis) = @_;
		if($ttl) {
			$self->get_redis->expire($key, $ttl, sub {
				$cb->();
			});
		} else {
			$cb->();
		}
	});
}

sub ttl { 
	my ($cb, $self) = (pop, shift);
	$self->get_redis->ttl(@_, sub {
		my ($redis, $value) = @_;
		$cb->($value);
	});
}

sub incr {
	my ($cb, $self) = (pop, shift, @_);
	$self->get_redis->incrby(@_, sub {
		my ($redis, $value) = @_;
		$cb->($value);
	});
}

sub decr {
	my ($cb, $self) = (pop, shift, @_);
	$self->get_redis->decrby(@_, sub {
		my ($redis, $value) = @_;
		$cb->($value);
	});
}

sub del {
	my ($cb, $self) = (pop, shift, @_);
	$self->get_redis->del(@_, sub {
		my ($redis) = @_;
		$cb->();
	});
}

1;
