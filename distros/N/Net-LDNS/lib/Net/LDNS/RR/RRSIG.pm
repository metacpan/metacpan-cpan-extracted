package Net::LDNS::RR::RRSIG;

use parent 'Net::LDNS::RR';

sub verify {
    my ( $self, $rrset, $keys ) = @_;
    my $msg = '';

    return $self->verify_time( $rrset, $keys, time(), $msg );
}

sub verify_str {
    my ( $self, $rrset, $keys ) = @_;
    my $msg = '';

    $self->verify_time( $rrset, $keys, time(), $msg );

    return $msg;
}

1;

=head1 NAME

Net::LDNS::RR::RRSIG - Type RRSIG record

=head1 DESCRIPTION

A subclass of L<Net::LDNS::RR>, so it has all the methods of that class available in addition to the ones documented here.

=head1 METHODS

=over

=item typecovered()

Returns a string with the name of the RR type this signature covers.

=item algorithm()

Returns the algorithm number.

=item labels()

Returns the number of labels that was used to calculate the signature.

=item origttl()

Returns the original TTL value.

=item expiration()

Returns the expiration time, as a time_t.

=item inception()

Returns the inception time, as a time_t.

=item keytag()

Returns the keytag.

=item signer()

Returns the signer name.

=item signature()

Returns the cryptographic signture in binary form.

=item verify($rrset_ref, $key_ref)

Cryptographically verifies that the signature in this object matches the given RRset and at least one of the given keys. C<$rrset_ref> should be a
reference to an array of RR objects, and C<$key_ref> a reference to an array of L<Net::LDNS::RR::DNSKEY> objects. This method simply returns a true
or false value, depending on the result och the check.

=item verify_str($rrset_ref, $key_ref)

Takes exactly the same arguments as L<verify()> and performs the same action, but instead of true/false it returns a string describing the result.
In the case of a successful result the message will be "All OK". For negative results, the string will describe the reason the verification failed.

=item verify_time($rrset_ref, $key_ref, $time, $msg)

This is the XS method doing the work for the previous two methods. C<$rrset_ref> and C<$key_ref> are the same as for the other methods. C<$time> is
the C<time_t> value for which the validation should be made (for the previous two methods it is set to the current computer time). C<$msg> should be
a writable scalar, and the string message describing the result will be but in it. The return value from the method is true/false.

=back
