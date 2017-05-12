package Plack::Middleware::Reproxy;
use strict;
use parent qw(Plack::Middleware);
our $VERSION = '0.00004';

sub call {
    my ($self, $env) = @_;

    my $res = $self->app->( $env );

    # Otherwise, wait for headers
    return $self->response_cb( $res, sub {
        my $res = shift;

        if ($res->[0] ne '200') {
            # Not success, then just pass through
            return;
        }
 
        # Now check header
        my $reproxy_url = Plack::Util::header_get( $res->[1], 'X-Reproxy-URL' );
        if ($reproxy_url) {
            # it's a reproxy!
            $reproxy_url = URI->new($reproxy_url);
            if (! $reproxy_url->scheme) {
                $reproxy_url->scheme( $ENV{'psgi.url_scheme'} );
            }
            if (! $reproxy_url->host) {
                $reproxy_url->host( $ENV{HTTP_HOST} || $ENV{SERVER_NAME} );
            }
            return $self->reproxy_to( $res, $env, $reproxy_url );
        }
    } );
}

sub extract_headers {
    my ($self, $env) = @_;
    return map {
        (my $field = $_) =~ s/^HTTPS?_//;
        ( $field => $env->{$_} );
    } grep { /^(?:HTTP|CONTENT(?!_TYPE$)|COOKIE)/i } keys %$env;
}

1;

__END__

=head1 NAME

Plack::Middleware::Reproxy - Handle X-Reproxy-URL From Within Plack

=head1 SYNOPSIS

    # Use Furl
    builder {
        enable 'Reproxy::Furl';
        $app;
    }

    # or if you want your custom reproxy
    builder {
        enable 'Reproxy::Callback', cb => sub {
            my ($middleware, $res, $env, $uri) = @_;
            ....
        };
        $app;
    }

=head1 DESCRIPTION

Plack::Middleware::Reproxy implements a simple reproxy mechanism via
X-Reproxy-URL, like https://github.com/kazuho/mod_reproxy.

=head1 DISCLAIMER

This module was developed for I<TESTING>, and so has not been extensively
used in real environments. If you need real reproxying, you should probably
use that of lighttpd, nginx, apache+mod_reproxy, etc.

=head1 AUTHOR

Daisuke Maki C<< daisuke@endeworks.jp >>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
