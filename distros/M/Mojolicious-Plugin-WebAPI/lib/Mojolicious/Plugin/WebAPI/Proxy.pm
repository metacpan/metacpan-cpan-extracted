package Mojolicious::Plugin::WebAPI::Proxy;

# ABSTRACT: Proxy for WebAPI integration

use Mojo::Base 'Mojolicious';
use Plack::Util;

has 'script';
has 'app';
has 'base';

sub handler {
    my ($self, $c) = @_;

    if(!defined $self->app) {
        $self->app(Plack::Util::load_psgi($self->home->rel_file($self->script)));
    }

    my $plack_env = $self->_mojo_req_to_psgi_env($c->req);
    $plack_env->{'MOJO.CONTROLLER'} = $c;

    my $plack_res = $self->app->($plack_env);
    my $mojo_res  = _psgi_res_to_mojo_res($plack_res);

    $c->tx->res($mojo_res);
    $c->rendered;
}

sub _mojo_req_to_psgi_env {
    my $self     = shift;
    my $mojo_req = shift;

    my $url  = $mojo_req->url;
    my $base = $url->base;
    my $body = Mojolicious::Plugin::WebAPI::_PSGIInput->new($mojo_req->body);

    my %headers = %{$mojo_req->headers->to_hash};
    for my $key (keys %headers) {
        my $value = $headers{$key};
        delete $headers{$key};
        $key =~ s{-}{_};
        $headers{'HTTP_'. uc $key} = $value;
        $headers{uc $key} = $value;
    }

    my $path = $url->path->to_string;
    if ( $self->base ) {
        $path = '/' . $path if index( $path, '/' ) != 0;

        my $base = $self->base;
        $path =~ s{ \A $base }{}xms;
    }

    return {
        %ENV,
        %headers,
        'SERVER_PROTOCOL'   => 'HTTP/'. $mojo_req->version,
        'SERVER_NAME'       => $base->host,
        'SERVER_PORT'       => $base->port,
        'REQUEST_METHOD'    => $mojo_req->method,
        'SCRIPT_NAME'       => '',
        'PATH_INFO'         => $path,
        'REQUEST_URI'       => $url->to_string,
        'QUERY_STRING'      => $url->query->to_string,
        'psgi.url_scheme'   => $base->scheme,
        'psgi.multithread'  => Plack::Util::FALSE,
        'psgi.version'      => [1,1],
        'psgi.errors'       => *STDERR,
        'psgi.input'        => $body,
        'psgi.multithread'  => Plack::Util::FALSE,
        'psgi.multiprocess' => Plack::Util::TRUE,
        'psgi.run_once'     => Plack::Util::FALSE,
        'psgi.streaming'    => Plack::Util::TRUE,
        'psgi.nonblocking'  => Plack::Util::FALSE,
    };
}

sub _psgi_res_to_mojo_res {
    my $psgi_res = shift;

    my $mojo_res = Mojo::Message::Response->new;
    $mojo_res->code($psgi_res->[0]);

    my $headers = $mojo_res->headers;
    while (scalar @{$psgi_res->[1]}) {
        $headers->header(shift @{$psgi_res->[1]} => shift @{$psgi_res->[1]});
    }

    $headers->remove('Content-Length'); # should be set by mojolicious later

    my $asset = $mojo_res->content->asset;
    Plack::Util::foreach($psgi_res->[2], sub {$asset->add_chunk($_[0])});

    return $mojo_res;
}

package Mojolicious::Plugin::WebAPI::_PSGIInput;
use strict;
use warnings;

    sub new {
        my ($class, $content) = @_;
        return bless [$content, 0], $class;
    }

    sub read {
        my $self = shift;
        if ($_[0] = substr($self->[0], $self->[1], $_[1])) {
            $self->[1] += $_[1];
            return 1;
        }
    }

    sub seek {
        my $self = shift;

        $self->[1] = $_[0];
    }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::WebAPI::Proxy - Proxy for WebAPI integration

=head1 VERSION

version 0.04

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
