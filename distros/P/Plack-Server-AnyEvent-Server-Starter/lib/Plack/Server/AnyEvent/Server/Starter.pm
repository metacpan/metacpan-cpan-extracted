
package Plack::Server::AnyEvent::Server::Starter;
use strict;
use warnings;
use base qw(Plack::Server::AnyEvent);
use AnyEvent;
use AnyEvent::Util qw(fh_nonblocking guard);
use AnyEvent::Socket qw(format_address);
use IO::Socket::INET;
use Server::Starter qw(server_ports);

our $VERSION = '0.00002';

# Server::Starter requires us to perform fdopen on a descriptor NAME...
# that's what we do here
# This code is stolen from AnyEvent-5.24 AnyEvent::Socket::tcp_server
sub _create_tcp_server {
    my ( $self, $app ) = @_;

    my ($hostport, $fd) = %{Server::Starter::server_ports()};
    if ($hostport =~ /(.*):(\d+)/) {
        $self->{host} = $1;
        $self->{port} = $2;
    } else {
        $self->{host} ||= '0.0.0.0';
        $self->{port} = $hostport;
    }

    # /WE/ don't care what the address family, type of socket we got, just    # create a new handle, and perform a fdopen on it. So that part of
    # AE::Socket::tcp_server is stripped out

    my %state;
    $state{fh} = IO::Socket::INET->new(
        Proto => 'tcp',
        Listen => 128, # parent class returns, zero, so set to AE::Socket's default
    );

    $state{fh}->fdopen( $fd, 'w' ) or
        Carp::croak "failed to bind to listening socket: $!";
    fh_nonblocking $state{fh}, 1;

    my $accept = $self->_accept_handler($app);
    $state{aw} = AE::io $state{fh}, 0, sub {
        # this closure keeps $state alive
        while ($state{fh} && (my $peer = accept my $fh, $state{fh})) {
            fh_nonblocking $fh, 1; # POSIX requires inheritance, the outside world does not

            my ($service, $host) = AnyEvent::Socket::unpack_sockaddr($peer);
            $accept->($fh, format_address $host, $service);
        }
    };

    warn "Accepting requests at http://$self->{host}:$self->{port}/\n";
    defined wantarray
        ? guard { %state = () } # clear fh and watcher, which breaks the circular dependency
        : ()
}

1;

__END__

=head1 NAME

Plack::Server::AnyEvent::Server::Starter - Use AnyEvent-Based Plack Apps From Server::Starter

=head1 SYNOPSIS

   % start_server --port=80 -- plackup -s AnyEvent::Server::Starter

=head1 DEPRECATION WARNING

This module is now merged with Twiggy, and is now deprecated. Please use Plack 0.99+ and Twiggy instead.

=head1 DESCRIPTION

Plack::Server::AnyEvent::Server::Starter is a wrapper to manage L<Plack::Server::AnyEvent> using L<Server::Starter>. Use this module when, for example, you want to run a L<Tatsumaki> app (which is AnyEvent based) via L<Server::Starter>.

=head1 SEE ALSO

L<Twiggy>
L<Server::Starter>
L<Plack::Server::AnyEvent>
L<Plack::Server::Standalone::Prefork::Server::Starter>

=head1 AUTHOR

Daisuke Maki

Much code stolen from AnyEvent 5.24 (by Marc Lehman), and Server::Starter SYNOPSIS (Kazuho Oku)

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
