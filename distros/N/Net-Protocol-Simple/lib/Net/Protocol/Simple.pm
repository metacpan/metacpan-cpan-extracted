package Net::Protocol::Simple;

use 5.008006;
use strict;
use warnings;

our $VERSION = '1.00';

my $PROTOCOLS = {
	ICMP => 1,
	TCP => 6,
	UDP => 17,
};

# CONSTRUCTOR

sub new {
	my ($class, %data) = @_;
	my $self = {};
	bless($self,$class);
	$self->init(%data);
	return $self;
}

sub init {
	my ($self,%data) = @_;
	$self->protocol($data{protocol});
	$self->layer(	$data{layer});
}

# METHODS

sub int {
	my $self = shift;
	return $PROTOCOLS->{$self->protocol()} if(exists($PROTOCOLS->{$self->protocol()}));
}
# ACCESSORS/MODIFIERS

sub protocol {
	my ($self,$v) = @_;
	$self->{_protocol} = normalize($v) if(defined($v));
	return $self->{_protocol};
}

sub layer {
	my ($self,$v) = @_;
	$self->{_layer} = $v if(defined($v));
	return $self->{_layer};
}

# FUNCTIONS

sub normalize {
	my $proto = uc(shift);
	if($proto =~ /^\d+$/){
		foreach my $x (keys %$PROTOCOLS){
			return $x if($proto eq $PROTOCOLS->{$x});
		}
	}
	return $proto;
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::Protocol::Simple - Perl extension for handling simple generic protocol layers within applications

=head1 SYNOPSIS

  use Net::Protocol::Simple;
  my $p = Net::Protocol::Simple->new(protocol => 6, layer => 4);

  $p->protocol(); Gives us 'TCP'
  $p->int(); Gives us 6;

  my $p = Net::Protocol::Simple->new(protocol = 'udp', layer => 4);
  $p->protocol(); Gives us 'UDP';
  $p->int(); Gives us 17;

=head1 DESCRIPTION

This module is intended to be used in conjunction with Net::Connection::Simple. Some applications such as snort and other IDS's log their alert data as simple connections. This module will allow you to read in their protocol data as an int or a string. The backend stores it as a string (TCP,UDP,ICMP). Natively it will handle these three protocols, but it will scale to any other layer and protocol as a simple handler. Using Net::Connection::Simple, you can use these to populate the multiple layers of the connection.

=head1 SEE ALSO

Net::Packet,Net::Connection,Snort::Rule

=head1 AUTHOR

Wes Young, E<lt>saxguard9-cpan@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Wes Young

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut