package Net::Curl::Parallel::Types;

=head1 NAME

Net::Curl::Parallel::Types - type constraints for Net::Curl::Parallel

=cut

use strictures 2;
use Type::Utils;
use Types::Standard -types;
use URI::Fast qw(uri);

use Type::Library
  -base,
  -declare => qw(
    Positive
    Natural
    Agent
    Method
    Uri
    Headers
    Content
    Request
  );

=head1 EXPORTED TYPES

Declared types may be exported individually or as a set with C<-all>.

  use Net::Curl::Parallel::Types -all;
  use Net::Curl::Parallel::Types qw(Agent Method);

=head2 Positive

A positive integer.

=cut

declare Positive, as Int & sub{ $_ > 0 };

=head2 Natural

A positive integer or zero.

=cut

declare Natural, as Int & sub{ $_ >= 0 };

=head2 Agent

An HTTP client agent string in the form C<Name/v1.23>.

=cut

declare Agent, as StrMatch[qr{^\S+/v\d+(?:\.\d+)$}];

=head2 Method

A supported HTTP method. Coercible from a matching lowercase name.

=cut

declare Method, as Enum[qw(GET POST HEAD PUT DELETE)];

coerce Method,
  from Enum[qw(get post head put delete)],
  via{ uc $_ };

=head2 Uri

A valid URI string. Automatically coerced from L<URI> and L<URI::Fast> objects.

=cut

declare Uri, as Str,
  where{
    my $uri = uri $_;
    return unless $uri->host;
    return 1;
  };

coerce Uri,
  from InstanceOf['URI'],
  via{ $_->as_string };

coerce Uri,
  from InstanceOf['URI::Fast'],
  via{ $_->to_string };

=head2 Headers

An array of strings, where each string is a header key/value pair separated by
a colon. Coercible from undef (to empty header set), array of string tuples
containing key/value pairs, a hash of key/value pairs, or an instance of
L<HTTP::Headers>.

=cut

declare Headers, as ArrayRef[StrMatch[qr/^\S+: .+$/]];

coerce Headers,
  from Undef,
  via{ [] };

coerce Headers,
  from Str,
  via{ [split qr/[\r\n]+/, $_] };

coerce Headers,
  from ArrayRef[Tuple[Str, Str]],
  via{ [map{ join ': ', @$_ } @$_] };

coerce Headers,
  from HashRef[Str],
  via{ my $h = $_; [map{ $_ . ': ' . $h->{$_} } keys %$h] };

coerce Headers,
  from InstanceOf['HTTP::Headers'],
  via{
    my $headers = $_;
    Headers->assert_coerce(
      [
        map{ [$_, $headers->header($_)] }
          $headers->header_field_names
      ]
    );
  };

=head2 Content

An optional string (C<Maybe[Str]>). Coercible from a hash ref of query
parameters or an array ref of key/value tuples to a url-encoded string. There
are no coercions or automatic url-encoding of binary data or other formats.

  {foo => 'bar bat'}               -> foo=bar%20bat
  {foo => ['bar', 'bat']}           -> foo=bar&foo=bat
  [['foo', 'bar bat']]              -> foo=bar%20bat
  [['foo', 'bar'], ['foo', 'bat']]  -> foo=bar&foo=bat

=cut

declare Content, as Maybe[Str & sub{ length $_ }];

coerce Content,
  from HashRef[Str | ArrayRef[Str]],
  via{
    my $uri = uri;
    $uri->query($_);
    scalar $uri->query;
  };

coerce Content,
  from ArrayRef[Tuple[Str, Str]],
  via{
    my $uri = uri;
    foreach (@$_) {
      my ($k, $v) = @$_;
      $uri->add_param($k, $v);
    }
    scalar $uri->query;
  };

coerce Content,
  from Enum[''],
  via{ undef };

=head2 Request

The supported request parameters accepted by L<Net::Curl::Parallel/add>, matching
the arguments to the constructor of L<HTTP::Request>. Coercible from an
instance of L<HTTP::Request>.

=cut

declare Request, as Tuple[Method, Uri, Headers, Content], coercion => 1;

coerce Request,
  from InstanceOf['HTTP::Request'],
  via {
    return [
      Method->assert_coerce($_->method),
      Uri->assert_coerce($_->uri),
      Headers->assert_coerce($_->headers),
      Content->assert_coerce($_->content),
    ];
  };

coerce Request,
  from ((~Request) & ArrayRef),
  via {
    return [
      Method->assert_coerce($_->[0]),
      Uri->assert_coerce($_->[1]),
      Headers->assert_coerce($_->[2]),
      Content->assert_coerce($_->[3]),
    ];
  };

1;
