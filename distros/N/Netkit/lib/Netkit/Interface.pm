package Interface;

use strict;
use warnings;

=head1 DESCRIPTION

Simple module which is basically a struct.

Stores eth number, ip address (optional) and mac address (optional).

=over 4

=item new()

Creates a new Attachment.

Usage:

 my $interface = Interface->new (
	   eth => 0,
	   ip => '10.0.0.2'
 );

=cut

sub new {
	my $class = shift;
	
	my %params = @_;

	my $self = bless {
		eth => $params{eth},
		ip => $params{ip},
		mac => $params{mac},
	}, $class;

	return $self;
}

=item dump()

Prints the Interface to selected file.

=back
=cut
sub dump {
	my $class = shift;
	
	print "ip link set dev eth$class->{eth} address $class->{mac}\n" if(defined $class->{mac});
	
	print "ip addr add $class->{ip} dev eth$class->{eth}\n" if(defined $class->{ip});
	
	print "ip link set eth$class->{eth} up\n";
	
	print "\n\n";
}

1;
