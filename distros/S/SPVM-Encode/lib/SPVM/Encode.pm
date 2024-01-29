package SPVM::Encode;

our $VERSION = "0.003";

1;

=encoding utf8

=head1 Name

SPVM::Encode - Encode/Decode Strings

=head1 Description

The Encode class in L<SPVM> has methods to encode/docode strings.

=head1 Usage

  use Encode;
  
  my $string = "あいうえお";
  
  my $utf16_string = Encode->encode_utf16($string);
  
  my $string_again = Encode->decode_utf16($utf16_string);

=head1 Class Methods

=head2 decode_utf8

  static method decode_utf8 : string ($utf8_string : short[]);

Normalizes the UTF-8 string $utf8_string to NFC, and returns it.

=head2 encode_utf8

  static method encode_utf8 : short[] ($string : string);

Copies the UTF-8 string $string and returns it.

=head2 decode_utf16

  static method decode_utf16 : string ($utf16_string : short[]);

Converts the UTF-16 string $utf16_string to a UTF-8 string, and returns it.

=head2 encode_utf16

  static method encode_utf16 : short[] ($string : string);

Converts the UTF-8 string $string to a UTF-16 string, and returns it.

=head2 decode_utf32

  static method decode_utf32 : string ($utf32_string : int[]);

Converts the UTF-32 string(Unicode code points) $utf32_string to a UTF-8 string, and returns it.

=head2 encode_utf32

  static method encode_utf32 : int[] ($string : string);

Converts the UTF-8 string $string to a UTF-32 string(Unicode code points), and returns it.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
