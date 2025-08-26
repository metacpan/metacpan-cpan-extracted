package SPVM::Mojo::UserAgent::Proxy;



1;

=head1 Name

SPVM::Mojo::UserAgent::Proxy - User agent proxy manager

=head1 Description

Mojo::UserAgent::Proxy class in L<SPVM> manages proxy servers for L<Mojo::UserAgent|SPVM::Mojo::UserAgent>.

=head1 Usage

  use Mojo::UserAgent::Proxy;

  my $proxy = Mojo::UserAgent::Proxy->new;
  $proxy->detect;
  say $proxy->http;

=head1 Fields

=head2 http

C<has http : rw string;>

Proxy server to use for HTTP and WebSocket requests.

=head2 https

C<has https : rw string;>

Proxy server to use for HTTPS and WebSocket requests.

=head2 not

C<has not : rw string[];>

Domains that don't require a proxy server to be used.

=head1 Class Methods

C<static method new : L<Mojo::UserAgent::Proxy|SPVM::Mojo::UserAgent::Proxy> ();>

Create a new L<Mojo::UserAgent::Proxy|SPVM::Mojo::UserAgent::Proxy> object, and return it.

=head1 Instance Methods

=head2 detect

C<method detect : void ();>

Check environment variables C<HTTP_PROXY>, C<http_proxy>, C<HTTPS_PROXY>, C<https_proxy>, C<NO_PROXY> and C<no_proxy>
for proxy information. Automatic proxy detection can be enabled with the C<SPVM_MOJO_PROXY> environment variable.

=head2 is_needed

C<method is_needed : int ($domain : string) ;>

Check if request for domain would use a proxy server.

=head2 prepare

C<method prepare : void ($tx : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>);>

Prepare proxy server information for transaction.

=head1 See Also

=over 2

=item * L<Mojo::UserAgent|SPVM::Mojo::UserAgent>

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

