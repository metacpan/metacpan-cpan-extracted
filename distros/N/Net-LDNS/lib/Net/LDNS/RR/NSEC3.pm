package Net::LDNS::RR::NSEC3;

use parent 'Net::LDNS::RR';

1;

=head1 NAME

Net::LDNS::RR::NSEC3 - Type NSEC3 record

=head1 DESCRIPTION

A subclass of L<Net::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item algorithm()

Returns the algorithm number.

=item flags()

Returns the flags field.

=item optout()

Returns the optout flag.

=item iterations()

Returns the iteration count.

=item salt()

Returns the cryptographic salt, in binary form.

=item next_owner()

Returns the next owner field.

=item typelist()

Returns the typelist as a space-separated string.

=item typehref()

Returns the typelist as a reference to a hash where the included types are keys storing true values.

=item covers($name)

Returns true or false depending on if the record covers the given name or not.

=back
