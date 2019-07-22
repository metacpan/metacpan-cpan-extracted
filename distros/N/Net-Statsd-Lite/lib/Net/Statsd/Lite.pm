package Net::Statsd::Lite;

# ABSTRACT: A lightweight StatsD client that supports multimetric packets

use v5.10;

use Moo 1.000000;

use Devel::StrictMode;
use IO::Socket 1.18 ();
use MooX::TypeTiny;
use Scalar::Util qw/ refaddr /;
use Sub::Quote qw/ quote_sub /;
use Sub::Util 1.40 qw/ set_subname /;
use Net::Statsd::Lite::Types -types;

use namespace::autoclean;

our $VERSION = 'v0.4.8';


has host => (
    is      => 'ro',
    isa     => Str,
    default => '127.0.0.1',
);


has port => (
    is      => 'ro',
    isa     => Port,
    default => 8125,
);


has proto => (
    is      => 'ro',
    isa     => Enum [qw/ tcp udp /],
    default => 'udp',
);


has prefix => (
    is      => 'ro',
    isa     => Str,
    default => '',
);


has autoflush => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

my %Buffers;


has max_buffer_size => (
    is      => 'ro',
    isa     => PosInt,
    default => 512,
);

has _socket => (
    is      => 'lazy',
    isa     => InstanceOf ['IO::Socket::INET'],
    builder => sub {
        my ($self) = shift;
        my $sock = IO::Socket::INET->new(
            PeerAddr => $self->host,
            PeerPort => $self->port,
            Proto    => $self->proto,
        ) or die "Failed to initialize socket: $!";
        return $sock;
    },
    handles => { _send => 'send' },
);


BEGIN {
    my $class = __PACKAGE__;

    my %PROTOCOL = (
        set_add   => [ '|s',  Str, ],
        counter   => [ '|c',  Int, 1 ],
        gauge     => [ '|g',  Gauge | PosInt ],
        histogram => [ '|h',  PosNum ],
        meter     => [ '|m',  PosInt ],
        timing    => [ '|ms', PosNum, 1 ],
    );

    foreach my $name ( keys %PROTOCOL ) {

        my $type = $PROTOCOL{$name}[1];
        my $rate = $PROTOCOL{$name}[2];

        my $code =
          defined $rate
          ? q{ my ($self, $metric, $value, $rate) = @_; }
          : q{ my ($self, $metric, $value) = @_; };

        if (STRICT) {

            $code .= $type->inline_assert('$value');

            $code .=
              q/ if (defined $rate) { / . Rate->inline_assert('$rate') . ' }'
              if defined $rate;
        }

        my $tmpl = $PROTOCOL{$name}[0];

        if ( defined $rate ) {

            $code .= q/ if ((defined $rate) && ($rate<1)) {
                     $self->_record( $tmpl . '|@' . $rate, $metric, $value )
                        if rand() <= $rate;
                   } else {
                     $self->_record( $tmpl, $metric, $value ); } /;
        }
        else {

            $code .= q{$self->_record( $tmpl, $metric, $value );};

        }

        quote_sub "${class}::${name}", $code,
          { '$tmpl'  => \$tmpl },
          { no_defer => 1 };

    }

    # Alises for other Net::Statsd::Client or Etsy::StatsD

    {
        no strict 'refs';    ## no critic (ProhibitNoStrict)

        *{"${class}::update"}    = set_subname "update"    => \&counter;
        *{"${class}::timing_ms"} = set_subname "timing_ms" => \&timing;

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

    my $data = $self->prefix . $metric . ':' . $value . $suffix . "\n";

    if ( $self->autoflush ) {
        send( $self->_socket, $data, 0 );
        return;
    }

    my $index = refaddr $self;
    my $avail = $self->max_buffer_size - length( $Buffers{$index} );

    $self->flush if length($data) > $avail;

    $Buffers{$index} .= $data;

}


sub flush {
    my ($self) = @_;

    my $index = refaddr $self;
    if ( $Buffers{$index} ne '' ) {
        send( $self->_socket, $Buffers{$index}, 0 );
        $Buffers{$index} = '';
    }
}

sub BUILD {
    my ($self) = @_;

    $Buffers{ refaddr $self } = '';
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

=head1 NAME

Net::Statsd::Lite - A lightweight StatsD client that supports multimetric packets

=head1 VERSION

version v0.4.8

=head1 SYNOPSIS

    use Net::Statsd::Lite;

    my $stats = Net::Statsd::Lite->new(
      prefix          => 'myapp.',
      autoflush       => 0,
      max_buffer_size => 8192,
    );

    ...

    $stats->increment('this.counter');

    $stats->set_add( $username ) if $username;

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

The current implementation expects values to be integers, except where
specified. But it otherwise does not enforce maximum/minimum values.

=head1 ATTRIBUTES

=head2 C<host>

The host of the statsd daemon. It defaults to C<127.0.0.1>.

=head2 C<port>

The port that the statsd daemon is listening on. It defaults to
C<8125>.

=head2 C<proto>

The network protocol that the statsd daemon is using. It defaults to
C<udp>.

=head2 C<prefix>

The prefix to prepend to metric names. It defaults to a blank string.

=head2 C<autoflush>

A flag indicating whether metrics will be send immediately. It
defaults to true.

When it is false, metrics will be saved in a buffer and only sent when
the buffer is full, or when the L</flush> method is called.

Note that when this is disabled, you will want to flush the buffer
regularly at the end of each task (e.g. a website request or job).

Not all StatsD daemons support receiving multiple metrics in a single
packet.

=head2 C<max_buffer_size>

The specifies the maximum buffer size. It defaults to C<512>.

=head1 METHODS

=head2 C<counter>

  $stats->counter( $metric, $value, $rate );

This adds the C<$value> to the counter specified by the C<$metric>
name.

If a C<$rate> is specified and less than 1, then a sampling rate will
be added. C<$rate> must be between 0 and 1.

=head2 C<update>

This is an alias for L</counter>, for compatability with
L<Etsy::StatsD> or L<Net::Statsd::Client>.

=head2 C<increment>

  $stats->increment( $metric, $rate );

This is an alias for

  $stats->counter( $metric, 1, $rate );

=head2 C<decrement>

  $stats->decrement( $metric, $rate );

This is an alias for

  $stats->counter( $metric, -1, $rate );

=head2 C<metric>

  $stats->metric( $metric, $value );

This is a counter that only accepts positive (increasing) values. It
is appropriate for counters that will never decrease (e.g. the number
of requests processed.)  However, this metric type is not supported by
many StatsD daemons.

=head2 C<gauge>

  $stats->gauge( $metric, $value );

A gauge can be thought of as a counter that is maintained by the
client instead of the daemon, where C<$value> is a positive integer.

However, this also supports gauge increment extensions. If the number
is prefixed by a "+", then the gauge is incremented by that amount,
and if the number is prefixed by a "-", then the gauge is decremented
by that amount.

=head2 C<timing>

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

=head2 C<timing_ms>

This is an alias for L</timing>, for compatability with
L<Net::Statsd::Client>.

=head2 C<histogram>

  $stats->histogram( $metric, $value );

This logs a value so that statistics about the metric can be
gathered. The C<$value> must be a positive number, although the
specification recommends that integers be used.

This metric type is not supported by many StatsD daemons. You can use
L</timing> for the same effect.

=head2 C<set_add>

  $stats->set_add( $metric, $string );

This adds the the C<$string> to a set, for logging the number of
unique things, e.g. IP addresses or usernames.

=head2 C<flush>

This sends the buffer to the L</host> and empties the buffer, if there
is any data in the buffer.

=head1 STRICT MODE

If this module is first loaded in C<STRICT> mode, then the values and
rate arguments will be checked that they are the correct type.

See L<Devel::StrictMode> for more information.

=head1 SEE ALSO

This module was forked from L<Net::Statsd::Tiny>.

L<https://github.com/b/statsd_spec>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Net-Statsd-Lite>
and may be cloned from L<git://github.com/robrwo/Net-Statsd-Lite.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Net-Statsd-Lite/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=head1 CONTRIBUTOR

=for stopwords Toby Inkster

Toby Inkster <tobyink@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
