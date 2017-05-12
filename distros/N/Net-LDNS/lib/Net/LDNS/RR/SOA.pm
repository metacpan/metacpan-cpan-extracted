package Net::LDNS::RR::SOA;

use parent 'Net::LDNS::RR';

1;

=head1 NAME

Net::LDNS::RR::SOA - Type SOA record

=head1 DESCRIPTION

A subclass of L<Net::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item mname()

Returns the master server name.

=item rname()

Returns the contact mail address, in DNAME format.

=item serial()

Returns the serial number.

=item refresh()

=item retry()

=item refresh()

=item minimum()

Returns the respective timing values from the record.

=back
