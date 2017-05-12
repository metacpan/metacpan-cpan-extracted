package Net::Proxy::Connector::ssl;
$Net::Proxy::Connector::ssl::VERSION = '0.13';
use strict;
use warnings;

use Net::Proxy::Connector;
use IO::Socket::SSL;
use Scalar::Util qw( refaddr );
use Carp;

our @ISA = qw( Net::Proxy::Connector );

my %IS_SSL;

sub init {
    my ($self) = @_;

    # set up some defaults
    $self->{host} ||= 'localhost';
}

# IN
sub listen {
    my ($self) = @_;
    my $sock;

    # start as a SSL socket (default)
    if ( !$self->{start_cleartext} ) {
        $sock = IO::Socket::SSL->new(
            Listen    => 1,
            LocalAddr => $self->{host},
            LocalPort => $self->{port},
            Proto     => 'tcp',
            map { $_ => $self->{$_} } grep { /^SSL_/ } keys %$self
        );

        # this exception is not catched by Net::Proxy
        die "Can't listen on $self->{host} port $self->{port}: "
            . IO::Socket::SSL::errstr()
            unless $sock;
    }

    # or as a standard TCP socket, which may be upgraded later
    else {
        $sock = IO::Socket::INET->new(
            Listen    => 1,
            LocalAddr => $self->{host},
            LocalPort => $self->{port},
            Proto     => 'tcp',
        );

        # this exception is not catched by Net::Proxy
        die "Can't listen on $self->{host} port $self->{port}: $!"
            unless $sock;
    }

    # remember the class of the socket
    $IS_SSL{ refaddr $sock } = !$self->{start_cleartext};

    Net::Proxy->set_nick( $sock,
        'SSL listener ' . $sock->sockhost() . ':' . $sock->sockport() );

    Net::Proxy->info( 'Started '
          . Net::Proxy->get_nick($sock) . ' as '
          . ( $self->{start_cleartext} ? 'cleartext' : 'SSL' ) );

    return $sock;
}

sub accept_from {
    my ($self, $listen) = @_;
    my $sock = $listen->accept();
    die IO::Socket::SSL::errstr() if ! $sock;

    Net::Proxy->set_nick( $sock,
              $sock->peerhost() . ':'
            . $sock->peerport() . ' -> '
            . $sock->sockhost() . ':'
            . $sock->sockport() );
    Net::Proxy->notice( 'Accepted ' . Net::Proxy->get_nick( $sock ) );

    return $sock;
}


# OUT
sub connect {
    my ($self) = @_;
    my $sock;

    # connect as a SSL socket (default)
    if ( !$self->{start_cleartext} ) {
        $sock = IO::Socket::SSL->new(
            PeerAddr => $self->{host},
            PeerPort => $self->{port},
            Proto    => 'tcp',
            Timeout  => $self->{timeout},
            map { $_ => $self->{$_} } grep { /^SSL_/ } keys %$self
        );
    }

    # or as a standard TCP socket, which may be upgraded later
    else {
        $sock = IO::Socket::INET->new(
            PeerAddr => $self->{host},
            PeerPort => $self->{port},
            Proto    => 'tcp',
            Timeout  => $self->{timeout},
        );
    }

    die $self->{start_cleartext} ? $! : IO::Socket::SSL::errstr() unless $sock;

    return $sock;
}

# READ
*read_from = \&Net::Proxy::Connector::raw_read_from;

# WRITE
*write_to = \&Net::Proxy::Connector::raw_write_to;

# SSL-related methods

# upgrade the socket to SSL (if needed)
sub upgrade_SSL {
    my ( $self, $sock ) = @_;

    if ( $IS_SSL{ refaddr $sock } ) {
        carp( Net::Proxy->get_nick($sock) . ' already is a SSL socket' );
        return $sock;
    }

    IO::Socket::SSL->start_SSL(
        $sock,
        SSL_server => $self->is_in(),
        map { $_ => $self->{$_} } grep { /^SSL_/ } keys %$self
    );
    $IS_SSL{ refaddr $sock } = 1;

    Net::Proxy->notice( 'Upgraded ' . Net::Proxy->get_nick($sock) . ' to SSL' );

    return $sock;
}

1;

__END__

=head1 NAME

Net::Proxy::Connector::ssl - SSL Net::Proxy connector

=head1 DESCRIPTION

C<Net::Proxy::Connecter::ssl> is a C<Net::Proxy::Connector>
that can manage SSL connections (thanks to C<IO::Socket::SSL>).

By default, this connector creates SSL sockets. You will need to
subclass it to create "smarter" connectors than can upgrade their
connections to SSL.

In addition to the options listed below, this connector accepts all
C<SSL_...> options to C<IO::Socket::SSL>. They are transparently passed
through to the appropriate C<IO::Socket::SSL> methods when needed.

=head1 CONNECTOR OPTIONS

The connector accept the following options:

=head2 C<in>

=over 4

=item host

The listening address. If not given, the default is C<localhost>.

=item port

The listening port.

=item start_cleartext

If true, the connection will start in cleartext.
It is possible to upgrade a socket to using SSL with
the C<upgrade_SSL()> method.

=back

=head2 C<out>

=over 4

=item host

The listening address. If not given, the default is C<localhost>.

=item port

The listening port.

=item start_cleartext

If true, the connection will start in cleartext.
It is possible to upgrade a socket to using SSL with
the C<upgrade_SSL()> method.

=back

=head1 METHODS

The Net::Proxy::Connector::ssl connector has an extra method:

=head2 upgrade_SSL

    $connector->upgrade_SSL( $sock )

This method will upgrade a cleartext socket to SSL.
If the socket is already in SSL, it will C<carp()>.

=head1 CREATING A SELF-SIGNED CERTIFICATE

I tend to forget this information, and the openssl documentation
doesn't make this any clearer, so here are the most basic commands
needed to create your own self-signed certificate (courtesy David
Morel):

    $ openssl genrsa -out key.pem 1024
    $ openssl req -new -key key.pem -x509 -out cert.pem -days 365

A certificate is required is you want to run a SSL server or a proxy
with a C<Net::Proxy::Connector::ssl> as its C<in> connector.

Once the key and certificate have been created, you can use them
in your parameter list to C<< Net::Proxy->new() >> (they are passed through
to C<IO::Socket::SSL>):

    Net::Proxy->new(
        {
            in => {
                host          => '0.0.0.0',
                port          => 443,
                SSL_key_file  => 'key.pem',
                SSL_cert_file => 'cert.pem',
            },
            out => { type => 'tcp', port => '80' }
        }
    );

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2006-2014 Philippe 'BooK' Bruhat, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

