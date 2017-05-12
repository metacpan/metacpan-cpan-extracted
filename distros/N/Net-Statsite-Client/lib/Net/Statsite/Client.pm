package Net::Statsite::Client;
use 5.008001;
use strict;
use warnings;

our $VERSION = '1.1.0';

use IO::Socket;
use Carp;

=head1 NAME

Net::Statsite::Client - Object-Oriented Client for L<statsite|http://armon.github.io/statsite> server

=head1 SYNOPSIS

    use Net::Statsite::Client;
    my $statsite = Net::Statsite::Client->new(
        host   => 'localhost',
        prefix => 'test',
    );

    $statsite->increment('item'); #increment key test.item

=head1 DESCRIPTION

Net::Statsite::Client is based on L<Etsy::StatsD> but with new - C<new> interface and C<unique> method.


=head1 METHODS

=head2 new (host => $host, port => $port, sample_rate => $sample_rate, prefix => $prefix)

Create a new instance.

I<host> - hostname of statsite server (default: localhost)

I<port> - port of statsite server (port: 8125)

I<sample_rate> - rate of sends metrics (default: 1)

I<prefix> - prefix metric name (default: '')

I<proto> - protocol (default: 'udp')

=cut

sub new {
    my ($class, %options) = @_;
    $options{host}   = 'localhost' unless defined $options{host};
    $options{port}   = 8125        unless defined $options{port};
    $options{prefix} = ''          unless defined $options{prefix};
    $options{proto}  = 'udp'       unless defined $options{proto};

    die "Invalid protocol '$options{proto}' (tcp|udp)" if $options{proto} !~ /^(?:tcp|udp)$/;

    my $sock = IO::Socket::INET->new(
        PeerAddr => $options{host},
        PeerPort => $options{port},
        Proto    => $options{proto},
    ) or croak "Failed to initialize socket: $!";

    bless { socket => $sock, sample_rate => $options{sample_rate}, prefix => $options{prefix} }, $class;
}

=head2 timing(STAT, TIME, SAMPLE_RATE)

Log timing information (should be in miliseconds)

=cut

sub timing {
    my ($self, $stat, $time, $sample_rate) = @_;
    $self->send({ $stat => "$time|ms" }, $sample_rate);
}

=head2 increment(STATS, SAMPLE_RATE)

Increment one of more stats counters.

=cut

sub increment {
    my ($self, $stats, $sample_rate) = @_;
    $self->update($stats, 1, $sample_rate);
}

=head2 decrement(STATS, SAMPLE_RATE)

Decrement one of more stats counters.

=cut

sub decrement {
    my ($self, $stats, $sample_rate) = @_;
    $self->update($stats, -1, $sample_rate);
}

=head2 update(STATS, DELTA, SAMPLE_RATE)

Update one of more stats counters by arbitrary amounts.

=cut

sub update {
    my ($self, $stats, $delta, $sample_rate) = @_;
    $delta = 1 unless defined $delta;
    my %data;
    if (ref($stats) eq 'ARRAY') {
        %data = map { $_ => "$delta|c" } @$stats;
    }
    else {
        %data = ($stats => "$delta|c");
    }
    $self->send(\%data, $sample_rate);
}

=head2 unique(STATS, ITEM, SAMPLE_RATE)

Unique Set

For example if you need count of unique ip adresses (per flush interval)
    $stats->unique('ip.unique', $ip);

=cut

sub unique {
    my ($self, $stats, $item, $sample_rate) = @_;
    my %data = ($stats => "$item|s");
    $self->send(\%data, $sample_rate);
}

=head2 gauge(STATS, VALUE, SAMPLE_RATE)

Gauge Set (Gauge, similar to  kv  but only the last value per key is retained)

=cut

sub gauge {
    my ($self, $stats, $value, $sample_rate) = @_;
    my %data = ($stats => "$value|g");
    $self->send(\%data, $sample_rate);
}

=head2 send(DATA, SAMPLE_RATE)

Sending logging data; implicitly called by most of the other methods.

=cut

sub send {
    my ($self, $data, $sample_rate) = @_;
    $sample_rate = $self->{sample_rate} unless defined $sample_rate;

    my $sampled_data;
    if (defined($sample_rate) and $sample_rate < 1) {
        while (my ($stat, $value) = each %$data) {
            $sampled_data->{$stat} = "$value|\@$sample_rate" if rand() <= $sample_rate;
        }
    }
    else {
        $sampled_data = $data;
    }

    return '0 but true' unless keys %$sampled_data;

    #failures in any of this can be silently ignored
    my $count  = 0;
    my $socket = $self->{socket};
    while (my ($stat, $value) = each %$sampled_data) {

        my $key = $stat;
        if ($$self{prefix}) {
            $key = "$$self{ prefix }.$stat";
        }

        #sanitize key (remove statsite separators)
        #https://github.com/armon/statsite#protocol
        $key =~ s/[:|\/]/_/g;

        _send_to_sock($socket, "$key:$value\n");
        ++$count;
    }
    return $count;
}

sub _send_to_sock( $$ ) {
    my ($sock, $msg) = @_;
    CORE::send($sock, $msg, 0);
}

=head1 CONTRIBUTING

the easiest way is use docker (L<avastsoftware/perl-extended|https://hub.docker.com/r/avastsoftware/perl-extended/> - with L<Carton> and L<Minilla>)

or L<Carton> and C<Minilla> itself (commands after C<../perl-extended>) 

carton (aka ruby bundle) for fetch dependency

    docker run -v $PWD:/tmp/app -w /tmp/app avastsoftware/perl-extended carton

and minil test for tests and regenerate meta and readme

    docker run -v $PWD:/tmp/app -w /tmp/app avastsoftware/perl-extended carton exec minil test


=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
