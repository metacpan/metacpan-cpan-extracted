
package MooseX::WithCache::Backend::Cache::Memcached;
use Moose;
use Moose::Util::TypeConstraints;

extends 'MooseX::WithCache::Backend';

foreach my $class (qw(Cache::Memcached Cache::Memcached::Fast Cache::Memcached::libmemcached)) {
    class_type $class;
    coerce $class 
        => from 'HashRef'
        => via { $class->new($_) }
    ;
}

sub _build_cache_type {
    return 'Cache::Memcached | Cache::Memcached::Fast | Cache::Memcached::libmemcached ';
}

has '+can_coerce' => ( default => 1 );

around _build_methods => sub {
    my ($next, $self) = @_;
    my $methods = $next->($self);

    $methods->{ cache_incr } = sub {
        my ($self, $key) = @_;
        my $cache = $self->__get_cache();
        if ($self->cache_disabled || ! $cache) {
            if (MooseX::WithCache::DEBUG()) {
                $self->cache_debug(blessed $self, "cache_incr: Cache disabled");
            }
            return ();
        }

        my $keygen = $self->cache_key_generator;
        my $cache_key = $keygen ? $keygen->generate($key) : $key;
        return $cache->incr($cache_key);
    };

    $methods->{ cache_decr } = sub {
        my ($self, $key) = @_;
        my $cache = $self->__get_cache();
        if ($self->cache_disabled || ! $cache) {
            if (MooseX::WithCache::DEBUG()) {
                $self->cache_debug(blessed $self, "cache_decr: Cache disabled");
            }
            return ();
        }

        my $keygen = $self->cache_key_generator;
        my $cache_key = $keygen ? $keygen->generate($key) : $key;
        return $cache->decr($cache_key);
    };

    $methods->{ cache_get_multi } = sub {
        my ($self, @keys) = @_;
        my $cache = $self->__get_cache();
        if ($self->cache_disabled || ! $cache) {
            if (MooseX::WithCache::DEBUG()) {
                $self->cache_debug(blessed $self, "cache_get_multi: Cache disabled");
            }
            return ();
        }

        my $keygen = $self->cache_key_generator;

        my @cache_keys = $keygen ? 
            map { $keygen->generate($_) } @keys :
            @keys;
        my %cache_ret = %{ $cache->get_multi(@cache_keys) };
        if (MooseX::WithCache::DEBUG()) {
            foreach my $key (@cache_keys) {
                $self->cache_debug(
                    blessed $self,
                    "cache_get_multi:\n",
                    "     + key =",
                    ($key || '(null)'),
                    "\n    + status =",
                    exists $cache_ret{$key} ? "[HIT]" : "[MISS]",
                );
            }
        }

        # in scalar context, returns a hashref
        # {
        #    results => \%results,
        #    missing => \@keys
        # }
        my $wantarray = wantarray;
        if ($wantarray) {
            return map { $cache_ret{$_} }
                grep { exists $cache_ret{$_} } @cache_keys;
        } elsif (defined $wantarray) {
            return {
                results => {
                    map {($keys[$_] => $cache_ret{$cache_keys[$_]}) } 
                    grep { exists $cache_ret{$cache_keys[$_]} } (0..$#keys)
                },
                missing => [ map { $keys[$_] } grep { ! exists $cache_ret{$cache_keys[$_]} } (0..$#keys) ]
            }
        }
    };

    return $methods;
};

no Moose;
no Moose::Util::TypeConstraints;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

MooseX::WithCache::Backend::Cache::Memcached - Cache::Memcached Backend

=head1 SYNOPSIS

    package MyObject;
    use MooseX::WithCache;
    with_cache(
        backend => 'Cache::Memcached'
    );

    package main;

    my $obj = MyObject->new(
        cache => Cache::Memcached->new({ ... });
    );

    $obj->cache_get($key);
    $obj->cache_set($key);
    $obj->cache_del($key);
    $obj->cache_incr($key);
    $obj->cache_decr($key);

    # In list context: returns the list of gotten results
    my @list = $obj->cache_get_multi(@keys);

    # In scalar context: returns a hashref with cached results,
    # and missing keys
    my $h = $obj->cache_get_multi(@keys);

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

=head2 build_cache_get_multi_method

=head2 build_cache_incr_method

=head2 build_cache_set_method

=head2 install_cache_attr

=cut
