package FakeBackend;

use Mojo::Base 'MojoX::Plugin::AnyCache::Backend';

has 'storage' => sub { {} };
has 'config';
has 'support_sync' => sub { 1 };
has 'support_async' => sub { 1 };

sub get {
	my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
	my ($self, $key) = @_;
	return $cb->($self->storage->{$key}) if $cb;
	return $self->storage->{$key};
}
sub set {
	my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
	my ($self, $key, $value, $ttl) = @_;
	$self->storage->{$key} = $value;
	$self->storage->{"TTL:$key"} = $ttl if $ttl;
	$cb->() if $cb;
}
sub ttl {
	my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
	my ($self, $key) = @_;
	return $cb->($self->storage->{"TTL:$key"}) if $cb;
	return $self->storage->{"TTL:$key"};
}
sub incr {
	my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
	my ($self, $key, $amount) = @_;
	$self->storage->{$key} //= 0;
	$self->storage->{$key} += $amount;
	$cb ? $cb->($self->storage->{$key}) : $self->storage->{$key};
}
sub decr {
	my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
	my ($self, $key, $amount) = @_;
	$self->storage->{$key} //= 0;
	$self->storage->{$key} -= $amount;
	$cb ? $cb->($self->storage->{$key}) : $self->storage->{$key};
}
sub del {
	my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
	my ($self, $key) = @_;
	delete $self->storage->{$key};
	$cb->() if $cb;
}

1;
