
package MooseX::WithCache;
use 5.008;
use constant DEBUG => $ENV{MOOSEX_WITHCACHE_DEBUG} ? 1 : 0;
use MooseX::Role::Parameterized;
use Class::Load qw/load_class/;
our $VERSION   = '0.01007';
our $AUTHORITY = 'cpan:DMAKI';
my %BACKENDS;

# This is solely for backwards compatibility
use Moose::Exporter;
Moose::Exporter->setup_import_methods(
    with_caller => [ 'with_cache' ],
);

sub with_cache {
    my ($caller, $name, %args) = @_;

    Carp::carp("use of with_cache for MooseX::WithCache is now deprecated. Use parameterized roles directly");

    Moose::Util::apply_all_roles(
        $caller,
        __PACKAGE__, {
            %args,
            name => $name,
        }
    );
}

parameter backend => (
    isa => 'Str',
    required => 1,
    default => 'Cache::Memcached',
);

parameter name => (
    isa => 'Str',
    required => 1,
    default => 'cache'
);

role {
    my $p = shift;

    my $name          = $p->name;
    my $backend_class = $p->backend;

    if ($backend_class !~ s/^\+//) {
        $backend_class = "MooseX::WithCache::Backend::$backend_class";
    }
    load_class($backend_class);
    my $backend = $BACKENDS{ $backend_class };
    if (! $backend ) {
        $backend = $backend_class->new();
        $BACKENDS{ $backend_class } = $backend;
    }

    has $name => (
        is => 'rw',
        isa => $backend->cache_type(),
        coerce => $backend->can_coerce(),
    );

    has cache_disabled => (
        is => 'rw',
        isa => 'Bool',
        default => 0
    );

    # key generator generates the appropriate cache key from given key(s). 
    has cache_key_generator => (
        is      => 'rw',
        does    => 'MooseX::WithCache::KeyGenerator',
    );

    method __get_cache => sub { $_[0]->$name };
    method cache_debug => sub {
        my $self = shift;
        print STDERR "[CACHE]: @_\n";
    };

    my $methods = $backend->methods();
    while (my($method, $code) = each %$methods) {
        method $method, $code;
    }
};

1;

__END__

=head1 NAME

MooseX::WithCache - Easy Cache Access From Moose Objects

=head1 SYNOPSIS

    package MyObject;
    use Moose;
    use MooseX::WithCache;

    with 'MooseX::WithCache' => {
        backend => 'Cache::Memcached',
    );

    no Moose;

    sub get_foo {
        my $self = shift;
        my $foo = $self->cache_get( 'foo' );
        if ($foo) {
            $foo = $self->get_foo_from_database();
            $self->cache_set(foo => $foo);
        }
        return $foo;
    }

    # main.pl
    my $object = MyObject->new(
        cache => Cache::Memcached->new({ ... })
    );

    my $foo = $object->get_foo();

    # if you want to do something with the cache object,
    # you can access it via the name you gave in with staemtent
    # 
    # with 'MooseX::WithCache' => {
    #    name => 'cache', # default
    #    ....
    # }

    my $cache = $object->cache;

=head1 DESCRIPTION

MooseX::WithCache gives your object instant access to cache objects.

MooseX::WithCache s not a cache object, it just gives your convinient methods
to access the cache through your objects.

By default, it gives you 3 methods:

    cache_get($key)
    cache_set($key, $value, $expires)
    cache_del($key)

But if there's a backend provided for it, you may get extra methods tailored
for that cache. For example, for Cache::Memcached, the backend provides
these additional methods:

    cache_get_multi(@keys);
    cache_incr($key);
    cache_decr($key);

=head2 STOP THAT CACHE

Data extraction/injection to the cache can be disabled. Simply set 
the cache_disabled() attribute that gets installed

    $object->cache_disabled(1);
    $object->cache_get($key); # won't even try

=head2 DEBUG OUTPUT

You can inspect what's going on with respect to the cache, if you specify
MOOSEX_WITHCACHE_DEBUG=1 in the environment. This will caue MooseX::WithCache to
display messages to STDERR.

=head2 KEY GENERATION

Sometimes you want to give compound keys, or simply transform the cache keys
somehow to normalize them.

MooseX::WithCache supports this through the cache_key_generator attribute.
The cache_key_generator simply needs to be a MooseX::WithCache::KeyGenerator
instance, which accepts whatever key provided, and returns a new key.

For example, if you want to provide complex key that is a perl structure,
and use its MD5 as the key, you can use MooseX::WithCache::KeyGenerator::DumpChecksum
to generate the keys.

Simply specify it in the constructor:

    MyObject->new(
        cache => ...,
        cache_key_generator => MooseX::WithCache::KeyGenerator::DumpChecksum->new()
    );

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
