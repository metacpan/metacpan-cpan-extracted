package Net::Prober::tcp;
$Net::Prober::tcp::VERSION = '0.16';
use strict;
use warnings;
use base 'Net::Prober::Probe::TCP';

use Carp ();
use Net::Prober ();

sub probe {
    my ($self, $args) = @_;

    my ($host, $port, $timeout, $proto) =
        $self->parse_args($args, qw(host port timeout proto));

    $port = Net::Prober::port_name_to_num($port);

    if (! defined $port or $port == 0) {
        Carp::croak("Can't probe: undefined port");
    }

    $timeout ||= 3.5;

    my $t0 = $self->time_now();

    my $sock = $self->open_socket($args);
    my $good = 0;
    my $reason;

    if (! $sock) {
        $reason = "Socket open failed";
    }
    else {
        $good = $sock->connected() && $sock->close();
        if (! $good) {
            $reason = "Socket connect or close failed";
        }
    }

    my $elapsed = $self->time_elapsed();

    if ($good) {
        return $self->probe_ok(
            time => $elapsed,
            host => $host,
            port => $port,
        );
    }

    return $self->probe_failed(
        time => $elapsed,
        host => $host,
        port => $port,
        reason => $reason,
    );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Prober::tcp

=head1 VERSION

version 0.16

=head1 AUTHOR

Cosimo Streppone <cosimo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Cosimo Streppone.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
