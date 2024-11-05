package SPVM::Net::SSLeay;

our $VERSION = "0.006";

1;

=head1 Name

SPVM::Net::SSLeay - OpenSSL Binding

=head1 Description

Net::SSLeay class in L<SPVM> is a binding for OpenSSL.

B<Warnings:>

B<The document is not finished yet. The tests haven't been written yet. The features may be changed without notice.> 

=head1 Usage

  use Net::SSLeay;

=head1 Examples

See source codes of L<IO::Socket::SSL|https://metacpan.org/pod/SPVM::IO::Socket::SSL> about examples of L<Net::SSLeay|SPVM::Net::SSLeay>.

=head1 Fields

=head2 operation_error

C<has operation_error : ro int;>

=head2 error

C<has error : ro long;>

=head1 Class Methods

=head2 new

C<static method new : Net::SSLeay ($ssl_ctx : L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>);>

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

=head2 set_fd

C<method set_fd : int ($fd : int);>

=head2 connect

C<method connect : int ();>

=head2 accept

C<method accept : int ();>

=head2 shutdown

C<method shutdown : int ();>

=head2 set_tlsext_host_name

C<method set_tlsext_host_name : int ($name : string);>

=head2 read

C<method read : int ($buf : mutable string, $num : int = -1, $offset : int = 0);>

=head2 peek

C<method peek : int ($buf : mutable string, $num : int = -1, $offset : int = 0);>

=head2 write

C<method write : int ($buf : string, $num : int = -1, $offset : int = 0);>

=head1 Modules

=over 2

=item * L<Net::SSLeay::SSL_METHOD|SPVM::Net::SSLeay::SSL_METHOD>

=item * L<Net::SSLeay::Constant|SPVM::Net::SSLeay::Constant>

=item * L<Net::SSLeay::X509|SPVM::Net::SSLeay::X509>

=item * L<Net::SSLeay::BIO|SPVM::Net::SSLeay::BIO>

=item * L<Net::SSLeay::ERR|SPVM::Net::SSLeay::ERR>

=item * L<Net::SSLeay::X509_VERIFY_PARAM|SPVM::Net::SSLeay::X509_VERIFY_PARAM>

=item * L<Net::SSLeay::X509_CRL|SPVM::Net::SSLeay::X509_CRL>

=item * L<Net::SSLeay::SSL_CTX|SPVM::Net::SSLeay::SSL_CTX>

=item * L<Net::SSLeay::X509_STORE_CTX|SPVM::Net::SSLeay::X509_STORE_CTX>

=item * L<Net::SSLeay::PEM|SPVM::Net::SSLeay::PEM>

=item * L<Net::SSLeay::X509_STORE|SPVM::Net::SSLeay::X509_STORE>

=back

=head2 Config Builder

L<SPVM::Net::SSLeay::ConfigBuilder>

=head1 Porting

This class is a Perl's L<Net::SSLeay> porting to L<SPVM>.

=head1 Repository

L<SPVM::Net::SSLeay - Github|https://github.com/yuki-kimoto/SPVM-Net-SSLeay>

=head1 Author

Yuki Kimoto<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

