package Net::Prober::Probe::TCP;
$Net::Prober::Probe::TCP::VERSION = '0.16';
use strict;
use warnings;

use base 'Net::Prober::Probe::Base';

use IO::Socket::INET;

sub defaults {
    return {
        host => undef,
        port => undef,
        ssl  => 0,
    }
}

sub open_socket {
    my ($self, $args) = @_;

    # TODO ipv6?
    my ($host, $port, $ssl, $timeout) = $self->parse_args(
        $args, qw(host port ssl timeout)
    );

    if ($ssl) {
        #arn "# Trying to connect through SSL to $host:$port with timeout $timeout\n";
        require IO::Socket::SSL;
        return IO::Socket::SSL->new(
            PeerAddr => $host,
            PeerPort => $port,
            SSL_verify_mode => 0,
            Timeout  => $timeout,
        );
    }

    # Unix sockets support (ex.: /tmp/mysqld.sock)
    if (defined $port && $port =~ m{^/}) {
        require IO::Socket::UNIX;
        return IO::Socket::UNIX->new($port);
    }

    # Normal TCP socket to host:port
    #arn "# Trying to connect to $host:$port with timeout $timeout\n";
    return IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Timeout  => $timeout,
    );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Prober::Probe::TCP

=head1 VERSION

version 0.16

=head1 AUTHOR

Cosimo Streppone <cosimo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Cosimo Streppone.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
