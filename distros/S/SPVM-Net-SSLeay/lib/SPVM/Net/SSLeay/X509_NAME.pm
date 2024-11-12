package SPVM::Net::SSLeay::X509_NAME;



1;

=head1 Name

SPVM::Net::SSLeay::X509_NAME - X509_NAME Data Structure in OpenSSL

=head1 Description

Net::SSLeay::X509_NAME class in L<SPVM> represents L<X509_NAME|https://docs.openssl.org/3.2/man3/X509_new/> data structure in OpenSSL

=head1 Usage

  use Net::SSLeay::X509_NAME;

=head1 Instance Methods

=head2 oneline

C<method oneline : string ();>

Calls native L<X509_NAME_oneline|https://docs.openssl.org/1.1.1/man3/X509_NAME_print_ex> functions given $buf with NULL, and returns its return value.

=head2 get_text_by_NID

C<method get_text_by_NID : int ($nid : int, $buf : mutable string, $len : int = -1);>

Calls native L<X509_get_text_by_NID|https://docs.openssl.org/1.1.1/man3/X509_NAME_get_index_by_NID> functions given $nid, $buf, $len, and returns its return value.

If $buf is defined and $len is a negative value, $len is set to the length of $buf.

=head2 DESTROY

C<method DESTROY : void ();>

Frees native L<X509_NAME|https://docs.openssl.org/3.2/man3/X509_new/> object by calling native L<X509_free|https://docs.openssl.org/3.2/man3/X509_new> function if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay::PEM|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

