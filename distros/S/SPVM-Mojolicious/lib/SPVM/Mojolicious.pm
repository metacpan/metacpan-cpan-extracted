package SPVM::Mojolicious;

our $VERSION = "0.027";

1;

=head1 Name

SPVM::Mojolicious - Real-time web framework

=head1 Description

This framewark is a Perl's L<Mojolicious> porting to L<SPVM>.

B<WARNINGS:>

This framework is still in early development: there is no documentation yet and method names, functionality and implementations change frequently and without warning.

Most tests are not written.

=head1 Details

=head2 HTTP Client

See L<Mojo::UserAgent|SPVM::Mojo::UserAgent> about the HTTP client in this web framework.

=head1 Classes

=over 2

=item * L<Mojo::Asset|SPVM::Mojo::Asset>

=item * L<Mojo::Asset::File|SPVM::Mojo::Asset::File>

=item * L<Mojo::Asset::Memory|SPVM::Mojo::Asset::Memory>

=item * L<Mojo::Cookie|SPVM::Mojo::Cookie>

=item * L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request>

=item * L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response>

=item * L<Mojo::Path|SPVM::Mojo::Path>

=item * L<Mojo::Parameters|SPVM::Mojo::Parameters>

=item * L<Mojo::URL|SPVM::Mojo::URL>

=item * L<Mojo::Date|SPVM::Mojo::Date>

=item * L<Mojo::Collection|SPVM::Mojo::Collection>

=item * L<Mojo::File|SPVM::Mojo::File>

=item * L<Mojo::Headers|SPVM::Mojo::Headers>

=item * L<Mojo::SSE|SPVM::Mojo::SSE>

=item * L<Mojo::SSE::Event|SPVM::Mojo::SSE::Event>

=item * L<Mojo::Content|SPVM::Mojo::Content>

=item * L<Mojo::Content::Single|SPVM::Mojo::Content::Single>

=item * L<Mojo::Content::MultiPart|SPVM::Mojo::Content::MultiPart>

=item * L<Mojo::Message|SPVM::Mojo::Message>

=item * L<Mojo::Message::Request|SPVM::Mojo::Message::Request>

=item * L<Mojo::Message::Response|SPVM::Mojo::Message::Response>

=item * L<Mojo::Upload|SPVM::Mojo::Upload>

=item * L<Mojo::Transaction|SPVM::Mojo::Transaction>

=item * L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>

=item * L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>

=item * L<Mojo::WebSocket::Frame|SPVM::Mojo::WebSocket::Frame>

=item * L<Mojo::WebSocket|SPVM::Mojo::WebSocket>

=item * L<Mojo::UserAgent|SPVM::Mojo::UserAgent>

=item * L<Mojo::UserAgent::Transactor|SPVM::Mojo::UserAgent::Transactor>

=item * L<Mojo::UserAgent::Proxy|SPVM::Mojo::UserAgent::Proxy>

=item * L<Mojo::UserAgent::CookieJar|SPVM::Mojo::UserAgent::CookieJar>

=item * L<Mojo::UserAgent::CookieJar::Callback::Ignore|SPVM::Mojo::UserAgent::CookieJar::Callback::Ignore>

=item * L<Mojo::UserAgent::Transactor::Endpoint|SPVM::Mojo::UserAgent::Transactor::Endpoint>

=item * L<Mojo::UserAgent::Transactor::Callback::Generator|SPVM::Mojo::UserAgent::Transactor::Callback::Generator>

=back

=head1 Porting

Mojolicious in L<SPVM> is a Perl's L<Mojolicious> porting to SPVM.

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

