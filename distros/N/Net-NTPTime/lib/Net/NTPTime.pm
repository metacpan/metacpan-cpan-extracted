package Net::NTPTime;

require Socket;
use base qw(Exporter);

our @EXPORT = qw(get_ntp_time get_unix_time);

our $VERSION = '1.00';

sub get_ntp_time
{
	my $hostname = shift(@_) || '0.north-america.pool.ntp.org';
	socket(SOCKET, PF_INET, SOCK_DGRAM, getprotobyname('udp'));
	my $ipaddr = inet_aton($hostname);
	my $portaddr = sockaddr_in(123, $ipaddr);
	my $bstr = "\010" . "\0"x47;
	send(SOCKET, $bstr, 0, $portaddr);
	$portaddr = recv(SOCKET, $bstr, 1024, 0);
	my @words = unpack("N12",$bstr);
	return($words[10]);
}

sub get_unix_time
{
	my $hostname = shift(@_) || '0.north-america.pool.ntp.org';
	return(&get_ntp_time($hostname) - 2208988800);
}

=head1 NAME

Net::NTPTime - Retrieve NTP and UNIX timestamp (unsigned integer) from an NTP server.

=head1 SYNOPSIS

	use Net::NTPTime;
	
	my $unix_time = get_unix_time;
	
	my $unix_time = get_unix_time('ntp.server.com');
	
	my $ntp_time = get_ntp_time;
	
	my $ntp_time = get_ntp_time('ntp.server.com');

=head1 DESCRIPTION

Retrieves timestamps in NTP and UNIX formats from an NTP server.

=head1 METHODS

=head2 get_unix_time(OPTIONAL_NTP_SERVER)

Returns an integer timestamp indicating the number of elapsed seconds since 00:00 01-JAN-1970.
You may include a specific NTP server to ping, or a default server will be used.

=head2 get_ntp_time(OPTIONAL_NTP_SERVER)

Returns an integer timestamp indicating the number of elapsed seconds since 00:00 01-JAN-1900.
You may include a specific NTP server to ping, or a default server will be used.

=head1 The real credit goes to Tim Hogard for writing the code to do this. Thanks!

=head1 AUTHOR, COPYRIGHT, and LICENSE

Copyright(C) 2009, phatWares, USA. All rights reserved.

Permission is granted to use this software under the same terms as Perl itself.
Refer to the L<Perl Artistic|perlartistic> license for details.

=cut
