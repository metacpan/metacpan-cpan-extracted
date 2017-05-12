
package MooseX::WithCache::Backend::Cache::FileCache;
use Moose;
use Moose::Util::TypeConstraints;

extends 'MooseX::WithCache::Backend';

class_type 'Cache::FileCache';

sub _build_cache_type {
    return 'Cache::FileCache';
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
    return $methods;
};

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

1;

__END__

=head1 NAME

MooseX::WithCache::Backend::Cache::FileCache - Cache::FileCache Backend

=head1 SYNOPSIS

    package MyObject;
    use MooseX::WithCache;
    with_cache(
        backend => 'Cache::FileCache'
    );

    package main;

    my $obj = MyObject->new(
        cache => Cache::FileCache->new({ ... });
    );

    $obj->cache_get($key);
    $obj->cache_set($key);
    $obj->cache_del($key);

    # {
    #   results => {
    #       key1 => $cache_hit_value1,
    #       key2 => $cache_hit_value2,
    #       ...
    #   },
    #   missing => [ 'key3', 'key4', 'key5' .... ]
    # }

=head1 METHODS

=head2 build_cache_del_method

=head2 build_cache_get_method

=head2 build_cache_set_method

=head2 install_cache_attr

=cut
