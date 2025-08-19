package SPVM::Mojo::Content;



1;

=encoding utf8

=head1 Name

SPVM::Mojo::Content - HTTP content base class

=head1 Description

Mojo::Content class in L<SPVM> is an abstract base class for HTTP content containers, based on L<RFC
7230|https://tools.ietf.org/html/rfc7230> and L<RFC 7231|https://tools.ietf.org/html/rfc7231>, like
L<Mojo::Content::MultiPart|SPVM::Mojo::Content::MultiPart> and L<Mojo::Content::Single|SPVM::Mojo::Content::Single>.

=head1 Usage

  use Mojo::Content;

  class Mojo::Content::MyContent extends Mojo::Content {
    
  }

=head1 Super Class

L<Mojo::EventEmitter|SPVM::Mojo::EventEmitter>

=head1 Events

=head2 body

Emitted once all headers have been parsed and the body starts.

Examples:

  $content->on(body => method : void ($content : Mojo::Content) {
    if ($content->headers->header("X-No-MultiPart")) {
      $content->auto_upgrade(0);
    }
  });

=head2 drain

Emitted once all data has been written.

Examples:

  $content->on(drain => method : void ($content : Mojo::Content) {
    $content->write_chunk(Sys->time);
  });

=head2 read

Emitted when a new chunk of content arrives.

Examples:

  $content->on(read => method : void ($content : Mojo::Content, $bytes : string) {
    say "Streaming: $bytes";
  });

=head1 Fields

=head2 auto_decompress

C<has auto_decompress : rw byte;>

Decompress content automatically if L</"is_compressed"> is true.

=head2 auto_relax

C<has auto_relax : rw byte;>

Try to detect when relaxed parsing is necessary.

=head2 headers

C<has headers : rw Mojo::Headers;>

Content headers, defaults to a L<Mojo::Headers|SPVM::Mojo::Headers> object.

=head2 max_buffer_size

C<has max_buffer_size : rw int;>

Maximum size in bytes of buffer for content parser, defaults to the value of the C<SPVM_MOJO_MAX_BUFFER_SIZE> environment
variable or C<262144> (256KiB).

=head2 max_leftover_size

C<has max_leftover_size : rw int;>

Maximum size in bytes of buffer for pipelined HTTP requests, defaults to the value of the C<SPVM_MOJO_MAX_LEFTOVER_SIZE>
environment variable or C<262144> (256KiB).

=head2 relaxed

C<has relaxed : rw byte;>

Activate relaxed parsing for responses that are terminated with a connection close.

=head2 skip_body

C<has skip_body : rw byte;>

Skip body parsing and finish after headers.

=head1 Instance Methods

=head2 body_contains

C<method body_contains : int ($chunk : string);>

Check if content contains a specific string. Meant to be overloaded in a subclass.

=head2 body_size

C<method body_size : int ();>

Content size in bytes. Meant to be overloaded in a subclass.

=head2 boundary

C<method boundary : string ();>

Extract multipart boundary from C<Content-Type> header.

=head2 clone

C<method clone : L<Mojo::Content|SPVM::Mojo::Content> ();>

Return a new L<Mojo::Content|SPVM::Mojo::Content> object cloned from this content if possible, otherwise return C<undef>.

=head2 generate_body_chunk

C<method generate_body_chunk : string ($offset : int);>

Generate dynamic content.

=head2 get_body_chunk

C<method get_body_chunk : string ($offset : int);>

Get a chunk of content starting from a specific position. Meant to be overloaded in a subclass.

=head2 get_header_chunk

C<method get_header_chunk : string ($offset : int);>

Get a chunk of the headers starting from a specific position. Note that this method finalizes the content.

=head2 header_size

C<method header_size : int ();>

Size of headers in bytes. Note that this method finalizes the content.

=head2 headers_contain  

C<method headers_contain : int ($chunk : string);>

Check if headers contain a specific string. Note that this method finalizes the content.

=head2 is_chunked

C<method is_chunked : int ();>

Check if C<Transfer-Encoding> header indicates chunked transfer encoding.

=head2 is_compressed

C<method is_compressed : int ();>

Check C<Content-Encoding> header for C<gzip> value.

=head2 is_dynamic

C<method is_dynamic : int ();>

Check if content will be dynamically generated, which prevents L</"clone"> from working.

=head2 is_finished

C<method is_finished : int ();>

Check if parser is finished.

=head2 is_limit_exceeded

C<method is_limit_exceeded : int ();>

Check if buffer has exceeded L</"max_buffer_size">.

=head2 is_multipart

C<method is_multipart : int ();>

False, this is not a L<Mojo::Content::MultiPart> object.

=head2 is_parsing_body

C<method is_parsing_body : int ();>

Check if body parsing started yet.

=head2 is_sse

C<method is_sse : int ();>

Check if C<Content-Type> header indicates Server-Sent Events (SSE). Note that this method is B<EXPERIMENTAL> and may
change without warning!

=head2 leftovers

C<method leftovers : string ();>

Get leftover data from content parser.

=head2 parse

C<method parse : L<Mojo::Content|SPVM::Mojo::Content> ($chunk : string);>

Parse content chunk.

=head2 parse_body

C<method parse_body : void ($chunk : string);>

Parse body chunk and skip headers.

=head2 progress

C<method progress : int ();>

Size of content already received from message in bytes.

=head2 write

C<method write : void ($chunk : string, $cb : L<Mojo::EventEmitter::Callback|SPVM::Mojo::EventEmitter::Callback>);>

Write dynamic content non-blocking, the optional drain callback will be executed once all data has been written.
Calling this method without a chunk of data will finalize the L</"headers"> and allow for dynamic content to be written
later. You can write an empty chunk of data at any time to end the stream.

=head2 write_chunk  

C<method write_chunk : void ($chunk : string, $cb : L<Mojo::EventEmitter::Callback|SPVM::Mojo::EventEmitter::Callback>);>

Write dynamic content non-blocking with chunked transfer encoding, the optional drain callback will be executed once
all data has been written. Calling this method without a chunk of data will finalize the L</"headers"> and allow for
dynamic content to be written later. You can write an empty chunk of data at any time to end the stream.

=head2 write_sse

C<method write_sse : void ($event : L<Mojo::SSE::Event|SPVM::Mojo::SSE::Event>, $cb : L<Mojo::EventEmitter::Callback|SPVM::Mojo::EventEmitter::Callback>);>

Write Server-Sent Event (SSE) non-blocking, the optional drain callback will be executed once all data has been
written. Calling this method without an event will finalize the response headers and allow for events to be written
later. Note that this method is B<EXPERIMENTAL> and may change without warning!

=head1 Well Known Child Classes

=over 2

=item * L<Mojo::Content::MultiPart|SPVM::Mojo::Content::MultiPart>

=item * L<Mojo::Content::Single|SPVM::Mojo::Content::Single>

=back

=head1 See Also

=over 2

=item * L<Mojo::Headers|SPVM::Mojo::Headers>

=item * L<Mojo::Message|SPVM::Mojo::Message>

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
