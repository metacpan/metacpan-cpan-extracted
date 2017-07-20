package Net::Prober::smtp;
$Net::Prober::smtp::VERSION = '0.17';
use strict;
use warnings;
use base 'Net::Prober::Probe::TCP';

sub args {
    return {
        host     => undef,
        port     => 25,
        timeout  => 30,
        ssl      => 0,
        username => undef,
        password => undef,
    };
}

sub probe {
    my ($self, $args) = @_;

    my ($host, $port, $timeout, $username, $password) =
        $self->parse_args($args, qw(host port timeout username password));

    my $t0 = $self->time_now();

    my $sock = $self->open_socket($args);
    if (! $sock) {
        return $self->probe_failed(
            reason => qq{Couldn't connect to smtp server $host:$port},
        );
    }

    chomp (my $esmtp_banner = $self->_get_reply($sock));

    if (! $esmtp_banner) {
        return $self->probe_failed(
            reason => qq{Couldn't get SMTP banner from $host:$port}
        );
    }

    if ($esmtp_banner !~ qr{^220 \s+ }x) {
        return $self->probe_failed(
            reason => qq{Incorrect SMTP banner from $host:$port? ($esmtp_banner)},
        );
    }

    $sock->send("QUIT\r\n");

    return $self->probe_ok(
        banner => $esmtp_banner,
        status => 220,
    );

}

sub _get_reply {
    my ($self, $sock) = @_;
    $sock->recv(my $reply, 256);
    return $reply;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Prober::smtp

=head1 VERSION

version 0.17

=head1 AUTHOR

Cosimo Streppone <cosimo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Cosimo Streppone.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
