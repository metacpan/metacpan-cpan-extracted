package RDF::Crypt;

use 5.010;

use RDF::Crypt::Verifier;
use RDF::Crypt::Signer;
use RDF::Crypt::Encrypter;
use RDF::Crypt::Decrypter;

our $SENDER;

BEGIN {
	$RDF::Crypt::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Crypt::VERSION   = '0.002';
}

1;

=head1 NAME

RDF::Crypt - semantic cryptography

=head1 DESCRIPTION

RDF-Crypt provides a variety of objects and methods for cryptographically
manipulating (encrypting, decrypting, signing and verifying) RDF graphs using
RSA and WebID.

RDF-Crypt uses a role-based architecture. Classes like RDF::Crypt::Encrypter
are in fact very slim wrappers around collections of roles. Most of the
interesting behaviour is documented in the role modules.

=head1 SEE ALSO

L<RDF::Crypt::Encrypter>,
L<RDF::Crypt::Decrypter>,
L<RDF::Crypt::Signer>,
L<RDF::Crypt::Verifier>.

L<Web::ID>, L<RDF::ACL>.

L<http://www.perlrdf.org/>.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010, 2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

