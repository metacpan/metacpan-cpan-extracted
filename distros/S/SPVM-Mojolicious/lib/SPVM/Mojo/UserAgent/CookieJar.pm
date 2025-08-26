package SPVM::Mojo::UserAgent::CookieJar;



1;

=head1 Name

SPVM::Mojo::UserAgent::CookieJar - Cookie jar for HTTP user agents

=head1 Description

Mojo::UserAgent::CookieJar class in L<SPVM> is a minimalistic and relaxed cookie jar used by L<Mojo::UserAgent|SPVM::Mojo::UserAgent>, based on L<RFC
6265|https://tools.ietf.org/html/rfc6265>.

=head1 Usage

  use Mojo::UserAgent::CookieJar;

  # Add response cookies
  my $jar = Mojo::UserAgent::CookieJar->new;
  $jar->add(
    Mojo::Cookie::Response->new(
      name   => "foo",
      value  => "bar",
      domain => "localhost",
      path   => "/test"
    )
  );
  
  # Find request cookies
  for my $cookie (@{$jar->find(Mojo::URL->new("http://localhost/test"))}) {
    say $cookie->name;
    say $cookie->value;
  }

=head1 Interfaces

=over 2

=item * L<Stringable|SPVM::Stringable>

=back

=head1 Fields

=head2 ignore

C<has ignore : rw L<Mojo::UserAgent::CookieJar::Callback::Ignore|SPVM::Mojo::UserAgent::CookieJar::Callback::Ignore>;>

A callback used to decide if a cookie should be ignored by L</"collect">.

Callback:

C<method : int ($cookie : L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response>);>

Examples:

  # Ignore all cookies
  $jar->ignore(method : int ($cookie : Mojo::Cookie::Response) {
    return 1;
  });
  
  # Ignore cookies for domains "com", "net" and "org"
  $jar->ignore(method : int ($cookie : Mojo::Cookie::Response) {
    
    unless (my $domain = $cookie->domain) {
      return 0;
    }
    
    return $domain eq "com" || $domain eq "net" || $domain eq "org";
  });

=head2 max_cookie_size

C<has max_cookie_size : rw int;>

Maximum cookie size in bytes, defaults to C<4096> (4KiB).

=head1 Class Methods

=head2 new

C<static method new : L<Mojo::UserAgent::CookieJar|SPVM::Mojo::UserAgent::CookieJar> ();>

Create a new L<Mojo::UserAgent::CookieJar|SPVM::Mojo::UserAgent::CookieJar> object and return it.

=head1 Instance Methods

=head2 add

C<method add : void ($cookie : object of L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response>|L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response>[]);>

Add multiple L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response> objects to the jar.

=head2 all
  
C<method all : L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response>[] ();>

Return all L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response> objects that are currently stored in the jar.

Examples:

  # Names of all cookies
  for my $_ (@{$jar->all}) {
    say $_->name;
  }
  
=head2 collect
  
C<method collect : void ($tx : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>);>

Collect response cookies from transaction.

=head2 empty
  
C<method empty : void ();>

Empty the jar.

=head2 find

C<method find : L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request>[] ($url : L<Mojo::URL|SPVM::Mojo::URL>);>

Find L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request> objects in the jar for L<Mojo::URL|SPVM::Mojo::URL> object.

Examples:

  # Names of all cookies found
  for my $_ (@{$jar->find(Mojo::URL->new("http://example.com/foo"))}) {
    say $_->name;
  }

=head2 load

Not implemented.

=head2 prepare

C<method prepare : void ($tx : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>);>

Prepare request cookies for transaction.

=head2 to_string

C<method to_string : string ();>

=head2 save

Not implemented.

=head1 See Also

=over 2

=item * L<Mojo::UserAgent|SPVM::Mojo::UserAgent>

=item * L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response>

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

