package Net::Statsd::Tiny;

# ABSTRACT: A tiny StatsD client that supports multimetric packets

use v5.12;

use warnings;

use parent qw/ Class::Accessor::Fast /;

use Carp ();
use IO::Socket::IP qw( SOCK_DGRAM );
use Socket 2.026 ();

our $VERSION = 'v0.4.1';


__PACKAGE__->mk_ro_accessors(
    qw/ host port proto prefix
      autoflush max_buffer_size socket /
);

sub new {
    my ( $class, @args ) = @_;

    my %args;
    if ( ( @args == 1 ) && ( ref( $args[0] ) eq 'HASH' ) ) {
        %args = %{ $args[0] };
    }
    else {
        %args = @args;
    }

    my %DEFAULTS = (
        host            => '127.0.0.1',
        port            => 8125,
        proto           => 'udp',
        prefix          => '',
        autoflush       => 1,
        max_buffer_size => 512,
    );

    foreach my $attr ( keys %DEFAULTS ) {
        next if exists $args{$attr};
        $args{$attr} = $DEFAULTS{$attr};
    }

    if ( my $socket = delete $args{socket} ) {
        $args{socket} = $socket;
    }
    else {
        $args{socket} = IO::Socket::IP->new(
            PeerHost    => $args{host},
            PeerService => $args{port},
            Proto       => $args{proto},
            Type        => SOCK_DGRAM,
        ) or die "Failed to initialize socket: $!";
    }

    my $self = $class->SUPER::new( \%args );

    $self->{_buffer} = '';

    return $self;
}


BEGIN {
    my $class = __PACKAGE__;

    my %PROTOCOL = (
        set_add   => 's',
        counter   => 'c',
        gauge     => 'g',
        histogram => 'h',
        meter     => 'm',
        timing    => 'ms',
    );

    foreach my $name ( keys %PROTOCOL ) {

        no strict 'refs';    ## no critic (ProhibitNoStrict)

        my $suffix = '|' . $PROTOCOL{$name};

        *{"${class}::${name}"} = sub {
            my ( $self, $metric, $value, $rate ) = @_;
            if ( ( defined $rate ) && ( $rate < 1 ) ) {
                $self->_record( $suffix . '|@' . $rate, $metric, $value )
                    if rand() < $rate;
            }
            else {
                $self->_record( $suffix, $metric, $value );
            }
        };

    }

    # Alises for other Net::Statsd::Client or Etsy::StatsD

    {
        no strict 'refs';    ## no critic (ProhibitNoStrict)

        *{"${class}::update"}    = \&counter;
        *{"${class}::timing_ms"} = \&timing;

    }

}

sub increment {
    my ( $self, $metric, $rate ) = @_;
    $self->counter( $metric, 1, $rate );
}

sub decrement {
    my ( $self, $metric, $rate ) = @_;
    $self->counter( $metric, -1, $rate );
}

sub _record {
    my ( $self, $suffix, $metric, $value ) = @_;

    Carp::croak "malformed metric" if $metric =~ /[\N{U+00}-\N{U+1f}:|]/;
    Carp::croak "malformed value"  if $value  =~ /[\N{U+00}-\N{U+1f}:|]/;

    my $data = $self->prefix . $metric . ':' . $value . $suffix . "\n";

    if ( $self->autoflush ) {
        $self->socket->send( $data, 0 );
        return;
    }

    my $avail = $self->max_buffer_size - length( $self->{_buffer} );
    $self->flush if length($data) > $avail;

    $self->{_buffer} .= $data;
}



sub flush {
    my ($self) = @_;

    if ( length($self->{_buffer}) ) {
        $self->socket->send( $self->{_buffer}, 0 );
        $self->{_buffer} = '';
    }
}

sub DEMOLISH {
    my ( $self, $is_global ) = @_;

    return if $is_global;

    $self->flush;
}


1;

__END__

=pod

=encoding UTF-8

=for stopwords UDP multimetric compatability StatsD statsd proto

=head1 NAME

Net::Statsd::Tiny - A tiny StatsD client that supports multimetric packets

=head1 VERSION

version v0.4.1

=head1 SYNOPSIS

    use Net::Statsd::Tiny;

    my $stats = Net::Statsd::Tiny->new(
      prefix          => 'myapp.',
      autoflush       => 0,
      max_buffer_size => 8192,
    );

    ...

    $stats->increment('this.counter');

    $stats->set_add( 'this.users', $username ) if $username;

    $stats->timing( $run_time * 1000 );

    $stats->flush;

=head1 DESCRIPTION

This is a small StatsD client that supports the
L<StatsD Metrics Export Specification v0.1|https://github.com/b/statsd_spec>.

It supports the following features:

=over

=item Multiple metrics can be sent in a single UDP packet.

=item It supports the meter and histogram metric types.

=back

Note that the specification requires the measured values to be
integers no larger than 64-bits, but ideally 53-bits.

The current implementation does not validate that the values you pass
to metrics conform to the spec, which allows you to take advantage of
extensions to some StatsD daemons. But the downside is that other
daemons may ignore those metrics.

For simplicity, it will allow you to specify a sampling rate for any
metric, not just the ones where it is documented below. But again,
some daemons may ignore or reject this.

=head1 ATTRIBUTES

=head2 host

The host of the statsd daemon. It defaults to C<127.0.0.1>.

=head2 port

The port that the statsd daemon is listening on. It defaults to
C<8125>.

=head2 proto

The network protocol that the statsd daemon is using. It defaults to
C<udp>.

=head2 socket

Alternatively, you can pass an L<IO::Socket> instead of the L</host>, L</port> and L</protocol>.

This will override other settings.

Added in v0.4.0.

=head2 prefix

The prefix to prepend to metric names. It defaults to a blank string.

=head2 autoflush

A flag indicating whether metrics will be send immediately. It
defaults to true.

When it is false, metrics will be saved in a buffer and only sent when
the buffer is full, or when the L</flush> method is called.

Note that when this is disabled, you will want to flush the buffer
regularly at the end of each task (e.g. a website request or job).

Not all StatsD daemons support receiving multiple metrics in a single
packet.

=head2 max_buffer_size

Specifies the maximum buffer size. It defaults to C<512>.

=head1 METHODS

=head2 counter

  $stats->counter( $metric, $value, $rate );

This adds the C<$value> to the counter specified by the C<$metric>
name.

If a C<$rate> is specified and less than 1, then a sampling rate will
be added. C<$rate> must be between 0 and 1.

=head2 update

This is an alias for L</counter>, for compatability with
L<Etsy::StatsD> or L<Net::Statsd::Client>.

=head2 increment

  $stats->increment( $metric, $rate );

This is an alias for

  $stats->counter( $metric, 1, $rate );

=head2 decrement

  $stats->decrement( $metric, $rate );

This is an alias for

  $stats->counter( $metric, -1, $rate );

=head2 metric

  $stats->metric( $metric, $value );

This is a counter that only accepts positive (increasing) values. It
is appropriate for counters that will never decrease (e.g. the number
of requests processed.)  However, this metric type is not supported by
many StatsD daemons.

=head2 gauge

  $stats->gauge( $metric, $value );

A gauge can be thought of as a counter that is maintained by the
client instead of the daemon, where C<$value> is a positive integer.

However, this also supports gauge increment extensions. If the number
is prefixed by a "+", then the gauge is incremented by that amount,
and if the number is prefixed by a "-", then the gauge is decremented
by that amount.

=head2 timing

  $stats->timing( $metric, $value, $rate );

This logs a "timing" in milliseconds, so that statistics about the
metric can be gathered. The C<$value> must be positive number,
although the specification recommends that integers be used.

In actually, any values can be logged, and this is often used as a
generic histogram for non-timing values (especially since many StatsD
daemons do not support the L</histogram> metric type).

If a C<$rate> is specified and less than 1, then a sampling rate will
be added. C<$rate> must be between 0 and 1.  Note that sampling
rates for timings may not be supported by all statsd servers.

=head2 timing_ms

This is an alias for L</timing>, for compatability with
L<Net::Statsd::Client>.

=head2 histogram

  $stats->histogram( $metric, $value );

This logs a value so that statistics about the metric can be
gathered. The C<$value> must be a positive number, although the
specification recommends that integers be used.

=head2 set_add

  $stats->set_add( $metric, $string );

This adds the the C<$string> to a set, for logging the number of
unique things, e.g. IP addresses or usernames.

=head2 flush

This sends the buffer to the L</host> and empties the buffer, if there
is any data in the buffer.

=head1 SECURITY CONSIDERATIONS

When using the L</set_add> method, be wary of exposing sensitive information like IP addresses, usernames, email addresses or even session ids over insecure channels.  One workaround is to log a message digest of the value instead, for example

    use Digest::SHA qw/ hmac_sha1 /;

    ...

    $stats->set_key( "myapp.sessions", hmac_sha1( $session->id, $my_secret_key );

Note that the keys should be consistent across worker processes and hosts.

When generating metric names based on untrusted sources (such as HTTP requests), ensure that the metrics contain only printable characters and do not contain colons (":") or pipes ("|"), since these are used by the statsd protocol.

=head1 SEE ALSO

L<Net::Statsd::Lite> which has a similar API but uses L<Moo> and
L<Type::Tiny> for data validation. It's also faster.

L<https://github.com/b/statsd_spec>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Net-Statsd-Tiny>
and may be cloned from L<https://github.com/robrwo/Net-Statsd-Tiny.git>

=head1 SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.12 or later.
Future releases may only support Perl versions released in the last ten (10) years.

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Net-Statsd-Tiny/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head2 Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see F<SECURITY.md> for instructions how to
report security vulnerabilities

=head1 AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=head1 CONTRIBUTOR

=for stopwords Michael R. Davis

Michael R. Davis <mrdvt@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
