package Net::Prober::ssh;
$Net::Prober::ssh::VERSION = '0.16';
use strict;
use warnings;
use base 'Net::Prober::Probe::TCP';

use Carp ();

sub defaults {
    my ($self) = @_;

    my $defaults = $self->SUPER::defaults();
    $defaults->{port} = 22;

    return $defaults;
}

sub probe {
    my ($self, $args) = @_;

    my ($host, $port, $timeout, $username, $password) =
        $self->parse_args($args, qw(host port timeout username password));

    my $t0 = $self->time_now();

    my $sock = $self->open_socket($args);
    if (! $sock) {
        return $self->probe_failed(
            reason => qq{Couldn't connect to SSH server $host:$port},
        );
    }

    chomp (my $ssh_banner = $self->_get_reply($sock));

    if (! $ssh_banner) {
        return $self->probe_failed(
            reason => qq{Couldn't get SSH banner from $host:$port}
        );
    }

    # SSH-protoversion-softwareversion SP comments CR LF
    if ($ssh_banner !~ qr{^SSH-
        (?<protoversion>    [^\-]+) -
        (?<softwareversion> [^\s]+) \s?
        (?<comments>        .*)? $}x) {
        return $self->probe_failed(
            reason => qq{Non-RFC compliant SSH banner from $host:$port? ($ssh_banner)},
        );
    }

    my %ssh_info = (
        protoversion => $+{protoversion},
        softwareversion => $+{softwareversion},
        comments => $+{comments},
        banner => $ssh_banner,
    );

    # We can't try to login if we haven't got credentials
    if ($username && $password) {
        $self->_send_command($sock, $username . "\n" . $password . "\n");
        if (! $self->_get_reply($sock)) {
            return $self->probe_failed(
                reason => qq{Couldn't login to ssh $host:$port with user $username},
            );
        }
    }

    # Say goodbye
    $self->_send_command($sock, 'exit');

    return $self->probe_ok(%ssh_info);
}

sub _send_command {
    my ($self, $sock, $text_input) = @_;
    return $sock->send($text_input);
}

sub _get_reply {
    my ($self, $sock) = @_;
    $sock->recv(my $reply, 1024);
    $reply =~ s{\s+$}{};
    return $reply;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Prober::ssh

=head1 VERSION

version 0.16

=head1 AUTHOR

Cosimo Streppone <cosimo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Cosimo Streppone.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
