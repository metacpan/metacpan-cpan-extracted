package Plack::Middleware::Throttle;

use Moose;
use Carp;
use Scalar::Util;
use DateTime;
use Plack::Util;

our $VERSION = '0.01';

extends 'Plack::Middleware';

has code => ( is => 'rw', isa => 'Int', lazy => 1, default => '503' );
has message =>
    ( is => 'rw', isa => 'Str', lazy => 1, default => 'Over rate limit' );
has backend => ( is => 'rw', isa => 'Object', required => 1 );
has key_prefix =>
    ( is => 'rw', isa => 'Str', lazy => 1, default => 'throttle' );
has max => ( is => 'rw', isa => 'Int', lazy => 1, default => 100 );
has white_list =>
    ( is => 'rw', isa => 'ArrayRef', predicate => 'has_white_list' );
has black_list =>
    ( is => 'rw', isa => 'ArrayRef', predicate => 'has_black_list' );
has path => ( is => 'rw', isa => 'RegexpRef', predicate => 'has_path' );

sub prepare_app {
    my $self = shift;
    $self->backend( $self->_create_backend( $self->backend ) );
}

sub _create_backend {
    my ( $self, $backend ) = @_;

    if ( defined !$backend ) {
        Plack::Util::load_class("Plack::Middleware::Throttle::Backend::Hash");
        return Plack::Middleware::Throttle::Backend::Hash->new;
    }

    return $backend if defined $backend && Scalar::Util::blessed $backend;
    die "backend must be a cache object";
}

sub call {
    my ( $self, $env ) = @_;

    my $res = $self->app->($env);

    return $res unless $self->path_is_throttled($env);

    return $res if $self->is_white_listed($env);
    return $self->forbiden if $self->is_black_listed($env);

    my $key     = $self->cache_key($env);
    my $allowed = $self->allowed($key);

    if ( !$allowed ) {
        $self->over_rate_limit();
    }
    else {
        $self->response_cb(
            $res,
            sub {
                my $res = shift;
                $self->add_headers($res);
            }
        );
    }
}

sub allowed {
    return 1;
}

sub request_done {
    return 1;
}

sub is_white_listed {
    my ( $self, $env ) = @_;
    return 0 if !$self->has_white_list;
    my $ip = $env->{REMOTE_ADDR};
    if ( grep { $_ == $ip } @{ $self->white_list } ) {
        return 1;
    }
    return 0;
}

sub is_black_listed {
    my ( $self, $env ) = @_;
    return 0 if !$self->has_black_list;
    my $ip = $env->{REMOTE_ADDR};
    if ( grep { $_ == $ip } @{ $self->black_list } ) {
        return 1;
    }
    return 0;
}

sub path_is_throttled {
    my ( $self, $env ) = @_;

    return 1 if !$self->has_path;
    my $path_match = $self->path;
    my $path = $env->{PATH_INFO};

    for ($path) {
        my $matched = 'CODE' eq ref $path_match ? $path_match->($_) : $_ =~ $path_match;
        $matched ? return 1 : return 0;
    }
    return 1;
}

sub forbiden {
    my $self = shift;
    return [
        403, [ 'Content-Type' => 'text/plain', ],
        ['your IP is black listed']
    ];
}

sub over_rate_limit {
    my $self = shift;
    return [
        $self->code,
        [
            'Content-Type'      => 'text/plain',
            'X-RateLimit-Reset' => $self->reset_time
        ],
        [ $self->message ]
    ];
}

sub add_headers {
    my ( $self, $res ) = @_;
    my $headers = $res->[1];
    Plack::Util::header_set( $headers, 'X-RateLimit-Limit', $self->max );
    Plack::Util::header_set( $headers, 'X-RateLimit-Reset',
        $self->reset_time );
    return $res;
}

sub client_identifier {
    my ( $self, $env ) = @_;
    if ( $env->{REMOTE_USER} ) {
        return $self->key_prefix."_".$env->{REMOTE_USER};
    }
    else {
        return $self->key_prefix."_".$env->{REMOTE_ADDR};
    }
}

1;
__END__

=head1 NAME

Plack::Middleware::Throttle - A Plack Middleware for rate-limiting incoming HTTP requests.

=head1 SYNOPSIS

  my $handler = builder {
    enable "Throttle::Hourly",
        max     => 2,
        backend => Plack::Middleware::Throttle::Backend::Hash->new(),
        path    => qr{^/api};
    sub { [ '200', [ 'Content-Type' => 'text/html' ], ['hello world'] ] };
  };

=head1 DESCRIPTION

This is a C<Plack> middleware that provides logic for rate-limiting incoming
HTTP requests to Rack applications.

This middleware provides three ways to handle throttling on incoming requests :

=over 4

=item B<Hourly>

How many requests an host can do in one hour. The counter is reseted each hour.

=item B<Daily>

How many requets an host can do in one hour. The counter is reseted each day.

=item B<Interval>

Which interval of time an host must respect between two request.

=back

=head1 OPTIONS

=over 4

=item B<code>

HTTP code returned in the response when the limit have been exceeded. By default 503.

=item B<message>

HTTP message returned in the response when the limit have been exceeded. By defaylt "Over rate limit".

=item B<backend>

A cache object to store sessions informations.

  backend => Redis->new(server => '127.0.0.1:6379');

or

  backend => Cache::Memcached->new(servers => ["10.0.0.15:11211", "10.0.0.15:11212"]);

The cache object must implement B<get>, B<set> and B<incr> methods. By default, you can use C<Plack::Middleware::Throttle::Backend::Hash>.

By default, if no backend is specified, L<Plack::Middleware::Throttle::Backend::Hash> is used.

=item B<key_prefix>

Key to prefix sessions entry in the cache.

=item B<path>

URL pattern or a callback to match request to throttle. If no path is specified, the whole application will be throttled.

=item B<white_list>

An arrayref of hosts to put in a white list.

=item B<black_list>

An arrayref of hosts to put in a black list.

=back

=head1 AUTHOR

franck cuny E<lt>franck@lumberjaph.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
