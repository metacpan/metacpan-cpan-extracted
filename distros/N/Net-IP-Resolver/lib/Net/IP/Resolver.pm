package Net::IP::Resolver;

=pod

=head1 NAME

Net::IP::Resolver - Resolve IPs to a particular network

=head1 SYNOPSIS

  # Create the resolver and add some networks
  my $resolver = Net::IP::Resolve->new;
  $resolver->add( 'Comcast' => '123.0.0.0/8', '124.128.0.0/10' );
  $resolver->add( 'Foobar'  => [ '1.2.3.0/24', '1.2.4.0/24' ] );
  
  # Check an IP
  my $ip = '123.123.123.123';
  my $network = $resolver->find_first( $ip );
  print "IP $ip is in network $network";
  
  # prints... "IP 123.123.123.123 is in network Comcast";

=head1 DESCRIPTION

C<Net::IP::Resolver> provides a mechanism for registering a number of
different networks (specified by a set of ip ranges), and then finding
the network for a given IP based on this specification.

The identifier for a network can be any defined value that you wish.

Thus you can resolve to numeric identifiers, names, or even to objects
representing the networks.

=head1 METHODS

=cut

use strict;
use Net::IP::Match::XS ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

The C<new> constructor takes no arguments, and create a new and empty
resolver.

Returns a new C<Net::IP::Resolver> object.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	my $self = bless {
		networks => [],
		results  => [],
		}, $class;

	$self;
}





#####################################################################
# Net::IP::Resolver Interface

=pod

=head2 add $network, $range, ...

The C<add> method adds a network to the resolver. It takes as argument
an identifier for the network, which can be C<any> defined value, including
an object of any type, followed by a set of 1 or more IP ranges, in the
format used by L<Net::IP::Match::XS> (which this class uses for the actual
ip matching).

Returns true if the network was added, or C<undef> if passed incorrect
arguments.

=cut

sub add {
	my $self    = shift;
	my $result  = defined $_[0] ? shift : return undef;
	my $network = @_ ? [ @_ ] : return undef;

	# Add the result and ranges
	push @{$self->{networks}}, $network;
	push @{$self->{results}},  $result;

	1;
}

=pod

=head2 find_first $ip

The C<find_first> method takes an IP address as argument, and checks
it against each network to find the first one that matches.

The assumption made by C<find_first> is that each network in the resolver
occupies a unique and non-overlapping set of ranges, and thus only any ip
can only ever resolve to one network

Returns the network identifier as originally provided, or C<undef> if the
ip is not provided, or the resolver cannot match it to any network.

=cut

sub find_first {
	my $self = shift;
	my $ip   = defined $_[0] ? shift : return undef;

	foreach my $i ( 0 .. $#{ $self->{networks} } ) {
		my $network = $self->{networks}->[$i];
		if ( Net::IP::Match::XS::match_ip( $ip, @$network ) ) {
			return $self->{results}->[$i];
		}
	}

	return undef;
}

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-IP-Resolver>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Net::IP>, L<Net::IP::Match::XS>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005 - 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
