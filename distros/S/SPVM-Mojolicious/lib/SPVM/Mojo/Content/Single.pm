package SPVM::Mojo::Content::Single;



1;

=head1 Name

SPVM::Mojo::Content::Single - HTTP content

=head1 Description

Mojo::Content::Single class in L<SPVM> is a container for HTTP content, based on L<RFC 7230|https://tools.ietf.org/html/rfc7230> and
L<RFC 7231|https://tools.ietf.org/html/rfc7231>.

=head1 Usage

  use Mojo::Content::Single;

  my $single = Mojo::Content::Single->new;
  $single->parse("Content-Length: 12\x0d\x0a\x0d\x0aHello World!");
  say $single->headers->content_length;

=head1 Super Class

L<Mojo::Content|SPVM::Mojo::Content>

=head1 Fields

=head2 asset

C<has asset : rw Mojo::Asset;>

The actual content, defaults to a L<Mojo::Asset::Memory|SPVM::Mojo::Asset::Memory> object with L<Mojo::Asset::Memory#auto_upgrade|SPVM::Mojo::Asset::Memory/"auto_upgrade"> enabled.

=head2 auto_upgrade

C<has auto_upgrade : rw byte;>

Try to detect multipart content and automatically upgrade to a L<Mojo::Content::MultiPart|SPVM::Mojo::Content::MultiPart> object, defaults to a true
value.

=head1 Class Methods

C<static method new : L<Mojo::Content::Single|SPVM::Mojo::Content::Single> ();>

Construct a new L<Mojo::Content::Single|SPVM::Mojo::Content::Single> object and subscribe to event L<Mojo::Content#read|SPVM::Mojo::Content/"read"> with default content
parser.

=head1 Instance Methods

=head2 body_contains

C<method body_contains : int ($chunk : string);>

Check if content contains a specific string.

=head2 body_size

C<method body_size : int ();>

Content size in bytes.

=head2 clone

C<method clone : L<Mojo::Content::Single|SPVM::Mojo::Content::Single> ();>

Return a new L<Mojo::Content::Single|SPVM::Mojo::Content::Single> object cloned from this content if possible, otherwise return C<undef>.

=head2 get_body_chunk

C<method get_body_chunk : string ($offset : int);>

Get a chunk of content starting from a specific position. Note that it might not be possible to get the same chunk
twice if content was generated dynamically.

=head2 parse

C<method parse : L<Mojo::Content|SPVM::Mojo::Content> ($chunk : string);>

Parse content chunk and upgrade to L<Mojo::Content::MultiPart|SPVM::Mojo::Content::MultiPart> object if necessary.

=head1 See Also

=over 2

=item * L<Mojo::Content|SPVM::Mojo::Content>

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
