#!/usr/bin/perl -w
package Net::Tshark;
use strict;
use warnings;

our $VERSION = '0.04';

use IPC::Run;
use File::Which qw(which);
use Net::Tshark::Packet;

# These thresholds are used to prevent the possibility
# of an infinite loop while waiting for packet data.
use constant MAX_POLLING_ITERATIONS       => 100;
use constant MAX_PACKETS_RETURNED_AT_ONCE => 10_000;

sub new
{
    my ($class) = @_;

    # Try to find tshark
    my $tshark_path = which('tshark');
    if (!defined $tshark_path)
    {
        if ($^O eq 'MSWin32' && -x "C:\\Program Files\\Wireshark\\tshark.exe")
        {
            $tshark_path = "C:\\Program Files\\Wireshark\\tshark.exe";
        }
        else
        {
            warn 'Could not find TShark installed. Is it in your PATH?';
            return;
        }
    }

    my $self = {
        in          => q(),
        out         => q(),
        err         => q(),
        tshark_path => $tshark_path,
    };

    return bless $self, $class;
}

sub DESTROY
{
    my ($self) = @_;
    return $self->stop;
}

sub start
{
    my ($self, %args) = @_;
    my ($interface, $capture_filter, $display_filter, $duration, $promiscuous)
      = @args{qw(interface capture_filter display_filter duration promiscuous)};

    # Construct the command to execute tshark
    my @command = ($self->{tshark_path});
    push @command, '-a duration:', int($duration)  if ($duration);
    push @command, '-f',           $capture_filter if ($capture_filter);
    push @command, '-i',           $interface      if (defined $interface);
    push @command, '-l';    # Flush the standard output after each packet
    push @command, '-p' if (defined $promiscuous && !$promiscuous);
    push @command, '-R', $display_filter if ($display_filter);
    push @command, '-T', 'pdml';    # Output XML

    # Start a tshark process and pipe its input, output, and error streams
    # so that we can read and write to it while it runs
    $self->{tshark} = IPC::Run::start \@command, \$self->{in}, \$self->{out},
      \$self->{err};

    return 1;
}

sub is_running
{
    my ($self) = @_;
    return defined $self->{tshark};
}

sub stop
{
    my ($self) = @_;

    if (defined $self->{tshark})
    {

        # Send Ctrl-C to gracefully end the process
        $self->{tshark}->signal('INT');

        # Get all of its stdout
        $self->__get_all_output;

        # Make sure the process has terminated
        $self->{tshark}->kill_kill;
        $self->{tshark}->finish;
        undef $self->{tshark};
    }

    return;
}

sub get_packet
{
    my ($self) = @_;

    # Get the decoded string for one packet.
    my $pkt_string = $self->__get_decoded_packet
      or return;

    # Create a packet object from the string and return it.
    return Net::Tshark::Packet->new($pkt_string);
}

sub get_packets
{
    my ($self) = @_;

    my @packets;
    for (1 .. MAX_PACKETS_RETURNED_AT_ONCE)
    {
        my $packet = $self->get_packet;
        last if !defined $packet;

        push @packets, $packet;
    }

    return @packets;
}

sub __get_decoded_packet
{
    my ($self) = @_;

    for (1 .. MAX_POLLING_ITERATIONS)
    {
        # Wait for us to see an entire packet
        if (my ($packet) = $self->{out} =~ /(<packet>.*?<\/packet>)/s)
        {

            # Remove the packet from the buffer and process it
            $self->{out} =~ s/\Q$packet\E//;

            return $packet;
        }

        # Get the latest output from the tshark process
        # and quit if there is no more output to get
        last if !$self->__get_more_output;
    }

    return;
}

sub __get_more_output
{
    my ($self) = @_;
    return if !defined $self->{tshark};

    my $buf_len = length $self->{out};
    $self->{tshark}->pump_nb;
    return length $self->{out} > $buf_len;
}

sub __get_all_output
{
    my ($self) = @_;

    for (1 .. MAX_POLLING_ITERATIONS)
    {
        last if !$self->__get_more_output;
    }

    return;
}

1;

__END__

=head1 NAME

Net::Tshark - Interface for the tshark network capture utility

=head1 SYNOPSIS

  use Net::Tshark;

  # Start the capture process, looking for packets containing HTTP requests and responses
  my $tshark = Net::Tshark->new;
  $tshark->start(interface => 2, display_filter => 'http');

  # Do some stuff that would trigger HTTP requests/responses for 30 s
  sleep 30;

  # Get any packets captured
  $tshark->stop;
  my @packets = $tshark->get_packets;
  
  # Extract packet information by accessing each packet like a nested hash
  my $src_ip = $packets[0]->{ip}->{src};
  my $dst_ip = $packets[0]->{ip}->{dst};

=head1 DESCRIPTION

A module that uses the command-line tshark utility to capture packets,
parse the output, and format the results as perl hash-like structures.

=head2 CONSTRUCTOR

=over 4

=item $tshark = Net::Tshark->new()

Returns a newly created C<Net::Tshark> object.

=back

=head2 METHODS

=over 4

=item $tshark->start(%options)

  Parameters:
  interface      - network interface to use (1, 2, etc)
  capture_filter - capture filter, as used by tshark
  display_filter - display filter, as used by tshark
  duration       - maximum number of seconds to capture packets for
  promiscuous    - set to 0 to disable promiscuous mode (necessary for some WiFi adapters)

=item $tshark->stop

Terminates the tshark process, stopping any further packet capture. You may still execute C<get_packets> after the tshark process has terminated.

=item $tshark->is_running

Returns a true value if the tshark process is running, or a false value if
the tshark process is not running.

=item $tshark->get_packet

Retrieves the next available captured packet, or returns undef if no packets are
available. Packets are C<Net::Tshark::Packet> objects, which implement much of the same interface as native hashes. Therefore, you can dereference C<Net::Tshark::Packet> objects much as you would nested hashes. In fact, you can even cast a C<Net::Tshark::Packet> object to a real hash:

  # Get a packet and access its fields directly
  my $packet = $tshark->get_packet;
  print "The dst IP is $packet->{ip}->{dst}\n";

  # Deep-copy the packet object and store its fields in a native hash
  my %packet_hash = %{$packet->hash};
  print "The src IP is $packet_hash{ip}->{src}\n";

=item $tshark->get_packets

Retrieves all available captured packets, or returns an empty list if no packets
are available.

  # Get a list of the source ips of all captured IP packets
  my @packets = $tshark->get_packets;
  my @src_ips = map { $_->{ip}->{src} } grep { defined $_->{ip} } @packets;
 
=back

=head1 SEE ALSO

Net::Pcap - Interface to pcap(3) LBL packet capture library

Net::Sharktools - Use Wireshark's packet inspection capabilities in Perl

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Zachary Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

