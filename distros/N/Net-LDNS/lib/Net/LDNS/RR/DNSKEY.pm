package Net::LDNS::RR::DNSKEY;

use parent 'Net::LDNS::RR';

1;

=head1 NAME

Net::LDNS::RR::DNSKEY - Type DNSKEY record

=head1 DESCRIPTION

A subclass of L<Net::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item flags()

Returns the flag field as a number.

=item protocol()

Returns the protocol number.

=item algorithm()

Returns the algorithm number.

=item keydata()

Returns the cryptographic key in binary form.

=item ds($hash)

Returns a L<Net::LDNS::RR::DS> record matching this key. The argument must be one of the strings 'sha1', 'sha256', 'sha384' or 'gost'. GOST may not
be available, depending on how you ldns library was compiled.

=item keysize()

The size of the key stored in the record. For RSA variants, it's the length in bits of the prime number. For DSA variants, it's the key's "T" value
(see RFC2536). For DH, it's the value of the "prime length" field (and probably useless, since DH keys can't have signature records).

=back
