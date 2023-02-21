package SPVM::Digest::MD5;

our $VERSION = '0.11';

1;

=head1 Name

SPVM::Digest::MD5 - SPVM interface to the MD5 Algorithm

=head1 Usage

  use Digest::MD5;
  
  my $digest = Digest::MD5->md5($data);
  my $digest = Digest::MD5->md5_hex($data);
  my $digest = Digest::MD5->md5_base64($data);
  
  # OO interface
  my $md5 = Digest::MD5->new;
  
  $md5->add($data1);
  $md5->add($data2);
  
  my $digest = $md5->digest;
  my $digest = $md5->hexdigest;
  my $digest = $md5->b64digest;

=head1 Description

The C<Digest::MD5> module allows you to use the RSA Data Security
Inc. MD5 Message Digest algorithm from within Perl programs.  The
algorithm takes as input a message of arbitrary length and produces as
output a 128-bit "fingerprint" or "message digest" of the input.

C<Digest::MD5> is Perl's L<Digest::MD5> porting to L<SPVM>.

C<Digest::MD5> is a L<SPVM> module.

=head1 Caution

L<SPVM> is yet experimental status.

=head1 Class Methods

=head2 md5

  static method md5 : string ($data : string)

This function will concatenate all arguments, calculate the MD5 digest
of this "message", and return it in binary form.  The returned string
will be 16 bytes long.

=head2 md5_hex

  static method md5_hex : string ($data : string)

Same as md5(), but will return the digest in hexadecimal form. The
length of the returned string will be 32 and it will only contain
characters from this set: '0'..'9' and 'a'..'f'.

=head2 md5_base64

  static method md5_base64 : string ($data : string)

Same as md5(), but will return the digest as a base64 encoded string.
The length of the returned string will be 22 and it will only contain
characters from this set: 'A'..'Z', 'a'..'z', '0'..'9', '+' and
'/'.

Note that the base64 encoded string returned is not padded to be a
multiple of 4 bytes long.  If you want interoperability with other
base64 encoded md5 digests you might want to append the redundant
string "==" to the result.

=head2 new

  static method new : Digest::MD5 ();

The constructor returns a new C<Digest::MD5> object which encapsulate
the state of the MD5 message-digest algorithm.

=head1 Instance Methods

=head2 add

  method add : Digest::MD5 ($data : string);

The $data provided as argument are appended to the message we
calculate the digest for.  The return value is the $md5 object itself.

All these lines will have the same effect on the state of the $md5
object:

    $md5->add("a"); $md5->add("b"); $md5->add("c");
    $md5->add("a")->add("b")->add("c");
    $md5->add("abc");

=head2 digest

  method digest : string ();

Return the binary digest for the message.  The returned string will be
16 bytes long.

=head2 hexdigest

  method hexdigest : string ();

Same as $md5->digest, but will return the digest in hexadecimal
form. The length of the returned string will be 32 and it will only
contain characters from this set: '0'..'9' and 'a'..'f'.

=head2 b64digest

  method b64digest : string ();

Same as $md5->digest, but will return the digest as a base64 encoded
string.  The length of the returned string will be 22 and it will only
contain characters from this set: 'A'..'Z', 'a'..'z', '0'..'9', '+'
and '/'.


The base64 encoded string returned is not padded to be a multiple of 4
bytes long.  If you want interoperability with other base64 encoded
md5 digests you might want to append the string "==" to the result.

=head1 Repository

L<SPVM::Digest::MD5 - Github|https://github.com/yuki-kimoto/SPVM-Digest-MD5>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

