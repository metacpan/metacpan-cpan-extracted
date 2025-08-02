package SPVM::Mojo::Cookie::Response;



1;

=head1 Name

SPVM::Mojo::Cookie::Response - HTTP response cookie

=head1 Description

Mojo::Cookie::Response class in L<SPVM> a container for HTTP response cookies, based on L<RFC
6265|https://tools.ietf.org/html/rfc6265>.

=head1 Usage

  use Mojo::Cookie::Response;
  
  my $cookie = Mojo::Cookie::Response->new;
  $cookie->set_name("foo");
  $cookie->set_value("bar");
  say $cookie->to_string;

=head1 Super Class

L<Mojo::Cookie|SPVM::Mojo::Cookie>

=head1 Fields

=head2 domain

C<has domain : rw string;>

Cookie domain.

=head2 expires

C<has expires : rw long;>

Expiration for cookie.

=head2 host_only

C<has host_only : rw byte;>

Host-only flag, indicating that the canonicalized request-host is identical to the cookie's L</"domain">.

=head2 httponly

C<has httponly : rw byte;>

HttpOnly flag, which can prevent client-side scripts from accessing this cookie.

=head2 max_age

C<has max_age : rw int;>

Max age for cookie.

=head2 path

C<has path : rw string;>

Cookie path.

=head2 samesite

C<has samesite : rw string;>

SameSite value. Note that this attribute is B<EXPERIMENTAL> because even though most commonly used browsers support the
feature, there is no specification yet besides L<this
draft|https://tools.ietf.org/html/draft-west-first-party-cookies-07>.

=head2 secure

C<has secure : rw byte;>

Secure flag, which instructs browsers to only send this cookie over HTTPS connections.

=head1 Class Methods

=head2 new

C<static method new : L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response> ();>

Creates a new L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response> object, and returns it.

=head1 Instance Methods

=head2 parse

C<method parse : L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response>[] ($string : string);>

Parses the string $string into the array of L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response> objects, and returns it.

Examples:

  my $cookies = Mojo::Cookie::Response->new->parse("f=b; path=/");

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
