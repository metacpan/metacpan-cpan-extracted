package Net::LDNS::RR::DS;

use parent 'Net::LDNS::RR';

1;

=head1 NAME

Net::LDNS::RR::DS - Type DS record

=head1 DESCRIPTION

A subclass of L<Net::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item keytag()

Returns the keytag value.

=item digtype()

Returns the numeric digest type.

=item algorithm()

Returns the algorithm number.

=item digest()

Returns the cryptographic digest in binary form.

=item hexdigest()

Returns the cryptographic digest as a hexadecimal string.

=item verify($other)

Checks if the current object is derived from the other object (if it's a DNSKEY) or was derived from the same DNSKEY as the other object (if it's a
DS). If used with any other type of RR, it always returns false.

=back
