package SPVM::HTTP::Tiny;

our $VERSION = "0.012";

1;

=head1 Name

SPVM::HTTP::Tiny - HTTP Client

=head1 Description

HTTP::Tiny class in L<SPVM> is a HTTP client.

B<This class is highly experimental. Many dramatic incompatibilities are expected.>.

=head1 Usage

  use HTTP::Tiny;
  
  my $response = HTTP::Tiny->new->get('http://example.com/');
  
  unless ($response->success) {
    die "Failed!";
  }
  
  say $response->status;
  
  say $response->reason;
  
  for my $header_name (@{$response->headers->names}) {
    my $header_value = $response->headers->header($header_name);
    
    say $header_value;
  }
  
  if (length $response->content) {
    print $response->content;
  }

=head1 Fields

=head2 agent

  has agent : ro string;

The user agent.

=head2 timeout

  has timeout : ro double;

The request timeout seconds.

=head1 Class Methods

=head2 new

  static method new : HTTP::Tiny ($options : object[] = undef);

Creates a new L<HTTP::Tiny|SPVM::HTTP::Tiny> object.

Options:

=over 2

=item C<agent> : string

Sets the L</"agent"> field.

=item C<timeout> : Double

Sets the L</"timeout"> field.

=back

=head1 Instance Methods

=head2 get

  method get : HTTP::Tiny::Response ($url : string, $options : object[] = undef);

Gets the HTTP response by sending an HTTP GET request to the URL $url.

The HTTP response is a L<HTTP::Tiny::Response|SPVM::HTTP::Tiny::Response> object.

Options:

=over 2

=item C<headers> : L<HTTP::Tiny::Headers|SPVM::HTTP::Tiny::Headers>

Headers for an HTTP request.

=item C<timeout> : Double

Timeout seconds.

=back

=head2 head

  method head : HTTP::Tiny::Response ($url : string, $options : object[] = undef);

=head2 put

  method put : HTTP::Tiny::Response ($url : string, $options : object[] = undef);

=head2 post

  method post : HTTP::Tiny::Response ($url : string, $options : object[] = undef);

=head2 patch

  method patch : HTTP::Tiny::Response ($url : string, $options : object[] = undef);

=head2 delete

  method delete : HTTP::Tiny::Response ($url : string, $options : object[] = undef);

=head1 Repository

L<SPVM::HTTP::Tiny - Github|https://github.com/yuki-kimoto/SPVM-HTTP-Tiny>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

