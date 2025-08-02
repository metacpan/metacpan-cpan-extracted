package SPVM::Mojo::Cookie;



1;

=head1 Name

SPVM::Mojo::Cookie - HTTP cookie base class

=head1 Description

Mojo::Cookie class in L<SPVM> an abstract base class for HTTP cookie containers, based on L<RFC
6265|https://tools.ietf.org/html/rfc6265>, like L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request> and L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response>.

=head1 Usage

  use Mojo::Cookie;
  
  class Mojo::Cookie::MyCookie extends Mojo::Cookie {
    
  }

=head1 Fields

=head2 name

C<has name : rw string;>

Cookie name.

=head2 value

C<has value : rw string;>

Cookie value.

=head1 Instance Methods

=head2 parse

C<method parse : L<Mojo::Cookie|SPVM::Mojo::Cookie>[] ($string : string);>

Parses the string $string into the array of L<Mojo::Cookie|SPVM::Mojo::Cookie> objects, and returns it.

Meant to be overloaded in a child class.

=head2 to_string

C<method to_string : string ();>

Renders the cookie to a string and returns it.

Meant to be overloaded in a child class.

=head1 Well Known Child Classes

=over 2

=item * L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request>

=item * L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response>

=back

=head1 See Also

L<SPVM::Mojolicious>

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

