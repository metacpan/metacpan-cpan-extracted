
package MooseX::WithCache::Backend::Cache::FastMmap;
use Moose;
use Moose::Util::TypeConstraints;

extends 'MooseX::WithCache::Backend';

class_type 'Cache::FastMmap';

sub _build_cache_type {
    return 'Cache::FastMmap';
}

around _build_methods => sub {
    my ($next, $self) = @_;

    my $methods = $next->($self);
    $methods->{cache_del} = sub {
        my ($self, $key) = @_;
        my $cache = $self->__get_cache();
        if ($self->cache_disabled || ! $cache) {
            if (MooseX::WithCache::DEBUG()) {
                $self->cache_debug("cache_set: Cache disabled");
            }
            return (); 
        }

        my $keygen = $self->cache_key_generator;
        my $cache_key = $keygen ? $keygen->generate($key) : $key;
        if (MooseX::WithCache::DEBUG()) {
            $self->cache_debug(
                "cache_del: key =",
                ($cache_key || '(null)'),
            );  
        }
        return $cache->remove($cache_key);
    };
    $methods->{cache_incr} = sub {
        my ($self, $key) = @_;
        my $cache = $self->__get_cache();
        if ($self->cache_disabled || ! $cache) {
            if (MooseX::WithCache::DEBUG()) {
                $self->cache_debug("cache_incr: Cache disabled");
            }
            return ();
        }

        my $keygen = $self->cache_key_generator;
        my $cache_key = $keygen ? $keygen->generate($key) : $key;
        return $cache->get_and_set( $cache_key, sub { ++$_[1] } );
    };
    $methods->{cache_decr} = sub {
        my ($self, $key) = @_;
        my $cache = $self->__get_cache();
        if ($self->cache_disabled || ! $cache) {
            if (MooseX::WithCache::DEBUG()) {
                $self->cache_debug("cache_decr: Cache disabled");
            }
            return ();
        }

        my $keygen = $self->cache_key_generator;
        my $cache_key = $keygen ? $keygen->generate($key) : $key;
        return $cache->get_and_set( $cache_key, sub { --$_[1] } );
    };
    return $methods;
};

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

1;

__END__

=head1 NAME

MooseX::WithCache::Backend::Cache::FastMmap - Cache::FastMmap Backend

=head1 SYNOPSIS

    package MyObject;
    use MooseX::WithCache;
    with_cache(
        backend => 'Cache::FastMmap'
    );

    package main;

    my $obj = MyObject->new(
        cache => Cache::FastMmap->new({ ... });
    );

    $obj->cache_get($key);
    $obj->cache_set($key);
    $obj->cache_del($key);
    $obj->cache_incr($key);
    $obj->cache_decr($key);

    # {
    #   results => {
    #       key1 => $cache_hit_value1,
    #       key2 => $cache_hit_value2,
    #       ...
    #   },
    #   missing => [ 'key3', 'key4', 'key5' .... ]
    # }

=head1 METHODS

=head2 build_cache_decr_method

=head2 build_cache_del_method

=head2 build_cache_get_method

=head2 build_cache_incr_method

=head2 build_cache_set_method

=head2 install_cache_attr

=cut
