package Role::Cache::LRU;

use namespace::clean;
use strictures 2;

use Cache::LRU;
use Carp qw(croak);
use Moo::Role;
use Sub::Quote qw(quote_sub);
use Types::Standard qw(InstanceOf);

our $VERSION = '0.04';

has cache => (
    isa => InstanceOf['Cache::LRU'],
    is => 'lazy',
    builder => quote_sub(q{ Cache::LRU->new }),
);

sub get_cache {
    my ($self, $key) = @_;

    return $self->cache->get($key);
}

sub set_cache {
    my ($self, $key, $data) = @_;

    return $self->cache->set($key, $data);
}

sub get_cache_size {
    my $self = shift;

    return $self->cache->{size};
}

sub set_cache_size {
    my ($self, $max) = @_;

    croak q|Invalid cache size!| if ($max <= 0);

    return $self->cache->{size} = $max;
}

1;
__END__

=encoding utf-8

=for stopwords lru

=head1 NAME

Role::Cache::LRU - LRU caching role for Moo class.

=head1 SYNOPSIS

    package MyPackage;

    use Moo;
    with 'Role::Cache::LRU';

    my $mp = MyPackage->new;
    $mp->set_cache('foo', {bar => 1});
    $mp->get_cache('foo');

=head1 DESCRIPTION

Role::Cache::LRU is a Moo's role that provides LRU caching based on
L<Cache::LRU|Cache::LRU>.

=head1 DEVELOPMENT

Source repository at L<https://github.com/kianmeng/role-cache-lru|https://github.com/kianmeng/role-cache-lru>.

How to contribute? Follow through the L<CONTRIBUTING.md|https://github.com/kianmeng/role-cache-lru/blob/master/CONTRIBUTING.md> document to setup your development environment.

=head1 METHODS

=head2 set_cache($key, $item)

Add a cache item to the cache. The $key must be a string.

    my $mp = MyPackage->new;
    $mp->set_cache('foo', {bar => 1});
    $mp->set_cache('bar', [1, 2, 3]);

=head2 get_cache($key)

Get a cached item based on the $key. If nothing is found, returns undef.

    my $mp = MyPackage->new;
    my $item = $mp->get_cache('fishball');
    print $item; # undef

=head2 set_cache_size($max)

Set the maximum cached size. The $max value must be larger or equal to 1.
Adjust this to your available maximum memory in your script.

    my $mp = MyPackage->new;
    $mp->set_cache_size(4096);

=head2 get_cache_size()

Get the maximum cache size. The default maximum value is 1024.

    my $mp = MyPackage->new;
    print $mp->get_cache_size();
    # 1024

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=head1 AUTHOR

Kian Meng, Ang E<lt>kianmeng@users.noreply.github.comE<gt>

=head1 SEE ALSO

L<Cache::LRU|Cache::LRU>

=cut
