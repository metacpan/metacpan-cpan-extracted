package Plack::App::Proxy::Backend::HTTP::Tiny;

=head1 NAME

Plack::App::Proxy::HTTP::Tiny - backend for Plack::App::Proxy

=head1 SYNOPSIS

  # In app.psgi
  use Plack::Builder;
  use Plack::App::Proxy::Anonymous;

  builder {
      enable "Proxy::Requests";
      Plack::App::Proxy->new(backend => 'HTTP::Tiny')->to_app;
  };

=head1 DESCRIPTION

This backend uses L<HTTP::Tiny> to make HTTP requests.

L<HTTP::Tiny> backend is Pure-Perl only and doesn't require any
architecture specific files.

It is possible to bundle it e.g. by L<App::FatPacker>.

=for readme stop

=cut


use 5.006;

use strict;
use warnings;

our $VERSION = '0.0100';


use parent qw(Plack::App::Proxy::Backend);

use HTTP::Headers;


sub call {
    my ($self, $env) = @_;

    return sub {
        my ($respond) = @_;

        my $ua = Plack::App::Proxy::Backend::HTTP::Tiny::PreserveHeaders->new(
            max_redirect => 0,
            %{ $self->options || {} }
        );

        my $writer;

        my $res = $ua->request(
            $self->method => $self->url, {
                headers => $self->headers,
                content => $self->content,
                data_callback => sub {
                    my ($data, $res) = @_;

                    return if $res->{status} =~ /^59\d+/;

                    if (not $writer) {
                        $env->{'plack.proxy.last_protocol'} = '1.1'; # meh
                        $env->{'plack.proxy.last_status'}   = $res->{status};
                        $env->{'plack.proxy.last_reason'}   = $res->{reason};
                        $env->{'plack.proxy.last_url'}      = $self->url;

                        $writer = $respond->([
                            $res->{status},
                            [$self->response_headers->(HTTP::Headers->new(%{$res->{headers}}))],
                        ]);
                    }

                    $writer->write($data);
                },
            }
        );

        if ($writer) {
            $writer->close;
            return;
        }

        if ($res->{status} =~ /^59\d/) {
            return $respond->([502, ['Content-Type' => 'text/html'], ["Gateway error: $res->{content}"]]);
        }

        return $respond->([
            $res->{status},
            [$self->response_headers->(HTTP::Headers->new(%{$res->{headers}}))],
            [$res->{content}],
        ]);
    };
}


package Plack::App::Proxy::Backend::HTTP::Tiny::PreserveHeaders;

use parent 'HTTP::Tiny';

# Preserve Host and User-Agent headers
sub _prepare_headers_and_cb {
    my ($self, $request, $args, $url, $auth) = @_;

    my ($host, $user_agent);

    while (my ($k, $v) = each %{$args->{headers}}) {
        $host = $v if lc $k eq 'host';
        $user_agent = $v if lc $k eq 'user-agent';
    }

    $self->SUPER::_prepare_headers_and_cb($request, $args, $url, $auth);

    $request->{headers}{'host'} = $host if $host;
    delete $request->{headers}{'user-agent'} if not defined $user_agent;

    return;
}


1;


=for readme continue

=head1 SEE ALSO

L<Plack>, L<Plack::App::Proxy>, L<Plack::Middleware::Proxy::Requests>,
L<HTTP::Tiny>.

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

Copyright (c) 2014 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
