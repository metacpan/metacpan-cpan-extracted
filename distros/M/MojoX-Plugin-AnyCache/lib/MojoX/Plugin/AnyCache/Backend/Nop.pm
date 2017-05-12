package MojoX::Plugin::AnyCache::Backend::Nop;

use strict;
use warnings;
use Mojo::Base 'MojoX::Plugin::AnyCache::Backend';

has 'support_async' => sub { 1 };

sub get { 
	my ($cb, $self) = (pop, shift);
    $cb->();
}

sub set {
	my ($cb, $self, $key, $value, $ttl) = (pop, shift, shift, shift, shift);
    $cb->();
}

sub incr {
	my ($cb, $self) = (pop, shift);
    $cb->();
}

sub decr {
	my ($cb, $self) = (pop, shift);
    $cb->();
}

sub del {
	my ($cb, $self) = (pop, shift);
    $cb->();
}

sub ttl {
	my ($cb, $self, $key) = (pop, shift, shift);
	$cb->(time);
}

1;
