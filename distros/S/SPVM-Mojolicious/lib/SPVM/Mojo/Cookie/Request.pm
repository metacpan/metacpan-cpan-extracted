package SPVM::Mojo::Cookie::Request;



1;

=head1 Name

SPVM::Mojo::Cookie::Request - HTTP request cookie

=head1 Usage

  use Mojo::Cookie::Request;
  
  my $cookie = Mojo::Cookie::Request->new;
  $cookie->set_name("foo");
  $cookie->set_value("bar");
  say $cookie->to_string;

=head1 Description

Mojo::Cookie::Request class in L<SPVM> is a container for HTTP request cookies, based on L<RFC
6265|https://tools.ietf.org/html/rfc6265>.

=head1 Super Class

L<Mojo::Cookie|SPVM::Mojo::Cookie>

=head1 Class Methods

=head2 new

C<static method new : L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request> ();>

Creates a new L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request> object, and returns it.

=head1 Instance Methods

=head2 parse

C<method parse : L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request>[] ($string : string);>

Parses the string $string into the array of L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request> objects, and returns it.

Examples:

  my $cookies = Mojo::Cookie::Request->new->parse("f=b; g=a");

=head2 to_string

C<method to_string : string ();>

Renders the cookie to a string and returns it.

Examples:

  my $str = $cookie->to_string;

=head1 See Also

L<SPVM::Mojolicious>

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

