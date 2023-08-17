package Plack::Middleware::Proxy::Connect::IO;

=head1 NAME

Plack::Middleware::Proxy::Connect::IO - CONNECT method

=head1 SYNOPSIS

=for markdown ```perl

    # In app.psgi
    use Plack::Builder;
    use Plack::App::Proxy;

    builder {
        enable "Proxy::Connect::IO", timeout => 30;
        enable "Proxy::Requests";
        Plack::App::Proxy->new->to_app;
    };

=for markdown ```

=head1 DESCRIPTION

This middleware handles the C<CONNECT> method. It allows to connect to
C<https> addresses.

The middleware runs on servers supporting C<psgix.io> and provides own
event loop so does not work correctly with C<psgi.nonblocking> servers.

The middleware uses only Perl's core modules: L<IO::Socket::INET> and
L<IO::Select>.

=for readme stop

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0305';

use parent qw(Plack::Middleware);

use Plack::Util::Accessor qw(
    timeout
);

use IO::Socket::INET;
use IO::Select;
use Socket qw(IPPROTO_TCP TCP_NODELAY);

use constant CHUNKSIZE       => 64 * 1024;
use constant DEFAULT_TIMEOUT => 60;
use constant READ_TIMEOUT    => 0.5;
use constant WRITE_TIMEOUT   => 0.5;

sub prepare_app {
    my ($self) = @_;

    # the default values
    $self->timeout(DEFAULT_TIMEOUT) unless defined $self->timeout;
}

sub call {
    my ($self, $env) = @_;

    return $self->app->($env)
        unless $env->{REQUEST_METHOD} eq 'CONNECT';

    return [501, [], ['']]
        unless $env->{'psgi.streaming'} and $env->{'psgix.io'};

    return sub {
        my ($respond) = @_;

        my $client = $env->{'psgix.io'};

        my ($host, $port) = $env->{REQUEST_URI} =~ m{^(?:.+\@)?(.+?)(?::(\d+))?$};

        my $remote = IO::Socket::INET->new(
            PeerAddr => $host,
            PeerPort => $port,
            Blocking => 0,
            Timeout  => $self->timeout,
        );

        if (!$remote) {
            if ($! eq 'Operation timed out') {
                return $respond->([504, [], ['']]);
            } else {
                return $respond->([502, [], ['']]);
            }
        }

        $client->blocking(0);

        # missing on Android
        if (eval { TCP_NODELAY }) {
            $client->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1);
            $remote->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1);
        }

        my $ioset = IO::Select->new;

        $ioset->add($client);
        $ioset->add($remote);

        my $writer = $respond->([200, []]);

        my $bufin = '';
        my $bufout = '';

    IOLOOP: while (1) {
            for my $socket ($ioset->can_read(READ_TIMEOUT)) {
                my $read = $socket->sysread(my $chunk, CHUNKSIZE);

                if ($read) {
                    if ($socket == $client) {
                        $bufout .= $chunk;
                    } elsif ($socket == $remote) {
                        $bufin .= $chunk;
                    }
                } else {
                    $client->syswrite($bufin);
                    $client->close;
                    $remote->syswrite($bufout);
                    $remote->close;
                    last IOLOOP;
                }
            }

            for my $socket ($ioset->can_write(WRITE_TIMEOUT)) {
                if ($socket == $client and length $bufin) {
                    my $write = $socket->syswrite($bufin);
                    substr $bufin, 0, $write, '';
                } elsif ($socket == $remote and length $bufout) {
                    my $write = $socket->syswrite($bufout);
                    substr $bufout, 0, $write, '';
                }
            }
        }
    };
}

1;

=head1 CONFIGURATION

=over 4

=item timeout

Timeout for the socket. The default value is C<60> seconds.

=back

=for readme continue

=head1 SEE ALSO

L<Plack>, L<Plack::App::Proxy>, L<Plack::Middleware::Proxy::Connect>.

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/perl-Plack-Middleware-Proxy-Connect-IO/issues>

The code repository is available at
L<http://github.com/dex4er/perl-Plack-Middleware-Proxy-Connect-IO>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2014, 2016, 2023 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
