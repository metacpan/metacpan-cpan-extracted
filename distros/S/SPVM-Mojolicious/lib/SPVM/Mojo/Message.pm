package SPVM::Mojo::Message;



1;

=head1 Name

SPVM::Mojo::Message - HTTP message base class

=head1 Description

Mojo::Message class in L<SPVM> is an abstract base class for HTTP message containers, based on L<RFC
7230|https://tools.ietf.org/html/rfc7230>, L<RFC 7231|https://tools.ietf.org/html/rfc7231> and L<RFC
2388|https://tools.ietf.org/html/rfc2388>, like L<Mojo::Message::Request|SPVM::Mojo::Message::Request> and L<Mojo::Message::Response|SPVM::Mojo::Message::Response>.


This class is an abstract class for child classes.

=head1 Usage

  class Mojo::Message::MyMessage extends Mojo::Message {
    
  }

=head1 Interfaces

=over 2

=item * L<Stringable|SPVM::Stringable>

=back

=head1 Events

=head2 finish

Emitted after message building or parsing is finished.

  my $before = Sys->time;
  $msg->on(finish => method : void ($msg : Mojo::Message) {
    $msg->headers->set_header("X-Parser-Time" => Sys->time - $before);
  });

=head2 progress

Emitted when message building or parsing makes progress.

  # Building
  $msg->on(progress => method : void ($msg : Mojo::Message, $state : string, $offset : Int) { say "Building \"$state\" at offset " . (int)$offset });
  
  # Parsing
  $msg->on(progress => method : void ($msg : Mojo::Message) {
    
  });

=head1 Fields

=head2 content

C<has content : rw L<Mojo::Content|SPVM::Mojo::Content>;>

Message content, defaults to a L<Mojo::Content::Single|SPVM::Mojo::Content::Single> object.

=head2 max_line_size

C<has max_line_size : rw int;>

Maximum start-line size in bytes, defaults to the value of the C<SPVM_MOJO_MAX_LINE_SIZE> environment variable or C<8192>
(8KiB).

=head2 max_message_size

C<has max_message_size : rw int;>

Maximum message size in bytes, defaults to the value of the C<SPVM_MOJO_MAX_MESSAGE_SIZE> environment variable or
C<16777216> (16MiB). Setting the value to C<0> will allow messages of indefinite size.

=head2 version

C<has version : rw string;>

HTTP version of message, defaults to C<1.1>.

=head1 Instance Methods

=head2 body

C<method body : string ();>

Slurp L</"content">.

=head2 set_body
  
C<method set_body : void ($body : string);>

Replace L</"content">.

=head2 body_params
  
C<method body_params : L<Mojo::Parameters|SPVM::Mojo::Parameters> ();>

C<POST> parameters extracted from C<application/x-www-form-urlencoded> or C<multipart/form-data> message body, usually
a L<Mojo::Parameters|SPVM::Mojo::Parameters> object. Note that this method caches all data, so it should not be called before the entire
message body has been received. Parts of the message body need to be loaded into memory to parse C<POST> parameters, so
you have to make sure it is not excessively large. There's a 16MiB limit for requests and a 2GiB limit for responses by
default.

  # Get POST parameter names and values
  my $hash = $msg->body_params->to_hash;

=head2 body_size
  
C<method body_size : int ();>

Content size in bytes.

=head2 build_body
  
C<method build_body : string ();>

Render whole body with L</"get_body_chunk">.

=head2 build_headers
  
C<method build_headers : string ();>

Render all headers with L</"get_header_chunk">.

=head2 build_start_line

C<method build_start_line : string ();>

Render start-line with L</"get_start_line_chunk">.

=head2 cookie

C<method cookie : L<Mojo::Cookie|SPVM::Mojo::Cookie> ($name : string);>

Access message cookies, usually L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request> or L<Mojo::Cookie::Response|SPVM::Mojo::Cookie::Response> objects. If there are multiple
cookies sharing the same name, and you want to access more than just the last one, you can use L</"every_cookie">. Note
that this method caches all data, so it should not be called before all headers have been received.

  # Get cookie value
  say $msg->cookie("foo")->value;

=head2 cookies

C<method cookies : L<Mojo::Cookie|SPVM::Mojo::Cookie>[] ();>

Access message cookies. Meant to be overloaded in a subclass.

=head2 every_cookie

C<method every_cookie : L<Mojo::Cookie|SPVM::Mojo::Cookie>[] ($name : string);>

Similar to L</"cookie">, but returns all message cookies sharing the same name as an array reference.

  # Get first cookie value
  say $msg->every_cookie("foo")->[0]->value;

=head2 every_upload

C<method every_upload : L<Mojo::Upload|SPVM::Mojo::Upload>[] ($name : string);>

Similar to L</"upload">, but returns all file uploads sharing the same name as an array reference.

  # Get content of first uploaded file
  say $msg->every_upload("foo")->[0]->asset->slurp;

=head2 extract_start_line

C<method extract_start_line : int ($str_ref : string[]);>

Extract start-line from string. Meant to be overloaded in a subclass.

=head2 finish

C<method finish : void ();>

=head2 fix_headers

Finish message parser/generator.

C<method fix_headers : void ();>

Make sure message has all required headers.

=head2 get_body_chunk

C<method get_body_chunk : string ($offset : int);>

Get a chunk of body data starting from a specific position. Note that it might not be possible to get the same chunk
twice if content was generated dynamically.

=head2 get_header_chunk

C<method get_header_chunk : string ($offset : int);>

Get a chunk of header data, starting from a specific position. Note that this method finalizes the message.

=head2 get_start_line_chunk

C<method get_start_line_chunk : string ($offset : int);>

Get a chunk of start-line data starting from a specific position. Meant to be overloaded in a subclass.

=head2 header_size

C<method header_size : int ();>

Size of headers in bytes. Note that this method finalizes the message.

=head2 headers
  
C<method headers : L<Mojo::Headers|SPVM::Mojo::Headers> ();>

Message headers, usually a L<Mojo::Headers|SPVM::Mojo::Headers> object.

  # Longer version
  my $headers = $msg->content->headers;

=head2 is_finished

C<method is_finished : int ();>

Check if message parser/generator is finished.

=head2 is_limit_exceeded

C<method is_limit_exceeded : int ();>

Check if message has exceeded L</"max_line_size">, L</"max_message_size">, L<Mojo::Content#max_buffer_size|SPVM::Mojo::Content/"max_buffer_size"> field or
L<Mojo::Headers#max_line_size|SPVM::Mojo::Headers/"max_line_size"> field.

=head2 json

C<method json : object ();>

Decode JSON message body directly using L<JSON|SPVM::JSON> if possible, an C<undef> return value indicates a bare C<null> or
that decoding failed.

Note that this method caches all data, so it should not be called before the entire message body has been received. The
whole message body needs to be loaded into memory to parse it, so you have to make sure it is not excessively large.
There's a 16MiB limit for requests and a 2GiB limit for responses by default.

  # Extract JSON values
  say $msg->json->(Hash)->get("foo")->(Hash)->get("bar")->(List)->get(23)->(string);

=head2 parse

C<method parse : void ($chunk : string);>

Parse message chunk.

=head2 save_to

C<method save_to : void ($path : string);>

Save message body to a file.

=head2 start_line_size

C<method start_line_size : int ();>

Size of the start-line in bytes. Meant to be overloaded in a subclass.

=head2 text
  
C<method text : string ();>

Retrieve L</"body">.

=head2 to_string
  
C<method to_string : string ();>

Render whole message. Note that this method finalizes the message, and that it might not be possible to render the same
message twice if content was generated dynamically.

=head2 upload
  
C<method upload : L<Mojo::Upload|SPVM::Mojo::Upload> ($name : string);>

Access C<multipart/form-data> file uploads, usually L<Mojo::Upload|SPVM::Mojo::Upload> objects. If there are multiple uploads sharing the
same name, and you want to access more than just the last one, you can use L</"every_upload">. Note that this method
caches all data, so it should not be called before the entire message body has been received.

  # Get content of uploaded file
  say $msg->upload("foo")->asset->slurp;

=head2 uploads

C<method uploads : L<Mojo::Upload|SPVM::Mojo::Upload>[] ();>

All C<multipart/form-data> file uploads, usually L<Mojo::Upload|SPVM::Mojo::Upload> objects.

  # Names of all uploads
  for my $_ (@{$msg->uploads}) {
    say $_->name;
  }

=head1 Well Known Child Classes

=over 2

=item * L<Mojo::Content::Request|SPVM::Mojo::Content::Request>

=item * L<Mojo::Content::Response|SPVM::Mojo::Content::Response>

=back

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
