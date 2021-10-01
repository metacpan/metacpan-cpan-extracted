package Mock::Data::Plugin::Net;
use Mock::Data::Plugin -exporter_setup => 1;
our @generators= qw( ipv4 cidr macaddr );
export(@generators);

our $VERSION = '0.03'; # VERSION
# ABSTRACT: Collection of generators for Internet-related data


sub apply_mockdata_plugin {
	my ($class, $mock)= @_;
	$mock->add_generators(
		map +("Net::$_" => $class->can($_)), @generators
	);
}


sub ipv4 {
	sprintf "127.%d.%d.%d", rand 256, rand 256, 1+rand 254;
}


sub cidr {
	my $blank= 1 + int rand 23;
	my $val= (int rand(1<<(24 - $blank))) << $blank;
	sprintf '127.%d.%d.%d/%d', (unpack 'C4', pack 'N', $val)[1,2,3], 32 - $blank;
}


sub macaddr {
	sprintf '%02x:%02x:%02x:%02x:%02x:%02x',
		((rand 64)<<2) | 0x02, rand 256, rand 256,
		rand 256, rand 256, rand 256
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Data::Plugin::Net - Collection of generators for Internet-related data

=head1 SYNOPSIS

  $mock= Mock::Data->new(['Net']);
  $mock->ipv4;     #  "127.54.23.132"
  $mock->cidr;     #  "127.43.0.0/16"
  $mock->macaddr;  #  "fc:34:23:98:13:53"

=head1 DESCRIPTION

This produces some simple patterns for network addresses.  It produces private IP ranges
and private MAC addresses.  Patches welcome for additional features.

=head1 GENERATORS

=head2 ipv4

Return a random IP address within C<< 127.0.0.0/8 >>, excluding .0 and .255

=head2 cidr

Return a random CIDR starting with C<< 127. >> like C<< 127.0.42.0/24 >>

=head2 macaddr

Return a random ethernet MAC in XX:XX:XX:XX:XX:XX format, taken from the Locally Administered
Address Ranges.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.03

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
