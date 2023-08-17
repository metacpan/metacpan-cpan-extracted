package Plack::App::Proxy::Backend::HTTP::Tiny;

=head1 NAME

Plack::App::Proxy::HTTP::Tiny - Backend for Plack::App::Proxy

=head1 SYNOPSIS

=for markdown ```perl

    # In app.psgi
    use Plack::Builder;

    builder {
        enable "Proxy::Requests";
        Plack::App::Proxy->new(backend => 'HTTP::Tiny', options => {
            timeout => 15
        })->to_app;
    };

=for markdown ```

=head1 DESCRIPTION

This backend uses L<HTTP::Tiny::PreserveHostHeader> to make HTTP requests.

L<HTTP::Tiny::PreserveHostHeader> is a wrapper for L<HTTP::Tiny> which is
Pure-Perl only and doesn't require any architecture specific files.

It is possible to bundle it e.g. by L<App::FatPacker>.

All I<options> from the L<Plack::App::Proxy> constructor goes to
L<HTTP::Tiny::PreserveHostHeader> constructor. This backend sets some default
options for L<HTTP::Tiny::PreserveHostHeader>:

=for markdown ```perl

    max_redirect => 0,
    http_proxy   => undef,
    https_proxy  => undef,
    all_proxy    => undef,

=for markdown ```

=for readme stop

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0204';

use parent qw(Plack::App::Proxy::Backend);

use HTTP::Headers;

use HTTP::Tiny::PreserveHostHeader;

sub call {
    my ($self, $env) = @_;

    return sub {
        my ($respond) = @_;

        my $http = HTTP::Tiny::PreserveHostHeader->new(
            max_redirect => 0,
            http_proxy   => undef,
            https_proxy  => undef,
            all_proxy    => undef,
            %{ $self->options || {} }
        );

        my $writer;

        my $response = $http->request(
            $self->method => $self->url,
            {
                headers       => $self->headers,
                content       => $self->content,
                data_callback => sub {
                    my ($data, $res) = @_;

                    return if $res->{status} =~ /^59\d+/;

                    if (not $writer) {
                        $env->{'plack.proxy.last_protocol'} = '1.1';    # meh
                        $env->{'plack.proxy.last_status'} = $res->{status};
                        $env->{'plack.proxy.last_reason'} = $res->{reason};
                        $env->{'plack.proxy.last_url'} = $self->url;

                        $writer = $respond->(
                            [
                                $res->{status},
                                [$self->response_headers->(HTTP::Headers->new(%{ $res->{headers} }))],
                            ]
                        );
                    }

                    $writer->write($data);
                },
            }
        );

        if ($writer) {
            $writer->close;
            return;
        }

        if ($response->{status} =~ /^59\d/) {
            return $respond->([502, ['Content-Type' => 'text/html'], ["Gateway error: $response->{content}"]]);
        }

        return $respond->(
            [
                $response->{status},
                [$self->response_headers->(HTTP::Headers->new(%{ $response->{headers} }))],
                [$response->{content}],
            ]
        );
    };
}

1;

=for readme continue

=head1 SEE ALSO

L<Plack>, L<Plack::App::Proxy>, L<Plack::Middleware::Proxy::Requests>,
L<HTTP::Tiny>, L<HTTP::Tiny::PreserveHostHeader>.

=head1 BUGS

This module might be incompatible with further versions of
L<Plack::App::Proxy> module.

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/perl-Plack-App-Proxy-Backend-HTTP-Tiny/issues>

The code repository is available at
L<http://github.com/dex4er/perl-Plack-App-Proxy-Backend-HTTP-Tiny>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2014-2016, 2023 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
