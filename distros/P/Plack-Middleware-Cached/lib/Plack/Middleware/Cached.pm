use strict;
use warnings;
package Plack::Middleware::Cached;

use parent 'Plack::Middleware';
use Scalar::Util qw(blessed reftype);
use Carp 'croak';
use Plack::Util::Accessor qw(cache key set env);
use utf8;

our $VERSION = '0.15';

sub prepare_app {
    my ($self) = @_;

    croak "expected cache" unless $self->cache;

    croak "cache object must provide get and set"
        unless can_cache( $self->cache );

    # define how the caching key is calculated
    if (ref $self->key and ref $self->key eq 'ARRAY') {
        my $key = $self->key;
        $self->key( sub {
            my $env = shift;
            # stringify subset of the request environment
            join '\1E',
                map { ($_, $env->{$_}) }
                grep { defined $env->{$_} } @$key;
        } );
    } elsif (not $self->key) {
        $self->key('REQUEST_URI');
    }

    $self->set( sub { $_[0] } ) unless $self->set;
}

sub call {
    my ($self, $env) = @_;

    my $key = ref($self->key) ? $self->key->($env) : $env->{$self->key};

    return $self->app_code->($env) unless defined $key;

    # get from cache
    my $object = $self->cache->get( $key );
    if (defined $object) {
        my ($response, $mod_env) = @{$object};
        if ($mod_env) { # TODO: should we check $self->env ?
            while ( my ($key, $value) = each %$mod_env ) {
                $env->{$key} = $value;
            }
        }
        $env->{'plack.middleware.cached'} = 1;
        return $response;
    }

    # pass through and cache afterwards
    my $response = $self->app_code->($env);

    # streaming response 
    if (ref $response eq 'CODE') {
        $response = $self->response_cb($response, sub {
            my ($ret) = @_;
            my $seen;
            my $body = '';
            return sub {
                my ($chunk) = @_;
                if ($seen++ and not defined $chunk) {
                    my $new_response = [ $ret->[0], $ret->[1], [ $body ] ];
                    $self->cache_response($key, $new_response, $env);
                    return;
                }
                $body .= $chunk if defined $chunk;
                return $chunk;
            };
        });
    } else {
        $self->cache_response($key, $response, $env);
    }

    return $response;
}

# cache a response based on configuration of this middleware
sub cache_response {
    my ($self, $key, $response, $env) = @_;

    my @options = $self->set->($response, $env);
    if (@options and $options[0]) {
        $options[0] = [ $options[0] ];
        my $env_vars = $self->env;
        if ($env_vars) {
            $env_vars = [$env_vars] unless ref $env_vars;
            $options[0]->[1] = {
                map { $_ => $env->{$_} } @$env_vars
            };
        }
        $self->cache->set( $key, @options );
    }
}

# allows caching PSGI-like applications not derived from Plack::Component
sub app_code {
    my $app = shift->app;

    (blessed $app and $app->can('call'))
        ? sub { $app->call(@_) }
        : $app;
}

# duck typing test
sub can_cache {
    my $cache = shift;

    blessed $cache and
        $cache->can('set') and $cache->can('get');
}

1;

=head1 NAME

Plack::Middleware::Cached - Glues a cache to your PSGI application

=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::Middleware::Cached;

    my $cache = CHI->new( ... );       # create a cache

    builder {
        enable 'Cached',               # enable caching
            cache => $cache,           # using this cache
            key   => 'REQUEST_URI',    # using this key from env
            env   => ['my.a','my.b'];  # and cache $env{'my.a'} and $env{'my.b'},
        $app;
    }

    # alternative creation without Plack::Builder
    Plack::Middleware::Cached->wrap( $app, cache => $cache );

=head1 DESCRIPTION

This module can be used to glue a cache to a L<PSGI> applications or
middleware.  A B<cache> is an object that provides at least two methods to get
and set data, based on a key. Existing cache modules on CPAN include L<CHI>,
L<Cache>, and L<Cache::Cache>.  Although this module aims at caching PSGI
applications, you can use it to cache any function that returns some response
object based on a request environment.

Plack::Middleware::Cached is put in front of a PSGI application as middleware.
Given a request in form of a PSGI environment E, it either returns the matching
response R from its cache, or it passed the request to the wrapped application,
and stores the application's response in the cache:

                      ________          _____
    Request  ===E===>|        |---E--->|     |
                     | Cached |        | App |
    Response <==R====|________|<--R----|_____|

In most cases, only a part of the environment E is relevant to the request.
This relevant part is called the caching B<key>. By default, the key is set
to the value of REQUEST_URI from the environment E.

Some application may also modify the environment E:

                      ________          _____
    Request  ===E===>|        |---E--->|     |
                     | Cached |        | App |
    Response <==R+E==|________|<--R+E--|_____|

If needed, you can configure Plack::Middleware::Cached with B<env> to also
cache parts of the environment E, as it was returned by the application.

If Plack::Middleware::Cached retrieved a response from the cache, it sets the
environment variable C<plack.middleware.cached>. You can inspect whether a
response came from the cache or from the wrapped application like this:

    builder {
        enable sub {
            my $app = shift;
            sub {
                my $env = shift;
                my $res = $app->($env);
                if ($env->{'plack.middleware.cached') {
                    ...
                }
                return $res;
            };
        };
        enable 'Cached', cache => $cache;
        $app;
    },

Caching delayed/streaming responses is supported as well.

=head1 CONFIGURATION

=over 4

=item cache

An cache object, which supports the methods C<< get( $key ) >> to retrieve
an object from cache and C<< set( $key, $object [, @options ] ) >> to store
an object in cache, possibly adjusted by some options. See L<CHI> for a class
than can be used to create cache objects.

=item key

Key to map a PSGI environment to a scalar key. By default only the REQUEST_URI
variable is used, but you can provide another variable as scalar, a combination
of variables as array reference, or a code reference that is called to
calculate a key, given a PSGI environment. If this code returns undef, the
request is not cached.

=item env

Name of an environment variable or array reference with multiple variables from
the environment that should be cached together with a response.

=item set

Code reference to determine a policy for storing data in the cache. Each time
a response (and possibly environment data) is to be stored in the cache, it
is passed to this function. The code is expected to return an array with the
response as first value and optional options to the cache's 'set' method as
additional values. For instance you can pass an expiration time like this:

    set => sub {
        my ($response, $env) = @_;
        return ($response, expires_in => '20 min');
    }

You can also use this method to skip selected responses from caching:

    set => sub {
        my ($response, $env) = @_;
        if ( $some_condition_not_to_cache_this_response ) {
            return;
        }
        return $response;
    }

=back

=head1 SEE ALSO

There already are several modules for caching PSGI applications:
L<Plack::Middleware::Cache> by Ingy döt Net implements a simple file
cache for PSGI responses. Panu Ervamaa created a more general module of
same name, available at L<https://github.com/pnu/Plack-Middleware-Cache>.

=encoding utf8

=head1 AUTHOR
 
Jakob Voß
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2013 by Jakob Voß.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
 
=cut
