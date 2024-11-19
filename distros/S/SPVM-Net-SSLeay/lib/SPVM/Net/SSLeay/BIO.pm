package SPVM::Net::SSLeay::BIO;



1;

=head1 Name

SPVM::Net::SSLeay::BIO - BIO Data Strucutre in OpenSSL

=head1 Description

Net::SSLeay::BIO class of L<SPVM> represents L<BIO|https://docs.openssl.org/1.0.2/man3/BIO_new> data structure in OpenSSL.

=head1 Usage

  use Net::SSLeay::BIO;

=head1 Class Methods

=head2 new

C<static method new : L<Net::SSLeay::BIO|SPVM::Net::SSLeay::BIO> ();>

Calls L<BIO_new|https://docs.openssl.org/1.0.2/man3/BIO_new/> function given the return value of native L<BIO_s_mem|https://docs.openssl.org/1.0.2/man3/BIO_s_mem/> function as the first argument, creates a new L<Net::SSLeay::BIO|SPVM::Net::SSLeay::BIO> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

Exceptions:

If BIO_new failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 new_file

C<static method new_file : Net::SSLeay::BIO ($filename : string, $mode : string);>

Calls native L<BIO_new_file|https://docs.openssl.org/1.0.2/man3/BIO_new_file/> function given the file name $filename and the mode $mode, creates a new L<Net::SSLeay::BIO|SPVM::Net::SSLeay::BIO> object, sets the pointer value of the new object to the return value of the native function, and returns the new object.

Exceptions:

If BIO_new_file failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head1 Instance Methods

=head2 read

C<method read : int ($data : mutable string, $dlen : int = -1);>

Calls native L<BIO_read|https://docs.openssl.org/1.0.2/man3/BIO_read/> function given the pointer value of the instance, $data and $dlen, and returns its return value.

If $dlen is lower than 0, it is set to the length of $data.

Exceptions:

The $data must be defined. Otherwise an exception is thrown.

The $dlen must be lower than or equal to the length of the $data. Otherwise an exception is thrown.

If BIO_read failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 write

C<method write : int ($data : string, $dlen : int = -1);>

Calls native L<BIO_write|https://docs.openssl.org/1.0.2/man3/BIO_write/> function given the pointer value of the instance, $data and $dlen, and returns its return value.

If $dlen is lower than 0, it is set to the length of $data.

Exceptions:

The $data must be defined. Otherwise an exception is thrown.

The $dlen must be lower than or equal to the length of the $data. Otherwise an exception is thrown.

If BIO_write failed, an exception is thrown with C<eval_error_id> set to the basic type ID of L<Net::SSLeay::Error|SPVM::Net::SSLeay::Error> class.

=head2 DESTROY

C<method DESTROY : void ();>

Calls native L<BIO_free|https://docs.openssl.org/1.0.2/man3/BIO_free> function given the pointer value of the instance if C<no_free> flag of the instance is not a true value.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

