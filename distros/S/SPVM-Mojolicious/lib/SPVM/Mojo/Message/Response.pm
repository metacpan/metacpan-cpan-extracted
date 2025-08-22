package SPVM::Mojo::Message::Response;



1;

=head1 Name

SPVM::Mojo::Message::Response - HTTP response

=head1 Description

Mojo::Message::Response class in L<SPVM> is a container for HTTP responses, based on L<RFC 7230|https://tools.ietf.org/html/rfc7230>
and L<RFC 7231|https://tools.ietf.org/html/rfc7231>.

=head1 Usage
  
  use Mojo::Message::Response;
  
  # Parse
  my $res = Mojo::Message::Response->new;
  $res->parse("HTTP/1.0 200 OK\x0d\x0a");
  $res->parse("Content-Length: 12\x0d\x0a");
  $res->parse("Content-Type: text/plain\x0d\x0a\x0d\x0a");
  $res->parse('Hello World!');
  say $res->code;
  say $res->headers->content_type;
  say $res->body;
  
  # Build
  my $res = Mojo::Message::Response->new;
  $res->set_code(200);
  $res->headers->set_content_type("text/plain");
  $res->set_body("Hello World!");
  say $res->to_string;

=head1 Inheritance

L<Mojo::Message|SPVM::Mojo::Message>

=head1 Fields

=head2 code

C<has code: rw int;>

HTTP response status code.

=head2 max_message_size

C<has max_message_size : rw int>

Maximum message size in bytes, defaults to the value of the C<SPVM_MOJO_MAX_MESSAGE_SIZE> environment variable or
C<2147483648> (2GiB). Setting the value to C<0> will allow messages of indefinite size.

=head2 message

C<has message : rw string;>

HTTP response status message.

=head1 Class Methods

=head2 new

C<static method new : L<Mojo::Message::Response|SPVM::Mojo::Message::Response> ();>

Create a new L<Mojo::Message::Response|SPVM::Mojo::Message::Response> object and return it.

=head1 Instance Methods

=head2 cookies

C<method cookies : L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response>[] ();>

Access response cookies, usually L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response> objects.

  # Names of all cookies
  for my $_ (@{$res->cookies}) {
    say $_->name;
  }

=head2 default_message

C<method default_message : string ($code : int = -1);>

Generate default response message for status code, defaults to using L</"code">.

=head2 extract_start_line

C<method extract_start_line : int ($bufref : string[]);>

Extract status-line from string.

=head2 fix_headers

C<method fix_headers : void ();>

Make sure response has all required headers.

=head2 get_start_line_chunk

C<method get_start_line_chunk : string ($offset : int);>

Get a chunk of status-line data starting from a specific position. Note that this method finalizes the response.

=head2 is_client_error

C<method is_client_error : int ($code : int);>

Check if this response has a C<4xx> status L</"code">.

=head2 is_empty

C<method is_empty : int ();>

Check if this response has a C<1xx>, C<204> or C<304> status L</"code">.

=head2 is_error

C<method is_error : int ();>

Check if this response has a C<4xx> or C<5xx> status L</"code">.

=head2 is_info

C<method is_info : int ();>

Check if this response has a C<1xx> status L</"code">.

=head2 is_redirect

C<method is_redirect : int ();>

Check if this response has a C<3xx> status L</"code">.

=head2 is_server_error

C<method is_server_error : int ();>

Check if this response has a C<5xx> status L</"code">.

=head2 is_success

C<method is_success : int ();>

Check if this response has a C<2xx> status L</"code">.

=head2 start_line_size

C<method start_line_size : int ();>

Size of the status-line in bytes. Note that this method finalizes the response.

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
