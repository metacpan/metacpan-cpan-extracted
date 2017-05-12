package Perlbal::Plugin::ServerStarter;

use strict;
use warnings;

our $VERSION = '0.04';

use Perlbal;
use Server::Starter qw( server_ports );

sub load {
    my $class = shift;
    
    Perlbal::register_global_hook(
        'manage_command.listen' => sub {
            my $mc = shift->parse(
                qr{^listen\s*=\s*((?:.*:)?\d+)},
                "usage: Listen = <ip:port|port>",
            );
            my ($port) = $mc->args;

            my %port_to_fd = %{ server_ports() };
            my $svc        = Perlbal->service($mc->{ctx}{last_created});
            my $listener   = Perlbal::SocketListener->new($port_to_fd{$port}, $svc);
            $svc->{listener} = $listener;

            Perlbal::log(debug => $listener->as_string) if Perlbal::DEBUG;

            return $mc->ok;
        },
    );

    return 1;
}

sub unload {
    my $class = shift;
    Perlbal::unregister_global_hook('manage_command.listen');
    return 1;
}

sub unregister { 1 }
sub register   { 1 }


package # hide from CPAN
    Perlbal::SocketListener;

use base 'Perlbal::Socket';
use fields qw( service port_fd );

use Perlbal;
use IO::Socket::INET;
use Socket qw( SOL_SOCKET SO_SNDBUF );

sub new {
    my Perlbal::SocketListener $self = shift;
    my ($fd, $service, $opts) = @_;

    $self = fields::new($self) unless ref $self;
    $opts ||= {};

    my $sock = IO::Socket::INET->new(Proto => 'tcp');
    $sock->fdopen($fd, 'w') or die "failed to bind to socket: $!";
    if ($sock->blocking) {
        $sock->blocking(0) or die "$!";
    }

    $self->SUPER::new($sock);
    $self->{service} = $service;
    $self->{port_fd} = $fd;
    $self->watch_read(1);

    return $self;
}

sub event_read {
    my Perlbal::SocketListener $self = shift;

    while (my ($psock, $peeraddr) = $self->{sock}->accept) {
        if ($psock->blocking) {
            $psock->blocking(0) or die "$!";
        }
        if (my $sndbuf = $self->{service}->{client_sndbuf_size}) {
            my $rv = setsockopt($psock, SOL_SOCKET, SO_SNDBUF, pack("L", $sndbuf));
        }
        $self->class_new_socket($psock);
    }
}

## following methods are almost copied from Perlbal::TCPListener (v1.80)

sub class_new_socket {
    my Perlbal::SocketListener $self = shift;
    my $psock = shift;

    my $service_role = $self->{service}->role;
    if ($service_role eq "reverse_proxy") {
        return Perlbal::ClientProxy->new($self->{service}, $psock);
    }
    elsif ($service_role eq "management") {
        return Perlbal::ClientManage->new($self->{service}, $psock);
    }
    elsif ($service_role eq "web_server") {
        return Perlbal::ClientHTTP->new($self->{service}, $psock);
    }
    elsif ($service_role eq "selector") {
        return Perlbal::ClientHTTPBase->new($self->{service}, $psock, $self->{service});
    }
    elsif (my $creator = Perlbal::Service::get_role_creator($service_role)) {
        return $creator->($self->{service}, $psock);
    }
}

sub as_string {
    my Perlbal::SocketListener $self = shift;
    my $ret = $self->SUPER::as_string;
    my Perlbal::Service $svc = $self->{service};
    $ret .= ": listening on FD:$self->{port_fd} via 'start_server' for service '$svc->{name}'";
    return $ret;
}

sub as_string_html {
    my Perlbal::SocketListener $self = shift;
    my $ret = $self->SUPER::as_string_html;
    my Perlbal::Service $svc = $self->{service};
    $ret .= ": listening on FD:$self->{port_fd} via <em>start_server</em> for service <b>$svc->{name}</b>";
    return $ret;
}

sub die_gracefully {
    my $self = shift;
    $self->close('graceful_death');
}

1;

=pod

=head1 NAME

Perlbal::Plugin::ServerStarter - Perlbal plugin for Server::Starter support

=head1 SYNOPSIS

  ## in perlbal.conf
  LOAD ServerStarter
  CREATE SERVICE web
    SET role    = web_server
    SET docroot = /path/to/htdocs
    LISTEN = 5000
  ENABLE web

  ## command line
  $ start_server --port 5000 -- perlbal -c perlbal.conf

  ## use nifty wrapper script of start_server and perlbal combination
  $ start_perlbal -c perlbal.conf

=head1 DESCRIPTION

Perlbal::Plugin::ServerStarter is a plugin to be able to run perlbal via I<start_server> command of L<Server::Starter>. Therefor, the hot deployment of upgrading perlbal, plugins and configration changes is available by Perlbal!!

=head1 COMMANDS

=over 4

=item LISTEN = [ip:]port

Set port number listened by I<start_server>. Under using this plugin, all of 'SET listen = [ip:]port' lines should be replaced in this command, because I<start_sever> generate multiple perlbal processes with same configration at restarting processes.

=back

=head1 SEE ALSO

=over

=item L<Server::Starter>

=item L<Perlbal>

=back

=head1 AUTHOR

Hiroshi Sakai E<lt>ziguzagu@cpan.orgE<gt>

Repository available on github: L<https://github.com/ziguzagu/Perlbal-Plugin-ServerStarter/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
