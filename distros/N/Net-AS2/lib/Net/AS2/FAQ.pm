=head1 NAME

Net::AS2::FAQ - Documents about Net::AS2 that does not fit the main document

=head1 Preparing Certificates

Keys and certificates in PEM forms are expected in L<Net::AS2>.

These could be prepared with the L<OpenSSL|http://openssl.org/> toolchain as follows:

=head2 Generating private key

    openssl genrsa -out my.key 1024

Please keep the key B<ONLY> to yourself.

The content could be used in the constructor.

=head2 Generating self-signed certificate

With this L<copy of openssl.conf|http://www.dylanbeattie.net/docs/openssl.conf>,

    openssl req -config openssl.conf -new -x509 -days 3650 -key my.key -out my.cert

Exchange the certificate with the communication partner.

The content could be used in the constructor.

=head2 Decoding .p12/.pfx certificate

In case you have generated a PKCS #12 key/certificate somewhere, you could
split them into key and certificate in PEM format with the following.

    openssl pkcs12 -in my.pfx -nodes

=head2 DER format to PEM format

If the certificate file is in binary format, most likely it is in the DER format.
Convert it into the PEM format with the following.

    openssl x509 -inform DER -outform PEM -in my.der.cert -out my.pem.cert

Ditto for keys

    openssl rsa -inform DER -outform PEM -in my.der.key -out my.pem.key

=head1 SEE ALSO

L<Net::AS2>

=cut

package Net::AS2::FAQ;

use strict;
use warnings;
our $VERSION = '1.0110'; # VERSION

1;
