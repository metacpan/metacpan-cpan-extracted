package SPVM::HTTP::Minimal;

our $VERSION = "0.001";
1;

=head1 Name

SPVM::HTTP::Minimal - HTTP Client

=head1 Description

The HTTP::Minimal class of L<SPVM> has methods for a HTTP client.

=head1 Usage

  use HTTP::Minimal;

  my $url = "http://google.com";
  
  my $http = HTTP::Minimal->new;
  
  my $res = $http->get($url);
  
  my $content = $res->content;

=head1 Fields

=head2 agent

  has agent : ro string;

The user agent.

=head2 timeout

  has timeout : ro int;

The request timeout seconds.

=head1 Class Methods

=head2 new

  static method new : HTTP::Minimal ($options : object[] = undef);

Creates a new L<HTTP::Minimal|SPVM::HTTP::Minimal> object.

Options:

=over 2

=item C<agent> : string

Sets the L</"agent"> field.

=item C<timeout> : Int

Sets the L</"timeout"> field.

=back

=head1 Instance Methods

=head2 get

  method get : HTTP::Minimal::Message::Response ($url : string, $options : object[] = undef);

Gets the HTTP response by sending an HTTP GET request to the URL $url.

The HTTP response is a L<HTTP::Minimal::Message::Response|SPVM::HTTP::Minimal::Message::Response> object.

Options:

=over 2

=item C<headers> : L<HTTP::Minimal::Headers|SPVM::HTTP::Minimal::Headers>

Headers for an HTTP request.

=item C<timeout> : Int

Timeout seconds.

=back

=head1 Repository

L<SPVM::HTTP::Minimal - Github|https://github.com/yuki-kimoto/SPVM-HTTP-Minimal>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

