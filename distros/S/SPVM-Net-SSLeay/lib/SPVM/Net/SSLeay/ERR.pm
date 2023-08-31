package SPVM::Net::SSLeay::ERR;



1;

=head1 Name

SPVM::Net::SSLeay::ERR - SSL/TSL Errors

=head1 Description

The Net::SSLeay::ERR class of L<SPVM> has methods to manipulate SSL/TLS errors.

=head1 Usage

  use Net::SSLeay::ERR;

=head1 Class Methods

=head2 error_string_n

  static method error_string_n : void ($e : long, $buf : mutable string, $len : int = -1);

=head2 error_string

  static method error_string : string ($e : long);

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
