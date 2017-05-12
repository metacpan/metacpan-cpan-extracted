package MooseX::WithCache::Backend;
use Moose;

BEGIN {
    if (MooseX::WithCache::DEBUG()) {
        require Data::Dump;
    }
}

has cache_type => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

has can_coerce => (
    is => 'ro',
    isa => 'Bool',
    default => 0
);

has methods => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1
);

sub _build_cache_type {}
sub _build_methods {
    return {
        cache_get => sub {
            my ($self, $key) = @_;
            my $cache = $self->__get_cache();
            if ($self->cache_disabled || ! $cache) {
                if (MooseX::WithCache::DEBUG()) {
                    $self->cache_debug(blessed $self, "cache_get: Cache disabled");
                }
                return ();
            }

            my $keygen = $self->cache_key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            my $cache_ret =  $cache->get($cache_key);
            if (MooseX::WithCache::DEBUG()) {
                $self->cache_debug(
                    blessed $self,
                    "cache_get:\n    + status:",
                    defined $cache_ret ? "[HIT]" : "[MISS]",
                    "\n    + key =", (
                        $cache_key ? (
                            $keygen ? Data::Dump::dump($key) . " ($cache_key)" : $cache_key 
                        ) : '(null)' ),
                );
            }
            return $cache_ret;
        },
        cache_set => sub {
            my ($self, $key, $value, $expire) = @_;
            my $cache = $self->__get_cache();
            if ($self->cache_disabled || ! $cache) {
                if (MooseX::WithCache::DEBUG()) {
                    $self->cache_debug(blessed $self, "cache_set: Cache disabled");
                }
                return ();
            }

            my $keygen = $self->cache_key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            if (MooseX::WithCache::DEBUG()) {
                $self->cache_debug(
                    blessed $self, 
                    "cache_set:\n    + key =", (
                        $cache_key ? (
                            $keygen ? Data::Dump::dump($key) . " ($cache_key)" : $cache_key 
                        ) : '(null)' ),
                    "\n    + expire =",
                    ($expire || '(null)'),
                    MooseX::WithCache::DEBUG() > 1 ? (
                        "\n    + value =",
                        ($value ? Data::Dump::dump($value) : '(null)'),
                    ) : '',
                );
            }
            return $cache->set($cache_key, $value, $expire);
        },
        cache_del => sub {
            my ($self, $key) = @_;
            my $cache = $self->__get_cache();
            if ($self->cache_disabled || ! $cache) {
                if (MooseX::WithCache::DEBUG()) {
                    $self->cache_debug(blessed $self, "cache_del: Cache disabled");
                }
                return ();
            }

            my $keygen = $self->cache_key_generator;
            my $cache_key = $keygen ? $keygen->generate($key) : $key;
            if (MooseX::WithCache::DEBUG()) {
                $self->cache_debug(
                    blessed $self,
                    "cache_del:\n    + key =", (
                        $cache_key ? (
                            $keygen ? Data::Dump::dump($key) . " ($cache_key)" : $cache_key 
                        ) : '(null)' ),
                );
            }
            return $cache->delete($cache_key);
        },
    };
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=head1 NAME

MooseX::WithCache::Backend - Base Class For All Backends

=head1 SYNOPSIS

    package MyBackend;
    use Moose;
    extends 'MooseX::WithCache::Backend';

=head1 METHODS

=head1 cache_type

Holds the Moose type of the cache attribute

=head1 methods

Holds the map of methods that this backend will install on the applicant class.

=cut
