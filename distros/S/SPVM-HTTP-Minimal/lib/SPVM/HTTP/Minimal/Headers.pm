package SPVM::HTTP::Minimal::Headers;



1;

=head1 Name

SPVM::HTTP::Minimal::Headers - HTTP Headers

=head1 Description

The HTTP::Minimal::Headers class of L<SPVM> has methods to manipulate HTTP headers.

=head1 Usage

  my $headers = HTTP::Minimal::Headers->new;

=head1 Class Methods

=head2 new

  static method new : HTTP::Minimal::Headers ();

Creates a new L<HTTP::Minimal::Headers|SPVM::HTTP::Minimal::Headers> object.

=head2 Instance Methods

=head2 add

  method add : void ($name : string, $value : string);

Adds a header.

=head2 remove

  method remove : void ($name : string);

Removes a header.

=head2 get

  method get : string[] ($name : string);

Gets a header value.

=head2 get_as_string

  method get_as_string : string ($name : string);

Gets a header value as a string.

=head2 names

  method names : string[] ();

Gets header names.

=head2 to_string

  method to_string : string ();

Converts all headers to a string.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

