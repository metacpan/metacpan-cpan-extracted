package MojoX::Plugin::AnyCache::Backend::Replicator;

use strict;
use warnings;
use Mojo::Base 'MojoX::Plugin::AnyCache::Backend';

sub init {
	my ($self) = @_;
	$self->{nodes} = undef;
	$self->get_nodes;
}

sub get_nodes {
	my ($self) = @_;
	
	if(!$self->{nodes}) {
		$self->{nodes} = [];
		$self->support_sync(1);
		$self->support_async(1);
		for my $node (@{$self->config->{nodes}}) {
			eval {
		      eval "require $node->{backend};";
		      warn("Require failed: $@") if $self->config->{debug} && $@;
		      my $backend = "$node->{backend}"->new;
		      $backend->config($node);
		      $self->support_sync(0) if !$backend->support_sync;
		      $self->support_async(0) if !$backend->support_async;
		      push @{$self->{nodes}}, $backend;
		    };
		    die("Failed to create backend node $node->{backend}: $@") if $@;
		}
		warn "No support for sync or async operations" if !$self->support_sync && !$self->support_async;
	}

	return @{$self->{nodes}};
}

sub get {
	my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
	my ($self, $key) = @_;
	my $node = $self->{nodes}->[rand @{$self->{nodes}}];
	if(my $serialiser = $node->get_serialiser) {
		return $node->get($key, sub {
			$cb->($serialiser->deserialise(shift));
		}) if $cb;
		return $serialiser->deserialise($node->get($key));
	} else {
		return $node->get($key, $cb);
	}
}

sub set {
	my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
	my ($self, $key, $value, $ttl) = @_;
	if($cb) {
		my $delay = Mojo::IOLoop->delay($cb);
		$_->set($key, ($_->get_serialiser ? $_->get_serialiser->serialise($value) : $value), $ttl, $delay->begin) for @{$self->{nodes}};
		return;
	}
	$_->set($key, ($_->get_serialiser ? $_->get_serialiser->serialise($value) : $value), $ttl) for @{$self->{nodes}};
}

sub ttl {
	my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
	my ($self, $key) = @_;
	$self->{nodes}->[rand @{$self->{nodes}}]->ttl($key, $cb)
}

sub incr {
	my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
	my ($self, $key, $amount) = @_;
	if($cb) {
		my $delay = Mojo::IOLoop->delay($cb);
		$_->incr($key, $amount, $delay->begin) for @{$self->{nodes}};
		return;
	}
	$_->incr($key, $amount) for @{$self->{nodes}};
}

sub decr {
	my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
	my ($self, $key, $amount) = @_;
	if($cb) {
		my $delay = Mojo::IOLoop->delay($cb);
		$_->decr($key, $amount, $delay->begin) for @{$self->{nodes}};
		return;
	}
	$_->decr($key, $amount) for @{$self->{nodes}};
}

sub del {
	my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
	my ($self, $key) = @_;
	if($cb) {
		my $delay = Mojo::IOLoop->delay($cb);
		$_->del($key, $delay->begin) for @{$self->{nodes}};
		return;
	}
	$_->del($key) for @{$self->{nodes}};
}

1;