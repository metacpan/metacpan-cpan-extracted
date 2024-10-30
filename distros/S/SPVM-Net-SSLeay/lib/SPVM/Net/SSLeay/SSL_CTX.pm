package SPVM::Net::SSLeay::SSL_CTX;



1;

=head1 Name

SPVM::Net::SSLeay::SSL_CTX - SSL/TLS Contexts

=head1 Description

The Net::SSLeay::SSL_CTX class of L<SPVM> has methods to manipulate SSL/TLS contexts.

=head1 Usage

  use Net::SSLeay::SSL_CTX;

=head1 Class Methods

=head2 new

  static method new : Net::SSLeay::SSL_CTX ($method : Net::SSLeay::SSL_METHOD);

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

=head2 set_mode

  method set_mode : long ($mode : long);

=head2 set_verify

  method set_verify : int ($mode : int);

=head2 get0_param

  method get0_param : Net::SSLeay::X509_VERIFY_PARAM ();

=head2 set_default_verify_paths

  method set_default_verify_paths : int ();

=head2 use_certificate_file

  method use_certificate_file : int ($file : string, $type : int);

=head2 use_certificate_chain_file

  method use_certificate_chain_file : int ($file : string);

=head2 use_PrivateKey_file

  method use_PrivateKey_file : int ($file : string, $type : int);

=head2 set_cipher_list

  method set_cipher_list : int ($str : string);

=head2 set_ciphersuites

  method set_ciphersuites : int ($str : string);

=head2 set_options

C<method set_options : long ($options : long);>

=head2 get_options

C<native method get_options : long ();>

=head2 clear_options

C<native method clear_options : long ($options : long);>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

