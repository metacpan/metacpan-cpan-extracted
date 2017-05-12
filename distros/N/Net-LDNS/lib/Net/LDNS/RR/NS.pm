package Net::LDNS::RR::NS;

use parent 'Net::LDNS::RR';

1;

=head1 NAME

Net::LDNS::RR::NS - Type NS record

=head1 DESCRIPTION

A subclass of L<Net::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item nsdname()

Returns the name of the nameserver.

=back
