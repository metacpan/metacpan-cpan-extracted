package Net::Proxy::Connector::dual;
$Net::Proxy::Connector::dual::VERSION = '0.13';
use strict;
use warnings;
use Carp;
use Scalar::Util qw( reftype );

use Net::Proxy::Connector;
our @ISA = qw( Net::Proxy::Connector );

sub init {
    my ($self) = @_;

    # check connectors
    for my $conn (qw( client_first server_first )) {
        croak "'$conn' connector required" if !exists $self->{$conn};

        croak "'$conn' connector must be a HASHREF"
            if ref $self->{$conn} ne 'HASH';

        croak "'type' key required for '$conn' connector"
            if !exists $self->{$conn}{type};

        croak "'hook' key is not a CODE reference for '$conn' connector"
            if $self->{$conn}{hook}
            && reftype( $self->{$conn}{hook} ) ne 'CODE';

        # load the class
        my $class = 'Net::Proxy::Connector::' . $self->{$conn}{type};
        eval "require $class";
        croak "Couldn't load $class for '$conn' connector: $@" if $@;

        # create and store the Connector object
        $self->{$conn} = $class->new( $self->{$conn} );
        $self->{$conn}->set_proxy($self->{_proxy_});
    }

    # other parameters
    croak q{Parameter 'port' is required} if !exists $self->{port};
    $self->{timeout} ||= 1;              # by default wait for one second
    $self->{host}    ||= 'localhost';    # by default listen on localhost

    return;
}

# IN
*listen = \&Net::Proxy::Connector::raw_listen;

sub accept_from {
    my ( $self, $listen ) = @_;
    my $sock = $self->raw_accept_from($listen);

    # find out who speaks first
    # if the client talks first, it's a client_first connection
    my $waiter = IO::Select->new($sock);
    my @waited = $waiter->can_read( $self->{timeout} );
    my $type   = @waited ? 'client_first' : 'server_first';

    # do the outgoing connection
    $self->{$type}->_out_connect_from($sock);

    return $sock;
}

# OUT

# READ
*read_from = \&Net::Proxy::Connector::raw_read_from;

# WRITE
*write_to = \&Net::Proxy::Connector::raw_write_to;

1;

__END__

=encoding utf-8

=head1 NAME

Net::Proxy::Connector::dual - Y-shaped Net::Proxy connector

=head1 DESCRIPTION

Net::Proxy::Connecter::dual is a L<Net::Proxy::Connector>
that can forward the connection to two distinct services,
based on the client connection, before any data is exchanged.

=head1 CONNECTOR OPTIONS

This connector can only work as an C<in> connector.

The C<server_first> and C<client_first> options are required: they
are hashrefs containing the options necessary to create two C<out>
L<Net::Proxy::Connector> objects that will be used to connect to
the requested service.

The Net::Proxy::Connector::dual object decides between the two
services by waiting during a short timeout. If the client sends
some data directly, then it is connected via the C<client_first>
connector. Otherwise, at the end of the timeout, it is connected
via the C<server_first> connector.

=over 4

=item host

The hostname on which the connector will listen for client connections.
Default is C<localhost>.

=item port

The port on which the connector will listen for client connections.

=item server_first

Typically an C<out> connector to a SSH server or any service that sends
a banner line.

=item client_first

Typically an C<out> connectrot to a web server or SSL server.

=item timeout

The timeout in seconds (can be decimal) to make a decision.
Default is 1 second.

=back

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>.

=head1 ACKNOWLEDGMENTS

This module is based on a script named B<sslh>, which I wrote with
Frédéric Plé C<< <frederic.ple+sslh@gmail.com> >> (who had the original insight
about the fact that not all servers speak first on the wire).

Frédéric wrote a C program, while I wrote a Perl script (based on my
experience with B<connect-tunnel>).

Now that C<Net::Proxy> is available, I've ported the Perl script to use it.

=head1 COPYRIGHT

Copyright 2006-2014 Philippe 'BooK' Bruhat, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

