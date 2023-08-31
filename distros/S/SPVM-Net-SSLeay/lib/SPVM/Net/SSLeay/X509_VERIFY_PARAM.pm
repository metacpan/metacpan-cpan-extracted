package SPVM::Net::SSLeay::X509_VERIFY_PARAM;



1;

=head1 Name

SPVM::Net::SSLeay::X509_VERIFY_PARAM - X509_VERIFY_PARAM

=head1 Description

The Net::SSLeay::X509_VERIFY_PARAM class of L<SPVM> has methods to manipulate the X509_VERIFY_PARAM structure.

=head1 Usage

  use Net::SSLeay::X509_VERIFY_PARAM;

=head1 Instance Methods

=head2 set_hostflags

  method set_hostflags : void ($flags : int);

=head2 set1_host

  method set1_host : int ($name : string, $namelen : int = 0);

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

