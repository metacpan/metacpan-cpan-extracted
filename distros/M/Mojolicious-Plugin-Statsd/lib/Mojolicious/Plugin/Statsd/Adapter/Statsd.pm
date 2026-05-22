package Mojolicious::Plugin::Statsd::Adapter::Statsd;

use Mojo::Base -base;

use Mojo::Loader qw(load_class);

our $VERSION = '0.06';

use IO::Socket::INET ();

has client =>  sub {
    my $self = shift;
    my ($host, $port) = split ':', $self->addr;
    load_class "Net::Statsd::Tiny";
    return Net::Statsd::Tiny->new(
        socket => $self->socket,
    );
};

has socket => sub {
    my $self = shift;
    IO::Socket::INET->new(
        Proto    => 'udp',
        PeerAddr => $self->addr,
        Blocking => 0,
    ) or die "Can't open write socket for stats: $@";
};

has addr => sub {
  $ENV{STATSD_ADDR} // '127.0.0.1:8125';
};

sub counter {
    my ( $self, $names, $value, $rate ) = @_;
    $self->client->counter($_, $value, $rate // 1) for @$names;
    return -1;
}

sub timing {
    my ( $self, $names, $value, $rate ) = @_;
    $self->client->timing($_, $value, $rate // 1) for @$names;
    return -1;
}

sub gauge {
    my ( $self, $names, $value ) = @_;
    $self->client->gauge($_, $value) for @$names;
    return -1;
}

sub set_add {
    my ( $self, $names, @values ) = @_;
    for my $value (@values) {
        $self->client->set_add($_, $value) for @$names;
    }
    return -1;
}

1;

# ABSTRACT: Statsd UDP recording

__END__

=pod

=encoding UTF-8

=for stopwords UDP statsd addr

=head1 NAME

Mojolicious::Plugin::Statsd::Adapter::Statsd - Statsd UDP recording

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This adapter for L<Mojolicious::Plugin::Statsd> sends stats immediately over
UDP to a statsd service.

=head1 OPTIONS

=head2 client

This is the underlying statsd client. It defaults to an instance of
L<Net::Statsd::Tiny> but any class with compatible methods can be
used.

=head2 addr

The statsd service address.  Defaults to the value of C<$ENV{STATSD_ADDR}>, or
C<localhost:8125>.

=head2 socket

An L<IO::Socket::INET>.  Opened connecting to L</addr> when necessary.

=head1 METHODS

=head2 timing

See L<Mojolicious::Plugin::Statsd/timing>.

=head2 counter

See L<Mojolicious::Plugin::Statsd/counter>.

=head2 gauge

See L<Mojolicious::Plugin::Statsd/gauge>.

=head2 set_add

See L<Mojolicious::Plugin::Statsd/set_add>.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Mojolicious-Plugin-Statsd>
and may be cloned from L<https://github.com/robrwo/perl-Mojolicious-Plugin-Statsd.git>

=head1 SUPPORT

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Mojolicious-Plugin-Statsd/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Meredith Howard  <mhoward@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2026 by Meredith Howard  <mhoward@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
