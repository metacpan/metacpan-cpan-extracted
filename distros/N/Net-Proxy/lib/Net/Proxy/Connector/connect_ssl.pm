package Net::Proxy::Connector::connect_ssl;
$Net::Proxy::Connector::connect_ssl::VERSION = '0.13';
use strict;
use warnings;
use Carp;

use Net::Proxy::Connector;
use Net::Proxy::Connector::connect;
our @ISA = qw( Net::Proxy::Connector::connect );

# we can't subclass Net::Proxy::Connector::ssl, because we don't want listen()
# so, mix-in the needed methods from Net::Proxy::Connector::ssl
use Net::Proxy::Connector::ssl;
*upgrade_SSL = \&Net::Proxy::Connector::ssl::upgrade_SSL;

# IN

# OUT
sub connect {
    my ($self) = (@_);

    # connect to the proxy, just like Net::Proxy::Connector::connect
    my $sock = $self->SUPER::connect(@_);

    # set a temporary nickname for the socket
    Net::Proxy->set_nick( $sock,
              $sock->sockhost() . ':'
            . $sock->sockport() . ' -> '
            . $sock->peerhost() . ':'
            . $sock->peerport() );
    Net::Proxy->notice( 'Connected (HTTP) ' . Net::Proxy->get_nick($sock) );

    # and then upgrade the socket to SSL
    return $self->upgrade_SSL($sock);
}

# READ

# WRITE

1;

__END__

=head1 NAME

Net::Proxy::Connector::connect_ssl - Create SSL/CONNECT tunnels through HTTP proxies

=head1 SYNOPSIS

    # sample proxy using Net::Proxy::Connector::tcp
    #                and Net::Proxy::Connector::connect_ssl
    use Net::Proxy;

    # listen on localhost:6789
    # and proxy to remotehost:9876 through proxy.company.com:8080
    # using the given credentials
    my $proxy = Net::Proxy->new(
        in  => { type => 'tcp', port => '6789' },
        out => {
            type        => 'connect_ssl',
            host        => 'remotehost',
            port        => '9876',
            proxy_host  => 'proxy.company.com',
            proxy_port  => '8080',
            proxy_user  => 'jrandom',
            proxy_pass  => 's3kr3t',
            proxy_agent => 'Mozilla/4.04 (X11; I; SunOS 5.4 sun4m)',
        },
    );
    $proxy->register();

    Net::Proxy->mainloop();

=head1 DESCRIPTION

Net::Proxy::Connecter::connect_ssl is a L<Net::Proxy::Connector> that
uses the HTTP CONNECT method to ask the proxy to create a tunnel to
an outside server. The data is then encrypted using SSL.

Obviously, you'll need a server that understands SSL (or a proxy using
L<Net::Proxy::Connector::ssl>) at the other end.

This connector is only an "out" connector.

In addition to the options listed below, this connector accepts all
C<SSL_...> options to L<IO::Socket::SSL>. They are transparently passed
through to the appropriate L<IO::Socket::SSL> methods when upgrading
the socket to SSL.

=head1 CONNECTOR OPTIONS

Net::Proxy::Connector::connect_ssl accepts the following options:

=head1 C<out>

=over 4

=item host

The destination host.

=item port

The destination port.

=item proxy_host

The web proxy name or address.

=item proxy_port

The web proxy port.

=item proxy_user

The authentication username for the proxy.

=item proxy_pass

The authentication password for the proxy.

=item proxy_agent

The user-agent string to use when connecting to the proxy.

=back

=head1 METHODS

The Net::Proxy::Connector::connect_ssl connector has an extra method,
obtained from L<Net::Proxy::Connector::ssl>:

=head2 upgrade_SSL

    $connector->upgrade_SSL( $sock )

This method will upgrade a cleartext socket to SSL.
If the socket is already in SSL, it will C<carp()>.

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>.

=head1 HISTORY

Because L<Net::Proxy> blocks when it tries to connect to itself,
it wasn't possible to pass an SSL-encrypted connection through
a proxy with a single script: you needed one for the SSL encapsulation,
and another one for bypassing the proxy with the C<CONNECT> HTTP method.

See L<Net::Proxy::Connector::connect> and L<Net::Proxy::Connector::ssl>
for details.

=head1 COPYRIGHT

Copyright 2007-2014 Philippe 'BooK' Bruhat, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

