package POE::Component::Client::Whois::IPBlks;
$POE::Component::Client::Whois::IPBlks::VERSION = '1.38';
#ABSTRACT: Determine which whois server is responsible for a network address.

use strict;
use warnings;
use Net::Netmask;

sub new {
  my $self = bless { }, shift;
  $self->{data} = {
  '1.0.0.0/8' => 'whois.apnic.net',
  '2.0.0.0/8' => 'whois.ripe.net',
  '3.0.0.0/8' => 'whois.arin.net',
  '4.0.0.0/8' => 'whois.arin.net',
  '5.0.0.0/8' => 'whois.ripe.net',
  '7.0.0.0/8' => 'whois.arin.net',
  '8.0.0.0/8' => 'whois.arin.net',
  '9.0.0.0/8' => 'whois.arin.net',
  '12.0.0.0/8' => 'whois.arin.net',
  '13.0.0.0/8' => 'whois.arin.net',
  '14.0.0.0/8' => 'whois.apnic.net',
  '15.0.0.0/8' => 'whois.arin.net',
  '16.0.0.0/8' => 'whois.arin.net',
  '17.0.0.0/8' => 'whois.arin.net',
  '18.0.0.0/8' => 'whois.arin.net',
  '19.0.0.0/8' => 'whois.arin.net',
  '20.0.0.0/8' => 'whois.arin.net',
  '23.0.0.0/8' => 'whois.arin.net',
  '24.0.0.0/8' => 'whois.arin.net',
  '25.0.0.0/8' => 'whois.ripe.net',
  '27.0.0.0/8' => 'whois.apnic.net',
  '31.0.0.0/8' => 'whois.ripe.net',
  '32.0.0.0/8' => 'whois.arin.net',
  '34.0.0.0/8' => 'whois.arin.net',
  '35.0.0.0/8' => 'whois.arin.net',
  '36.0.0.0/8' => 'whois.apnic.net',
  '37.0.0.0/8' => 'whois.ripe.net',
  '38.0.0.0/8' => 'whois.arin.net',
  '39.0.0.0/8' => 'whois.apnic.net',
  '40.0.0.0/8' => 'whois.arin.net',
  '41.0.0.0/8' => 'whois.afrinic.net',
  '42.0.0.0/8' => 'whois.apnic.net',
  '43.0.0.0/8' => 'whois.apnic.net',
  '44.0.0.0/8' => 'whois.arin.net',
  '45.0.0.0/8' => 'whois.arin.net',
  '46.0.0.0/8' => 'whois.ripe.net',
  '47.0.0.0/8' => 'whois.arin.net',
  '48.0.0.0/8' => 'whois.arin.net',
  '49.0.0.0/8' => 'whois.apnic.net',
  '50.0.0.0/8' => 'whois.arin.net',
  '51.0.0.0/8' => 'whois.ripe.net',
  '52.0.0.0/8' => 'whois.arin.net',
  '54.0.0.0/8' => 'whois.arin.net',
  '56.0.0.0/8' => 'whois.arin.net',
  '58.0.0.0/8' => 'whois.apnic.net',
  '59.0.0.0/8' => 'whois.apnic.net',
  '60.0.0.0/8' => 'whois.apnic.net',
  '61.0.0.0/8' => 'whois.apnic.net',
  '62.0.0.0/8' => 'whois.ripe.net',
  '63.0.0.0/8' => 'whois.arin.net',
  '64.0.0.0/8' => 'whois.arin.net',
  '65.0.0.0/8' => 'whois.arin.net',
  '66.0.0.0/8' => 'whois.arin.net',
  '67.0.0.0/8' => 'whois.arin.net',
  '68.0.0.0/8' => 'whois.arin.net',
  '69.0.0.0/8' => 'whois.arin.net',
  '70.0.0.0/8' => 'whois.arin.net',
  '71.0.0.0/8' => 'whois.arin.net',
  '72.0.0.0/8' => 'whois.arin.net',
  '73.0.0.0/8' => 'whois.arin.net',
  '74.0.0.0/8' => 'whois.arin.net',
  '75.0.0.0/8' => 'whois.arin.net',
  '76.0.0.0/8' => 'whois.arin.net',
  '77.0.0.0/8' => 'whois.ripe.net',
  '78.0.0.0/8' => 'whois.ripe.net',
  '79.0.0.0/8' => 'whois.ripe.net',
  '80.0.0.0/8' => 'whois.ripe.net',
  '81.0.0.0/8' => 'whois.ripe.net',
  '82.0.0.0/8' => 'whois.ripe.net',
  '83.0.0.0/8' => 'whois.ripe.net',
  '84.0.0.0/8' => 'whois.ripe.net',
  '85.0.0.0/8' => 'whois.ripe.net',
  '86.0.0.0/8' => 'whois.ripe.net',
  '87.0.0.0/8' => 'whois.ripe.net',
  '88.0.0.0/8' => 'whois.ripe.net',
  '89.0.0.0/8' => 'whois.ripe.net',
  '90.0.0.0/8' => 'whois.ripe.net',
  '91.0.0.0/8' => 'whois.ripe.net',
  '92.0.0.0/8' => 'whois.ripe.net',
  '93.0.0.0/8' => 'whois.ripe.net',
  '94.0.0.0/8' => 'whois.ripe.net',
  '95.0.0.0/8' => 'whois.ripe.net',
  '96.0.0.0/8' => 'whois.arin.net',
  '97.0.0.0/8' => 'whois.arin.net',
  '98.0.0.0/8' => 'whois.arin.net',
  '99.0.0.0/8' => 'whois.arin.net',
  '100.0.0.0/8' => 'whois.arin.net',
  '101.0.0.0/8' => 'whois.apnic.net',
  '102.0.0.0/8' => 'whois.afrinic.net',
  '103.0.0.0/8' => 'whois.apnic.net',
  '104.0.0.0/8' => 'whois.arin.net',
  '105.0.0.0/8' => 'whois.afrinic.net',
  '106.0.0.0/8' => 'whois.apnic.net',
  '107.0.0.0/8' => 'whois.arin.net',
  '108.0.0.0/8' => 'whois.arin.net',
  '109.0.0.0/8' => 'whois.ripe.net',
  '110.0.0.0/8' => 'whois.apnic.net',
  '111.0.0.0/8' => 'whois.apnic.net',
  '112.0.0.0/8' => 'whois.apnic.net',
  '113.0.0.0/8' => 'whois.apnic.net',
  '114.0.0.0/8' => 'whois.apnic.net',
  '115.0.0.0/8' => 'whois.apnic.net',
  '116.0.0.0/8' => 'whois.apnic.net',
  '117.0.0.0/8' => 'whois.apnic.net',
  '118.0.0.0/8' => 'whois.apnic.net',
  '119.0.0.0/8' => 'whois.apnic.net',
  '120.0.0.0/8' => 'whois.apnic.net',
  '121.0.0.0/8' => 'whois.apnic.net',
  '122.0.0.0/8' => 'whois.apnic.net',
  '123.0.0.0/8' => 'whois.apnic.net',
  '124.0.0.0/8' => 'whois.apnic.net',
  '125.0.0.0/8' => 'whois.apnic.net',
  '126.0.0.0/8' => 'whois.apnic.net',
  '128.0.0.0/8' => 'whois.arin.net',
  '129.0.0.0/8' => 'whois.arin.net',
  '130.0.0.0/8' => 'whois.arin.net',
  '131.0.0.0/8' => 'whois.arin.net',
  '132.0.0.0/8' => 'whois.arin.net',
  '133.0.0.0/8' => 'whois.apnic.net',
  '134.0.0.0/8' => 'whois.arin.net',
  '135.0.0.0/8' => 'whois.arin.net',
  '136.0.0.0/8' => 'whois.arin.net',
  '137.0.0.0/8' => 'whois.arin.net',
  '138.0.0.0/8' => 'whois.arin.net',
  '139.0.0.0/8' => 'whois.arin.net',
  '140.0.0.0/8' => 'whois.arin.net',
  '141.0.0.0/8' => 'whois.ripe.net',
  '142.0.0.0/8' => 'whois.arin.net',
  '143.0.0.0/8' => 'whois.arin.net',
  '144.0.0.0/8' => 'whois.arin.net',
  '145.0.0.0/8' => 'whois.ripe.net',
  '146.0.0.0/8' => 'whois.arin.net',
  '147.0.0.0/8' => 'whois.arin.net',
  '148.0.0.0/8' => 'whois.arin.net',
  '149.0.0.0/8' => 'whois.arin.net',
  '150.0.0.0/8' => 'whois.apnic.net',
  '151.0.0.0/8' => 'whois.ripe.net',
  '152.0.0.0/8' => 'whois.arin.net',
  '153.0.0.0/8' => 'whois.apnic.net',
  '154.0.0.0/8' => 'whois.afrinic.net',
  '155.0.0.0/8' => 'whois.arin.net',
  '156.0.0.0/8' => 'whois.arin.net',
  '157.0.0.0/8' => 'whois.arin.net',
  '158.0.0.0/8' => 'whois.arin.net',
  '159.0.0.0/8' => 'whois.arin.net',
  '160.0.0.0/8' => 'whois.arin.net',
  '161.0.0.0/8' => 'whois.arin.net',
  '162.0.0.0/8' => 'whois.arin.net',
  '163.0.0.0/8' => 'whois.apnic.net',
  '164.0.0.0/8' => 'whois.arin.net',
  '165.0.0.0/8' => 'whois.arin.net',
  '166.0.0.0/8' => 'whois.arin.net',
  '167.0.0.0/8' => 'whois.arin.net',
  '168.0.0.0/8' => 'whois.arin.net',
  '169.0.0.0/8' => 'whois.arin.net',
  '170.0.0.0/8' => 'whois.arin.net',
  '171.0.0.0/8' => 'whois.apnic.net',
  '172.0.0.0/8' => 'whois.arin.net',
  '173.0.0.0/8' => 'whois.arin.net',
  '174.0.0.0/8' => 'whois.arin.net',
  '175.0.0.0/8' => 'whois.apnic.net',
  '176.0.0.0/8' => 'whois.ripe.net',
  '177.0.0.0/8' => 'whois.lacnic.net',
  '178.0.0.0/8' => 'whois.ripe.net',
  '179.0.0.0/8' => 'whois.lacnic.net',
  '180.0.0.0/8' => 'whois.apnic.net',
  '181.0.0.0/8' => 'whois.lacnic.net',
  '182.0.0.0/8' => 'whois.apnic.net',
  '183.0.0.0/8' => 'whois.apnic.net',
  '184.0.0.0/8' => 'whois.arin.net',
  '185.0.0.0/8' => 'whois.ripe.net',
  '186.0.0.0/8' => 'whois.lacnic.net',
  '187.0.0.0/8' => 'whois.lacnic.net',
  '188.0.0.0/8' => 'whois.ripe.net',
  '189.0.0.0/8' => 'whois.lacnic.net',
  '190.0.0.0/8' => 'whois.lacnic.net',
  '191.0.0.0/8' => 'whois.lacnic.net',
  '192.0.0.0/8' => 'whois.arin.net',
  '193.0.0.0/8' => 'whois.ripe.net',
  '194.0.0.0/8' => 'whois.ripe.net',
  '195.0.0.0/8' => 'whois.ripe.net',
  '196.0.0.0/8' => 'whois.afrinic.net',
  '197.0.0.0/8' => 'whois.afrinic.net',
  '198.0.0.0/8' => 'whois.arin.net',
  '199.0.0.0/8' => 'whois.arin.net',
  '200.0.0.0/8' => 'whois.lacnic.net',
  '201.0.0.0/8' => 'whois.lacnic.net',
  '202.0.0.0/8' => 'whois.apnic.net',
  '203.0.0.0/8' => 'whois.apnic.net',
  '204.0.0.0/8' => 'whois.arin.net',
  '205.0.0.0/8' => 'whois.arin.net',
  '206.0.0.0/8' => 'whois.arin.net',
  '207.0.0.0/8' => 'whois.arin.net',
  '208.0.0.0/8' => 'whois.arin.net',
  '209.0.0.0/8' => 'whois.arin.net',
  '210.0.0.0/8' => 'whois.apnic.net',
  '211.0.0.0/8' => 'whois.apnic.net',
  '212.0.0.0/8' => 'whois.ripe.net',
  '213.0.0.0/8' => 'whois.ripe.net',
  '216.0.0.0/8' => 'whois.arin.net',
  '217.0.0.0/8' => 'whois.ripe.net',
  '218.0.0.0/8' => 'whois.apnic.net',
  '219.0.0.0/8' => 'whois.apnic.net',
  '220.0.0.0/8' => 'whois.apnic.net',
  '221.0.0.0/8' => 'whois.apnic.net',
  '222.0.0.0/8' => 'whois.apnic.net',
  '223.0.0.0/8' => 'whois.apnic.net',
};
  return $self;
}

sub get_server {
  my $self = shift;
  my $ip = shift || return undef;

  foreach my $range ( keys %{ $self->{data} } ) {
	if ( $range eq '0.0.0.0/2' ) {
		foreach my $cls_a ( 1 .. 126 ) {
		  my $block2 = Net::Netmask->new( "$cls_a.0.0.0/8" );
		  if ( $block2->match( $ip ) ) {
			return ( $self->{data}->{ $range }, $range );
		  }
		}
	}
	my $block = Net::Netmask->new( $range );
	if ( $block->match( $ip ) ) {
		return ( $self->{data}->{ $range }, $range );
	}
  }
  return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Client::Whois::IPBlks - Determine which whois server is responsible for a network address.

=head1 VERSION

version 1.38

=head1 SYNOPSIS

  use strict;
  use POE::Component::Client::Whois::IPBlks;

  my $ipblks = POE::Component::Client::Whois::IPBlks->new();

  my $whois_server = $ipblks->get_server('192.168.1.12');

=head1 DESCRIPTION

POE::Component::Client::Whois::IPBlks provides the ability to determine which whois server is responsible for a network address. It has a list of network ranges mapped to whois servers and uses L<Net::Netmask> to determine the appropriate Whois server for the given address.

=head1 CONSTRUCTOR

=over

=item C<new>

Returns a POE::Component::Client::Whois::IPBlks object.

=back

=head1 METHODS

=over

=item C<get_server>

Takes a single argument, an IP address to lookup the Whois for. Returns the applicable whois server or undef on failure.

=back

=head1 SEE ALSO

L<Net::Netmask>

L<http://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.xhtml>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
