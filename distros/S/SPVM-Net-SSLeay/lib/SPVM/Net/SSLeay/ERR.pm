package SPVM::Net::SSLeay::ERR;



1;

=head1 Name

SPVM::Net::SSLeay::ERR - ERR Name Space in OpenSSL

=head1 Description

Net::SSLeay::ERR class in L<SPVM> has represents C<ERR> name space in OpenSSL.

=head1 Usage

  use Net::SSLeay::ERR;

=head1 Class Methods

=head2 error_string_n

C<static method error_string_n : void ($e : long, $buf : mutable string, $len : int = -1);>

Calls native L<ERR_error_string_n|https://docs.openssl.org/master/man3/ERR_error_string_n> function.

Exceptions:

The buffer $buf must be defined. Otherwise an exception is thrown.

The length $len must be less than or equal to the length of the buffer $buf. Otherwise an exception is thrown.

=head2 error_string

C<static method error_string : string ($e : long);>

Same as L</"error_string_n> method, but $buf of the length 256 is created automatically.

The returned string is cut just before C<\0>.

=head2 get_error

C<method get_error : long ();>

Returns the earliest error code from the thread's error queue and removes the entry by calling native L<ERR_get_error|https://docs.openssl.org/master/man3/ERR_get_error> function.

=head2 peek_error

C<method peek_error : long ();>

Returns the earliest error code from the thread's error queue and removes the entry by calling native L<ERR_peek_error|https://docs.openssl.org/master/man3/ERR_peek_error> function.

=head2 peek_last_error

C<method peek_last_error : long ();>

Returns the earliest error code from the thread's error queue and removes the entry by calling native L<ERR_peek_last_error|https://docs.openssl.org/master/man3/ERR_peek_last_error> function.

=head1 See Also

=over 2

=item * L<Net::SSLeay|SPVM::Net::SSLeay>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
