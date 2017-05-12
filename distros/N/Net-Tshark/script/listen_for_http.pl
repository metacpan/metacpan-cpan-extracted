use warnings;
use strict;
use lib '../lib';
use Net::Tshark;

# Start the capture process, looking for packets containing HTTP requests and responses
my $tshark = Net::Tshark->new or die "Could not start TShark";
$tshark->start(interface => 1, display_filter => 'http', promiscuous => 0);

# Do some stuff that would trigger HTTP requests/responses for 30 s
print 'Capturing HTTP packets for 10 seconds.';
for (1 .. 10)
{
	print '.';
	$| = 1;
	sleep 1;
}
print "done.\n\n";

# Get any packets captured
print "Stopping capture and reading packet data...\n";
$| = 1;
$tshark->stop;
my @packets = $tshark->get_packets;

# Output a report of what was captured
print 'Captured ' . scalar(@packets) . " HTTP packets:\n";

# Extract packet information by accessing each packet like a nested hash
foreach my $packet (@packets) {
	if ($packet->{http}->{request})
	{
		my $host = $packet->{http}->{host};
		my $method = $packet->{http}->{'http.request.method'};
		print "\t - HTTP $method request to $host\n";
	}
	else
	{
		my $code = $packet->{http}->{'http.response.code'};
		print "\t - HTTP response: $code\n";
	}
}


__END__

=head1 NAME

listen_for_http.pl - Example script for Net::Tshark that listens for local HTTP packets.

=head1 SYNOPSIS

  perl listen_for_http.pl

=head1 DESCRIPTION

Example script for Net::Tshark that listens for local HTTP packets on the first network interface, in non-promiscuous mode.

=head1 SEE ALSO

C<Net::Tshark> - Interface for the tshark network capture utility

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Zachary Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut