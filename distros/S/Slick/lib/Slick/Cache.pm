package Slick::Cache;

use 5.036;

use Moo;
use Carp            qw(croak);
use List::Util      qw(reduce);
use Scalar::Util    qw(reftype);
use Types::Standard qw(Str HashRef);
use Module::Runtime qw(require_module);

has type => (
    is  => 'ro',
    isa => sub {
        my $s = shift;
        return grep { $_ eq $s } qw(redis memcached);
    },
    required => 1
);

has _executor => (
    is  => 'ro',
    isa => sub {
        my $s = shift;
        return blessed($s)
          && ( blessed($s) =~ /Slick\:\:CacheExecutor.*/x );
    },
    handles => [qw(get set incr decr raw)]
);

sub BUILD {
    my $self = shift;
    my $args = shift;

    delete $args->{type};

    my $package = ucfirst( $self->type );

    require_module("Slick::CacheExecutor::$package");
    $self->{_executor} =
      "Slick::CacheExecutor::$package"->new( [ $args->%* ]->@* );

    return $self;
}

1;

=encoding utf8

=head1 NAME

Slick::Cache

=head1 SYNOPSIS

A wrapper around a L<Slick::CacheExecutor> that either implements L<Redis> or L<Cache::Memcached>.

    use 5.036;

    use Slick;

    my $s = Slick->new;

    # See Redis and Cache::Memcached on CPAN for arguments

    # Create a Redis instance
    $s->cache(
        my_redis => type => 'redis',    # Slick Arguments
        server   => '127.0.0.1:6379'    # Cache::Memcached arguments
    );

    # Create a Memcached instance
    $s->cache(
        my_memcached => type          => 'memcached',   # Slick Arguments
        servers      => ['127.0.0.1'] => debug => 1     # Cache::Memcached arguments
    );

    $s->cache('my_redis')->set( something => 'awesome' );

    $s->get(
        '/foo' => sub {
            my ( $app, $context ) = @_;
            my $value = $app->cache('my_redis')->get('something');  # Use your cache
            return $context->text($value);
        }
    );

    $s->run;

=head1 API

=head2 raw

Returns the underlying L<Redis> or L<Cache::Memcached> objects.

=head2 set

   $s->cache('my_cache')->set(something => 'awesome');

Sets a value in the cache. Note, this is a facade for L<Redis>->set or L<Cache::Memcached>->set.

=head2 get

    $s->cache('my_cache')->get('something');

Gets a value from the cache, returns C<undef> if it that key does not exist.
Note, this is a facade for L<Redis>->get or L<Cache::Memcached>->get.

=head2 incr

    $s->cache('my_cache')->incr('value');

Attempts to increment a value in the cache.

=head2 decr

    $s->cache('my_cache')->decr('value');

Attempts to decrement a value in the cache.

=head1 See also

=over2

=item * L<Slick::CacheExecutor>

=item * L<Slick::CacheExecutor::Redis>

=item * L<Slick::CacheExecutor::Memcached>

=item * L<Slick::Context>

=item * L<Slick::Database>

=item * L<Slick::DatabaseExecutor>

=item * L<Slick::DatabaseExecutor::MySQL>

=item * L<Slick::DatabaseExecutor::Pg>

=item * L<Slick::EventHandler>

=item * L<Slick::Events>

=item * L<Slick::Methods>

=item * L<Slick::RouteMap>

=item * L<Slick::Util>

=back

=cut
