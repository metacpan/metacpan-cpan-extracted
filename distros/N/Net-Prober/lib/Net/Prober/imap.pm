package Net::Prober::imap;
$Net::Prober::imap::VERSION = '0.16';
use strict;
use warnings;
use base 'Net::Prober::Probe::TCP';

sub defaults {
    return {
        host     => undef,
        port     => 143,
        timeout  => 30,
        username => undef,
        password => undef,
        mailbox  => 'inbox',
        ssl      => 0,
    };
}

sub probe {
    my ($self, $args) = @_;

    my ($host, $port, $timeout, $username, $password, $mailbox, $ssl) =
        $self->parse_args($args, qw(host port timeout username password mailbox ssl));

    my $t0 = $self->time_now();

    my $sock = $self->open_socket($args);
    if (! $sock) {
        return $self->probe_failed(
            reason => qq{Couldn't connect to IMAP server $host:$port},
        );
    }

    chomp (my $imap_banner = $self->_get_reply($sock));

    if (! $imap_banner) {
        return $self->probe_failed(
            reason => qq{Couldn't get IMAP banner from $host:$port}
        );
    }

    if ($imap_banner !~ qr{\* \s+ OK}ix) {
        return $self->probe_failed(
            reason => qq{Incorrect IMAP banner from $host:$port? ($imap_banner)},
        );
    }

    # We can't try to login if we haven't got credentials
    if ($username && $password) {

        $self->_send_command($sock, login => $username, $password);
        if (! $self->_get_reply($sock)) {
            return $self->probe_failed(
                reason => qq{Couldn't login to imap $host:$port with user $username},
            );
        }

        $self->_send_command($sock, select => $mailbox);
        if (! $self->_get_reply($sock, qr{OK.*Completed}i)) {
            return $self->probe_failed(
                reason => qq{Couldn't select mailbox $mailbox when talking to imap $host:$port}
            );
        }

    }

    # Say goodbye
    $self->_send_command($sock, 'logout');

    return $self->probe_ok(
        banner => $imap_banner
    );
}

sub _send_command {
    my ($self, $sock, $cmd, @args) = @_;
    my $imap_cmd = sprintf ". %s %s\r\n", $cmd, join(" ", @args);
    return $sock->send($imap_cmd);
}

sub _get_reply {
    my ($self, $sock) = @_;
    $sock->read(my $reply, 1024);
    $reply =~ s{^\s+}{};
    $reply =~ s{\s+$}{};
    return $reply;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Prober::imap

=head1 VERSION

version 0.16

=head1 AUTHOR

Cosimo Streppone <cosimo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Cosimo Streppone.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
