package POE::Filter::TacacsPlus;

=head1 NAME

POE::Filter::TacacsPlus - TacacsPlus packet filter

=cut

use strict;
use warnings;

our $VERSION = '1.11';


use Net::TacacsPlus::Packet 1.05;


=head1 METHODS

=head2 new()

Construct a filter object.

=cut

sub new {
	my $class = shift;
	my %args  = @_; 
	
	my $self = {
		'key' => $args{'key'}
	};
	
	bless $self, $class;
	
	return $self;
}


=head2 get(@raw_packets)

Transforms raw packets to the Net::TacacsPlus::Packet object.

=cut

sub get {
	my $self = shift;
	my $raw_packets = shift; 
	
	my @tacacs_packets;
	foreach my $raw (@{$raw_packets}) {
		push(@tacacs_packets, Net::TacacsPlus::Packet->new(
			'raw' => $raw,
			'key' => $self->{'key'},
		));
	}
	
	return \@tacacs_packets;
}


=head2 put(@packet_objects)

Transforms Net::TacacsPlus::Packet to the binary packet form.

=cut

sub put {
	my $self    = shift;
	my $packets = shift;
	
	my @tacacs_raw_packets;
	foreach my $packet (@{$packets}) {
		push(@tacacs_raw_packets, $packet->raw);
	}
	
	return \@tacacs_raw_packets;
}

1;
