package SPVM::Mojo::Content::MultiPart;



1;

=head1 Name

SPVM::Mojo::Content::MultiPart - HTTP multipart content

=head1 Description

Mojo::Content::MultiPart class in L<SPVM> is a container for HTTP multipart content, based on L<RFC
7230|https://tools.ietf.org/html/rfc7230>, L<RFC 7231|https://tools.ietf.org/html/rfc7231> and L<RFC
2388|https://tools.ietf.org/html/rfc2388>.


=head1 Usage

  use Mojo::Content::MultiPart;

  my $multi = Mojo::Content::MultiPart->new;
  $multi->parse("Content-Type: multipart/mixed; boundary=---foobar");
  my $single = $multi->parts->[4];

=head1 Super Class

L<Mojo::Content|SPVM::Mojo::Content>

=head1 Events

=head2 part

Emitted when a new L<Mojo::Content::Single|SPVM::Mojo::Content::Single> part starts.

  $multi->on(part => method : void ($multi : Mojo::Content::MultiPart, $single : Mojo::Content::Single) {
    
  });

=head1 Fields

=head2 parts

C<has parts : L<Mojo::Content|SPVM::Mojo::Content>[];>

Content parts embedded in this multipart content, usually L<Mojo::Content::Single|SPVM::Mojo::Content::Single> objects.

=head1 Class Methods



=head1 Instance Methods
  
=head2 body_contains

C<method body_contains : int ($chunk : string);>

Check if content parts contain a specific string.

=head2 body_size

C<method body_size : int ();>

Content size in bytes.

=head2 build_boundary

C<method build_boundary : string ();>

Generate a suitable boundary for content and add it to C<Content-Type> header.

=head2 clone

C<method clone : L<Mojo::Content::MultiPart|SPVM::Mojo::Content::MultiPart> ();>

Return a new L<Mojo::Content::MultiPart|SPVM::Mojo::Content::MultiPart> object cloned from this content if possible, otherwise return C<undef>.

=head2 get_body_chunk

C<method get_body_chunk : string ($offset : int);>

Get a chunk of content starting from a specific position. Note that it might not be possible to get the same chunk
twice if content was generated dynamically.

=head2 is_multipart

C<method is_multipart : int ();>

True, this is a L<Mojo::Content::MultiPart|SPVM::Mojo::Content::MultiPart> object.

=head1 See Also

=over 2

=item * L<Mojo::Content::Single|SPVM::Mojo::Content::Single>

=item * L<Mojo::Content|SPVM::Mojo::Content>

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
