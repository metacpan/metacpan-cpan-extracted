package SPVM::Digest::SHA;

our $VERSION = "0.061001";

1;

=head1 Name

SPVM::Digest::SHA - SHA-1/224/256/384/512

=head1 Description

The SPVM::Digest::SHA of L<SPVM> has methods for SHA-1/224/256/384/512.

=head1 Usage

  use Digest::SHA;
  
  my $digest = Digest::SHA->sha1($data);
  my $digest = Digest::SHA->sha1_hex($data);
  my $digest = Digest::SHA->sha1_base64($data);
  
  my $digest = Digest::SHA->sha256($data);
  my $digest = Digest::SHA->sha384_hex($data);
  my $digest = Digest::SHA->sha512_base64($data);

Object Oriented Programming:

  my $sha = Digest::SHA->new($alg);
  
  $sha->add($data);
  
  my $sha_copy = $sha->clone;
  
  my $digest = $sha->digest;
  my $digest = $sha->hexdigest;
  my $digest = $sha->b64digest;

=head1 Class Methods

=head2 sha1

C<static method sha1 : string ($data : string);>

Receive the input date and return its SHA-1 digest encoded as a binary string.

=head2 sha1_hex

C<static method sha1_hex : string ($data : string);>

Receive the input date and return its SHA-1 digest encoded as a hexadecimal string.

=head2 sha1_base64

C<static method sha1_base64 : string ($data : string);>

Receive the input date and return its SHA-1 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 sha224

C<static method sha224 : string ($data : string);>

Receive the input date and return its SHA-224 digest encoded as a binary string.

=head2 sha224_hex

C<static method sha224_hex : string ($data : string);>

Receive the input date and return its SHA-224 digest encoded as a hexadecimal string.

=head2 sha224_base64

C<static method sha224_base64 : string ($data : string);>

Receive the input date and return its SHA-224 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 sha256

C<static method sha256 : string ($data : string);>

Receive the input date and return its SHA-256 digest encoded as a binary string.

=head2 sha256_hex

C<static method sha256_hex : string ($data : string);>

Receive the input date and return its SHA-256 digest encoded as a hexadecimal string.

=head2 sha256_base64

C<static method sha256_base64 : string ($data : string);>

Receive the input date and return its SHA-256 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 sha384

C<static method sha384 : string ($data : string);>

Receive the input date and return its SHA-384 digest encoded as a binary string.

=head2 sha384_hex

C<static method sha384_hex : string ($data : string);>

Receive the input date and return its SHA-384 digest encoded as a hexadecimal string.

=head2 sha384_base64

C<static method sha384_base64 : string ($data : string);>

Receive the input date and return its SHA-384 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 sha512

C<static method sha512 : string ($data : string);>

Receive the input date and return its SHA-512 digest encoded as a binary string.

=head2 sha512_hex

C<static method sha512_hex : string ($data : string);>

Receive the input date and return its SHA-512 digest encoded as a hexadecimal string.

=head2 sha512_base64

C<static method sha512_base64 : string ($data : string);>

Receive the input date and return its SHA-512 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 sha512224

C<static method sha512224 : string ($data : string);>

Receive the input date and return its SHA-512/224 digest encoded as a binary string.

=head2 sha512224_hex

C<static method sha512224_hex : string ($data : string);>

Receive the input date and return its SHA-512/224 digest encoded as a hexadecimal string.

=head2 sha512224_base64

C<static method sha512224_base64 : string ($data : string);>

Receive the input date and return its SHA-512/224 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 sha512256

C<static method sha512256 : string ($data : string);>

Receive the input date and return its SHA-512/256 digest encoded as a binary string.

=head2 sha512256_hex

C<static method sha512256_hex : string ($data : string);>

Receive the input date and return its SHA-512/256 digest encoded as a hexadecimal string.

=head2 sha512256_base64

C<static method sha512256_base64 : string ($data : string);>

Receive the input date and return its SHA-512/256 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 hmac_sha1

C<static method hmac_sha1 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-1 digest encoded as a binary string.

=head2 hmac_sha1_hex

C<static method hmac_sha1_hex : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-1 digest encoded as a hexadecimal string.

=head2 hmac_sha1_base64

C<static method hmac_sha1_base64 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-1 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 hmac_sha224

C<static method hmac_sha224 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-224 digest encoded as a binary string.

=head2 hmac_sha224_hex

C<static method hmac_sha224_hex : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-224 digest encoded as a hexadecimal string.

=head2 hmac_sha224_base64

C<static method hmac_sha224_base64 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-224 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 hmac_sha256

C<static method hmac_sha256 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-256 digest encoded as a binary string.

=head2 hmac_sha256_hex

C<static method hmac_sha256_hex : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-256 digest encoded as a hexadecimal string.

=head2 hmac_sha256_base64

C<static method hmac_sha256_base64 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-256 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 hmac_sha384

C<static method hmac_sha384 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-384 digest encoded as a binary string.

=head2 hmac_sha384_hex

C<static method hmac_sha384_hex : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-384 digest encoded as a hexadecimal string.

=head2 hmac_sha384_base64

C<static method hmac_sha384_base64 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-384 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 hmac_sha512

C<static method hmac_sha512 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-512 digest encoded as a binary string.

=head2 hmac_sha512_hex

C<static method hmac_sha512_hex : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-512 digest encoded as a hexadecimal string.

=head2 hmac_sha512_base64

C<static method hmac_sha512_base64 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-512 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 hmac_sha512224

C<static method hmac_sha512224 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-512/224 digest encoded as a binary string.

=head2 hmac_sha512224_hex

C<static method hmac_sha512224_hex : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-512/224 digest encoded as a hexadecimal string.

=head2 hmac_sha512224_base64

C<static method hmac_sha512224_base64 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-512/224 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 hmac_sha512256

C<static method hmac_sha512256 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-512/256 digest encoded as a binary string.

=head2 hmac_sha512256_hex

C<static method hmac_sha512256_hex : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-512/256 digest encoded as a hexadecimal string.

=head2 hmac_sha512256_base64

C<static method hmac_sha512256_base64 : string ($data : string, $key : string);>

Receive the input date and return its HMAC-SHA-512/256 digest encoded as a Base64 string.

See L<Digest::SHA/"PADDING OF BASE64 DIGESTS"> for details about padding.

=head2 new

C<static method new : L<Digest::SHA|SPVM::Digest::SHA> ($alg : int);>

Returns a new C<Digest::SHA> object.  Allowed values for I<$alg> are 1,
224, 256, 384, 512, 512224, or 512256.  It's also possible to use
common string representations of the algorithm (e.g. "sha256",
"SHA-384").  If the argument is missing, SHA-1 will be used by
default.

=head1 Instance Methods

=head2 hashsize

C<method hashsize : int ();>

Returns the number of digest bits for this object.  The values are
160, 224, 256, 384, 512, 224, and 256 for SHA-1, SHA-224, SHA-256,
SHA-384, SHA-512, SHA-512/224 and SHA-512/256, respectively.

=head2 algorithm

C<method algorithm : int ();>

Returns the digest algorithm for this object.  The values are 1,
224, 256, 384, 512, 512224, and 512256 for SHA-1, SHA-224, SHA-256,
SHA-384, SHA-512, SHA-512/224, and SHA-512/256, respectively.

=head2 add

C<method add : void ($date : string);>

Use the input data to
update the current digest state.  In other words, the following
statements have the same effect:

  $sha->add("a"); $sha->add("b"); $sha->add("c");
  $sha->add("abc");

=head2 digest

C<method digest : string ();>

Returns the digest encoded as a binary string.

=head2 b64digest

C<method hexdigest : string ();>

Returns the digest encoded as a hexadecimal string.

=head2 b64digest

C<method b64digest : string ();>

Returns the digest encoded as a Base64 string.

=head2 

C<method clone : L<Digest::SHA|SPVM::Digest::SHA> ();>

Returns a duplicate copy of the object.

=head1 See Also

=head2 Digest::SHA

C<SPVM::Digest::SHA> is a Perl's L<Digest::SHA> porting to L<SPVM>.

=head1 Repository

L<SPVM::Digest::SHA - Github|https://github.com/yuki-kimoto/SPVM-Digest-SHA>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Contributors

L<Yoshiyuki Itoh|https://github.com/YoshiyukiItoh>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

