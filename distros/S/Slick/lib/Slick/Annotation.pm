package Slick::Annotation;

use 5.036;

use Exporter     qw(import);
use Carp         qw(carp);
use JSON::Tiny   qw(decode_json encode_json);
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(cacheable);

sub cacheable {
    my $cache   = shift;
    my $code    = shift;
    my $timeout = shift // 300;    # Default cache is 5 minutes

    return sub {
        my ( $app, $context ) = @_;

        state $cache_obj = $app->cache($cache);

        if ($cache_obj) {
            if ( $cache_obj->get( $context->request->uri ) ) {
                my $response =
                  decode_json( $cache_obj->get( $context->request->uri ) );

                $context->from_psgi($response);
            }
            else {
                $code->( $app, $context );

                my $json = encode_json $context->to_psgi;

                if ( blessed( $cache_obj->{_executor} ) =~ /Memcached/x ) {
                    $cache_obj->set(
                        $context->request->uri => $json => $timeout );
                }
                else {
                    $cache_obj->set(
                        $context->request->uri => $json => EX => $timeout );
                }
            }
        }
        else {
            carp
qq{Attempted to use cache $cache to cache route but cache does not exist.};
            $code->( $app, $context );
        }
    }
}

1;

=encoding utf8

=head1 NAME

Slick::Annotation

=head1 SYNOPSIS

A functional module for "annotations", simply functions that can compose
nicely to add functionality to routes.

=head1 cacheable

    use 5.036;

    use Slick;
    use Slick::Annotation qw(cacheable);

    my $s = Slick->new;

    # See Redis and Cache::Memcached on CPAN for arguments

    # Create a Redis instance
    $s->cache(
        my_redis => type => 'redis',    # Slick Arguments
        server   => '127.0.0.1:6379'    # Cache::Memcached arguments
    );

    # Use your cache to cache your route
    $s->get(
        '/foobar' => cacheable(
            'my_redis', # cache name
            sub {
                my ( $app, $context ) = @_;
                return $context->json( { foo => 'bar' } );
            }
        )
    );

    $s->run;

Declares a route sub-routine as "cacheable" meaning it will
always return the same response, and retrieve that response from a
specified cache. See L<Slick::Cache> for more information about
caching.

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
