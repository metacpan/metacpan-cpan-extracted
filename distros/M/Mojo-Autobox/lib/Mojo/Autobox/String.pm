package Mojo::Autobox::String;

use Mojo::Base -strict;

sub byte_stream {
  require Mojo::ByteStream;
  Mojo::ByteStream->new(shift);
}

*b = \&byte_stream;

sub dom {
  require Mojo::DOM;
  my $dom = Mojo::DOM->new(shift);
  return @_ ? $dom->find(@_) : $dom;
}

sub json {
  require Mojo::JSON;
  require Mojo::JSON::Pointer;
  my $data = Mojo::JSON::decode_json(shift);
  return @_ ? Mojo::JSON::Pointer->new($data)->get(shift) : $data;
}

*j = \&json;

sub url {
  require Mojo::URL;
  Mojo::URL->new(shift);
}

1;

=head1 NAME

Mojo::Autobox::String - Autobox string methods for Mojo::Autobox

=head1 SYNOPSIS

 use Mojo::Autobox;

 # "Trimmed"
 '  Trimmed  '->byte_stream->trim;

 # "Text"
 '<p>Text</p>'->dom->at('p')->text;

 # "world"
 '{"hello": "world"}'->json->{hello};
 
 # "anchor"
 'http://mysite.com/path#anchor'->url->fragment;

=head1 DESCRIPTION

String methods for L<Mojo::Autobox>.

=head1 METHODS

=head2 byte_stream

Returns an instance of L<Mojo::ByteStream>, constructed from the invocant string.

=head2 b

An alias for L</byte_stream>.

=head2 dom

Returns an instance of L<Mojo::DOM>, constructed from the invocant string.
Optionally takes a CSS3 selector which is passed to the L<Mojo::DOM> instance's L<find|Mojo::DOM/find> method.

=head2 json

Parses the invocant string as JSON using L<Mojo::JSON/decode_json> and returns the result.
Optionally takes a JSON pointer used to delve into the resulting structure using L<Mojo::JSON::Pointer>.

=head2 j

An alias for L</json>.

=head2 url

Returns an instance of L<Mojo::URL>, constructed from the invocant string.

