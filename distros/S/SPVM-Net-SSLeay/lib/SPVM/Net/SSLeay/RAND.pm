package SPVM::Net::SSLeay::RAND;



1;

=head1 Name

SPVM::Net::SSLeay::RAND - RAND Name Space in OpenSSL

=head1 Description

Net::SSLeay::RAND class in L<SPVM> represents C<RAND> name space in OpenSSL.

=head1 Usage

  use Net::SSLeay::RAND;

=head1 Class Methods

=head2 seed

C<static method seed : void ($buf : string, $num : int);>

Calls native L<RAND_seed|https://docs.openssl.org/master/man3/RAND_seed> function.

Exceptions:

The buffer $buf must be defined. Otherwise an exception is thrown.

=head2 poll

C<static method poll : int ();>

Calls native L<RAND_poll|https://docs.openssl.org/master/man3/RAND_poll> function.

=head2 load_file

C<static method load_file : int ($filename : string, $max_bytes : long);>

Calls native L<RAND_load_file|https://docs.openssl.org/master/man3/RAND_load_file> function given $filename and $max_bytes, and returns its return value.

Exceptions:

The filename $filename must be defined.

If RAND_load_file failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

