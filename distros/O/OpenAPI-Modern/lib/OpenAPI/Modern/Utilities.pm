use strictures 2;
package OpenAPI::Modern::Utilities;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Internal utilities and common definitions for OpenAPI::Modern

our $VERSION = '0.149';

use 5.020;
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use File::ShareDir 'dist_dir';
use List::Util 1.45 qw(uniqstr pairs);
use Scalar::Util 'looks_like_number';
use Mojo::Util qw(url_unescape url_escape);
use Carp 'croak';
use if "$]" < 5.041010, 'List::Util' => 'any';
use if "$]" >= 5.041010, experimental => 'keyword_any';
use builtin::compat qw(blessed indexed);
use JSON::Schema::Modern::Utilities qw(register_schema load_cached_document true false match_media_type);
use namespace::clean;

use Exporter 'import';

our @EXPORT = qw(
  SUPPORTED_OAD_VERSIONS
  OAS_VERSIONS
  DEFAULT_DIALECT
  DEFAULT_BASE_METASCHEMA
  DEFAULT_METASCHEMA
  STRICT_METASCHEMA
  STRICT_DIALECT
  OAS_VOCABULARY
);

our @EXPORT_OK = qw(
  OAS_SCHEMAS
  MEDIA_RANGE_RE
  add_vocab_and_default_schemas
  add_formats
  convert_request
  convert_response
  uri_decode
  uri_encode
  uri_encode_strict
  intersect_types
  coerce_primitive
  is_header_name
  is_cookie_name
  is_cookie_value
  elem
  deserialize_multipart
);

our %EXPORT_TAGS = (
  constants => \@EXPORT,
);

# it is likely the case that we can support a version beyond what's stated here -- but we may not,
# so we'll warn to that effect. Every effort will be made to upgrade this implementation to fully
# support the latest point release as soon as possible.
use constant SUPPORTED_OAD_VERSIONS => [ '3.0.4', '3.1.2', '3.2.0' ];

# in most things, such as checking for compatibility, we only use major.minor as the version number
use constant OAS_VERSIONS => [ map s/^\d+\.\d+\K\.\d+\z//ar, SUPPORTED_OAD_VERSIONS->@* ];

# see https://spec.openapis.org/#openapi-specification-schemas for the latest links
# these are updated automatically at build time via 'update-schemas'

# the main OpenAPI document schema, with permissive (unvalidated) JSON Schemas
use constant DEFAULT_METASCHEMA => {
  '3.0' => 'https://spec.openapis.org/oas/3.0/schema/2024-10-18',
  '3.1' => 'https://spec.openapis.org/oas/3.1/schema/2025-11-23',
  '3.2' => 'https://spec.openapis.org/oas/3.2/schema/2026-08-30',
};

# metaschema for JSON Schemas contained within OpenAPI documents:
# standard JSON Schema (presently draft2020-12) + OpenAPI vocabulary
use constant DEFAULT_DIALECT => {
  '3.0' => DEFAULT_METASCHEMA->{'3.0'}.'#/definitions/Schema',
  '3.1' => 'https://spec.openapis.org/oas/3.1/dialect/2024-11-10',
  '3.2' => 'https://spec.openapis.org/oas/3.2/dialect/2026-02-26',
};

# OpenAPI document schema that forces the use of the JSON Schema dialect (no $schema overrides
# permitted)
use constant DEFAULT_BASE_METASCHEMA => {
  '3.0' => 'https://spec.openapis.org/oas/3.0/schema/2024-10-18', # same as standard
  '3.1' => 'https://spec.openapis.org/oas/3.1/schema-base/2025-11-23',
  '3.2' => 'https://spec.openapis.org/oas/3.2/schema-base/2026-08-30',
};

# OpenAPI vocabulary definition
use constant OAS_VOCABULARY => {
  '3.1' => 'https://spec.openapis.org/oas/3.1/meta/2024-11-10',
  '3.2' => 'https://spec.openapis.org/oas/3.2/meta/2026-02-26',
};

# an OpenAPI schema and JSON Schema dialect which prohibit unknown keywords
use constant STRICT_METASCHEMA => {
  '3.1' => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/3.1/strict-schema.json',
  '3.2' => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/3.2/strict-schema.json',
};

use constant STRICT_DIALECT => {
  '3.1' => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/3.1/strict-dialect.json',
  '3.2' => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/3.2/strict-dialect.json',
};

# <uri> => <local filename> (under share/) - for internal use only!
use constant _BUNDLED_SCHEMAS => {
  map +(
    DEFAULT_METASCHEMA->{$_}        => 'oas/'.$_.'/schema.json',
    $_ eq '3.0' ? () : (
      DEFAULT_DIALECT->{$_}         => 'oas/'.$_.'/dialect.json',
      DEFAULT_BASE_METASCHEMA->{$_} => 'oas/'.$_.'/schema-base.json',
      OAS_VOCABULARY->{$_}          => 'oas/'.$_.'/vocabulary.json',
      STRICT_METASCHEMA->{$_}       => $_.'/strict-schema.json',
      STRICT_DIALECT->{$_}          => $_.'/strict-dialect.json',
    )
  ), OAS_VERSIONS->@*
};

# these are all loadable on demand, via JSON::Schema::Modern::load_cached_document,
# and also made available as s/<date>/latest/
# { <oas version> => [ <uri>, <uri>, .. ]
use constant OAS_SCHEMAS => {
  map do {
    my $version = $_;
    $version => [ grep m{/oas/$version/}, keys _BUNDLED_SCHEMAS->%* ]
  }, OAS_VERSIONS->@*
};

my ($OWS, $TOKEN, $QUOTED_STRING);
BEGIN {
  # see RFC9110 §8.3.1: ABNF "OWS": HT SP
  $OWS = q{[\x09\x20]*};

  # see RFC9110 §5.6.2: ABNF "token" (identical to RFC2616 §2.2 "token")
  $TOKEN = q{(?a:[[:alnum:]!#$%&'*+.^_`|~-]+)};

  # see RFC9110 §5.6.6: ABNF "quoted-string"
  # quoted-string  = DQUOTE *( qdtext / quoted-pair ) DQUOTE
  # qdtext         = HTAB / SP / %x21 / %x23-5B / %x5D-7E / obs-text ; everything but: " \ DEL
  # quoted-pair    = "\" ( HTAB / SP / VCHAR / obs-text )
  $QUOTED_STRING = q{"((?:[\x09\x20\x21\x23-\x5B\x5D-\x7E\x80-\xFF]|\x5C[\x09\x20-\x7E\x80-\xFF])*)"};
}

# note: unanchored!
use constant MEDIA_RANGE_RE => "$TOKEN/$TOKEN(?:$OWS;$OWS$TOKEN=(?:$TOKEN|$QUOTED_STRING))*";

sub add_vocab_and_default_schemas ($evaluator, $version = OAS_VERSIONS->[-1]) {
  return if ($evaluator->{__openapi_vocabs_loaded}//={})->{$version}++;

  $evaluator->add_vocabulary('JSON::Schema::Modern::Vocabulary::OpenAPI');

  foreach my $uri (OAS_SCHEMAS->{$version}->@*) {
    my $document = load_cached_document($evaluator, $uri);

    # add "latest" alias for each of these documents, mapping to the same document object
    $evaluator->add_document(($document->canonical_uri =~ s{/\d{4}-\d{2}-\d{2}\z}{}ar).'/latest', $document);
  }
}

sub add_formats ($evaluator, $version = OAS_VERSIONS->[-1]) {
  return if ($evaluator->{__openapi_formats_loaded}//={})->{$version}++;

  $evaluator->add_format_validation(int32 => +{
    type => 'number',
    sub => sub ($x) {
      require Math::BigInt; Math::BigInt->VERSION(1.999701);
      $x = Math::BigInt->new($x);
      return if $x->is_nan;
      my $bound = Math::BigInt->new(2) ** 31;
      $x >= -$bound && $x < $bound;
    }
  }) if not $evaluator->_get_format_validation('int32');

  $evaluator->add_format_validation(int64 => +{
    type => 'number',
    sub => sub ($x) {
      require Math::BigInt; Math::BigInt->VERSION(1.999701);
      $x = Math::BigInt->new($x);
      return if $x->is_nan;
      my $bound = Math::BigInt->new(2) ** 63;
      $x >= -$bound && $x < $bound;
    }
  }) if not $evaluator->_get_format_validation('int64');

  $evaluator->add_format_validation(float => +{ type => 'number', sub => sub ($x) { 1 } })
    if not $evaluator->_get_format_validation('float');
  $evaluator->add_format_validation(double => +{ type => 'number', sub => sub ($x) { 1 } })
    if not $evaluator->_get_format_validation('double');
  $evaluator->add_format_validation(password => +{ type => 'string', sub => sub ($) { 1 } })
    if not $evaluator->_get_format_validation('password');

  $evaluator->add_format_validation('media-range' => +{
    type => 'string',
    sub => sub ($x) {
      # see RFC9110 §12.5.1: ABNF "media-range", RFC9110 §8.3.1: ABNF "media-type"
      return 0+!!($x =~ ('^'.MEDIA_RANGE_RE.'\z'));
    },
  }) if not $evaluator->_get_format_validation('media-range');
}

# generates the equivalent Mojo::Message::Request from any of:
# - HTTP::Request
# - Plack::Request
# - Catalyst::Request
# - Dancer2::Core::Request
# results may be unsatisfactory if not a valid HTTP request.
sub convert_request ($request) {
  return $request if $request->isa('Mojo::Message::Request');

  my $req = Mojo::Message::Request->new;

  if ($request->isa('HTTP::Request')) {
    $req->method($request->method);
    $req->url(Mojo::URL->new($request->uri));
    $req->version($request->protocol =~ s{^HTTP/(\d\.\d)\z}{$1}ar) if $request->protocol;
    # remember, if you're constructing $body manually, you need to =~ s/\n/\r\n/g;
    my $body = $request->content;

    if (match_media_type(scalar $request->content_type, ['multipart/*'])) {
      $req->content(Mojo::Content::MultiPart->new);
      $req->headers->add(@$_) foreach pairs $request->headers->flatten;
      $req->content->emit(read => $body);
    }
    else {
      $req->headers->add(@$_) foreach pairs $request->headers->flatten;
      $req->body($body) if length $body;
    }
  }
  # note: Dancer2::Core::Request inherits from Plack::Request
  elsif ($request->isa('Plack::Request') or $request->isa('Catalyst::Request')) {
    # make $request->content work
    $request = do { +require Plack::Request; Plack::Request->new($request->env) }
      if not $request->isa('Plack::Request');

    if (match_media_type($request->content_type, ['multipart/*'])) {
      $req->content(Mojo::Content::MultiPart->new);
      $req->parse($request->env);
      $req->content->emit(read => $request->content);
    }
    else {
      $req->parse($request->env); # parsing psgi.input alters it; must read content afterwards
      my $body = $request->content;
      $req->body($body) if length $body;
    }

    # Plack is unable to distinguish between %2F and /, so the raw (undecoded) uri can be passed
    # here. see PSGI::FAQ
    $req->url(Mojo::URL->new($request->env->{REQUEST_URI})) if exists $request->env->{REQUEST_URI};
  }
  else {
    return $req->error({ message => 'unknown type '.ref($request) });
  }

  # we could call $req->fix_headers here to add a missing Content-Length or Host, but proper
  # requests from the network should always have these set.

  $req->finish;
  return $req;
}

# generates the equivalent Mojo::Message::Response from any of:
# - HTTP::Response
# - Plack::Response
# - Catalyst::Response
# - Dancer2::Core::Response
# results may be unsatisfactory if not a valid HTTP response.
sub convert_response ($response) {
  return $response if $response->isa('Mojo::Message::Response');

  my $res = Mojo::Message::Response->new;

  my (@headers, $body);
  if ($response->isa('HTTP::Response')) {
    $res->code($response->code);
    $res->version($response->protocol =~ s{^HTTP/(\d\.\d)\z}{$1}ar) if $response->protocol;
    @headers = pairs $response->headers->flatten;
    $body = $response->content;
  }
  elsif ($response->isa('Plack::Response') or $response->isa('Dancer2::Core::Response')) {
    $res->code($response->status);
    @headers = pairs $response->headers->psgi_flatten_without_sort->@*;
    $body = $response->content;
  }
  elsif ($response->isa('Catalyst::Response')) {
    $res->code($response->status);
    HTTP::Headers->VERSION('6.07');
    @headers = pairs $response->headers->flatten;
    $body = $response->body;
  }
  else {
    return $res->error({ message => 'unknown type '.ref($response) });
  }

  if (match_media_type(scalar $response->content_type, ['multipart/*'])) {
    $res->content(Mojo::Content::MultiPart->new);
    $res->headers->add(@$_) foreach @headers;
    $res->content->emit(read => $body);
  }
  else {
    $res->headers->add(@$_) foreach @headers;
    $res->body($body) if length $body;
  }

  # we could call $res->fix_headers here to add a missing Content-Length, but proper responses from
  # the network should always have it set.

  $res->finish;
  return $res;
}

# url-percent-decode and UTF-8-decode a string
sub uri_decode ($str) {
  Encode::decode('UTF-8', url_unescape($str), Encode::DIE_ON_ERR);
}

# UTF-8-encode and url-percent-encode a string (only encoding characters that MUST be encoded)
sub uri_encode ($str) {
  url_escape(Encode::encode('UTF-8', $str, Encode::DIE_ON_ERR), '^A-Za-z0-9\-._~!$&\'()*+,;=:@');
}

# UTF-8-encode and url-percent-encode a string (encoding all of reserved, gen-delims and sub-delims)
sub uri_encode_strict ($str) {
  url_escape(Encode::encode('UTF-8', $str, Encode::DIE_ON_ERR));
}

# find the intersection of all the lists, number and integer as equivalent
sub intersect_types (@lol) {
  my $count = @lol;
  my %vals;
  while (my $list = shift @lol) {
    ++$vals{$_} foreach uniqstr map +($_ eq 'integer' ? 'number' : $_), @$list;
  }

  return grep $vals{$_} == $count, keys %vals;
}

# Given a reference to a string or number, coerce it to the best-matching primitive in the allowed
# list other than object and array (which must be deserialized according to style rules first)
# The core types are: (array, object, null, boolean, string, number)
# Returns validity status, allowing the caller to fall back to the original value or generate an error.
sub coerce_primitive ($dataref, $types = []) {
  return if not @$types;            # no type specified; indicate failure
  return if not defined $$dataref;  # null is an error
  return if ref $$dataref;          # booleans, arrays, objects are errors

  my $data = $$dataref; # make copy to avoid unwanted mutation of the original

  $$dataref = undef, return 1 if $data eq '' and elem('null', $types);

  if (elem('boolean', $types)) {
    $$dataref = false, return 1 if $data eq '0' or $data eq 'false' or $data eq '';
    $$dataref = true, return 1 if $data eq '1' or $data eq 'true';
  }

  $$dataref = 0+$$dataref, return 1 if elem('number', $types) and looks_like_number($$dataref);

  $$dataref = ''.$$dataref, return 1 if elem('string', $types);
}


# RFC9110 §5.1
# field-name     = token
sub is_header_name ($name) {
  !!(defined $name && $name =~ /^$TOKEN\z/);
}

# RFC6265 §3.1 and §4.2.1
# cookie-header = "Cookie:" OWS cookie-string OWS
# cookie-string = cookie-pair *( ";" SP cookie-pair )
# cookie-pair   = cookie-name "=" cookie-value
# cookie-name   = token                                         ; (defined in RFC2616 §2.2)
# cookie-value  = *cookie-octet / ( DQUOTE *cookie-octet DQUOTE )
# cookie-octet  = %x21 / %x23-2B / %x2D-3A / %x3C-5B / %x5D-7E  ; US-ASCII characters excluding
#                                   ; CTLs, whitespace, DQUOTE, comma, semicolon, and backslash

sub is_cookie_name ($name) {
  !!(defined $name && $name =~ /^$TOKEN\z/);
}

sub is_cookie_value ($value) {
  !!(defined $value && $value =~ /^("?)[\x21\x23-\x2B\x2D-\x3A\x3C-\x5B\x5D-\x7E]*\1\z/);
}

# are any $items a member of $set?
sub elem ($items, $set) {
  croak 'set is not an array' if ref $set ne 'ARRAY';
  $items = [ $items ] if ref $items ne 'ARRAY';

  any {
    my $item = $_;
    any { defined $item ? (defined $_ && $item eq $_) : (!defined $_) } @$set
  }
  @$items;
}

# Operates on a Mojo::Content object; returns two values:
# - all parts as an arrayref of objects:
#   for multipart/form-data: [ { $name => $value }, { ... }, ]
#   for other multipart/*:   [ $value1, $value2, ... ]
# - headers for each part as an arrayref of objects:
#   [ { $header1 => $value, $header2 => $value, ... }, { ... }, ... ]
# Operates recursively; parts within parts are also deserialized.
# Strings are not decoded with charset here, but individual fields' Content-Type are included so
# that can be done afterwards (or correlated with an encoding object)
# Based loosely on Mojo::Message::_parse_formdata
sub deserialize_multipart ($content) {
  die 'body is not multipart' if not blessed $content or not $content->is_multipart;

  my (@content, @headers);
  my $is_form = match_media_type($content->headers->content_type, ['multipart/form-data']);

  my $part_num = 0;
  foreach my $part ($content->parts->@*) {
    my $headers = $part->headers->to_hash('multi');
    $headers = +{ map +($_ => ($headers->{$_}->@* == 1 ? $headers->{$_}[0] : $headers->{$_} )),
      keys $headers->%* };

    my $value;
    if ($part->is_multipart) {
      ($value, my $new_headers) = deserialize_multipart($part);
      # new_headers is an arrayref... copy into the $headers hash with array indices as hash keys
      $headers = { %$headers, indexed $new_headers->@* };
    }
    else {
      $value = $part->asset->slurp;
    }

    if ($is_form) {
      my $disposition = $part->headers->content_disposition;
      die 'missing Content-Disposition' if not defined $disposition;

      # see ABNF at RFC2183 §2 (RFC6266 does not apply to multipart/form-data bodies)
      my ($disposition_type) = ($disposition =~ /^($TOKEN)/);
      next if $disposition_type ne 'form-data';

      pos($disposition) = length $&;
      my $leftovers = $';
      my $params = {};
      while ($disposition =~ /\G$OWS;$OWS($TOKEN)=($TOKEN|$QUOTED_STRING)/g) {
        my ($param_name, $value, $qs_value) = ($1, $2, $3);    # $QUOTED_STRING contains $3
        $leftovers = $';
        # RFC9110 §5.6.4: "The backslash octet ("\") can be used as a single-octet quoting mechanism
        # within quoted-string and comment constructs. Recipients that process the value of a
        # quoted-string MUST handle a quoted-pair as if it were replaced by the octet following the
        # backslash."
        $params->{$param_name} = Encode::decode('UTF-8',
          defined $qs_value ? ($qs_value =~ s/\x5C(.)/$1/gr) : $value,
          Encode::DIE_ON_ERR | Encode::LEAVE_SRC);
      }

      next if length $leftovers;
      $value = { $params->{name} // 'part_'.$part_num => $value };
    }

    $part_num++;
    push @content, $value;
    push @headers, $headers;
  }

  # remove empty header entries
  my $seen_header;
  foreach my $idx (reverse 0..$#headers) {
    $seen_header++, last if keys $headers[$idx]->%*;
    delete $headers[$idx];
  }

  return (\@content, \@headers);
}

{
  # make all bundled schemas available via JSON::Schema::Modern::load_cached_document
  my $share_dir = dist_dir('OpenAPI-Modern');
  foreach my $uri (keys _BUNDLED_SCHEMAS->%*) {
    register_schema($uri, $share_dir.'/'._BUNDLED_SCHEMAS->{$uri});
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenAPI::Modern::Utilities - Internal utilities and common definitions for OpenAPI::Modern

=head1 VERSION

version 0.149

I use a linearly-increasing version numbering scheme. No meaning should be
presumed or inferred from the version being less than 1.0.

=head1 SYNOPSIS

  use OpenAPI::Modern::Utilities;

=head1 DESCRIPTION

This class contains common definitions and internal utilities to be used by L<OpenAPI::Modern>.

=for Pod::Coverage DEFAULT_BASE_METASCHEMA
DEFAULT_DIALECT
DEFAULT_METASCHEMA
OAS_SCHEMAS
MEDIA_RANGE_RE
OAS_VERSIONS
OAS_VOCABULARY
STRICT_DIALECT
STRICT_METASCHEMA
SUPPORTED_OAD_VERSIONS
add_vocab_and_default_schemas
add_formats
convert_request
convert_response
uri_decode
uri_encode
uri_encode_strict
intersect_types
coerce_primitive
is_header_name
is_cookie_name
is_cookie_value
elem
deserialize_multipart

The constant values are updated automatically by C<update-schemas>, in the root of this distribution.

=head1 GIVING THANKS

=for stopwords MetaCPAN GitHub

If you found this module to be useful, please show your appreciation by
adding a +1 in L<MetaCPAN|https://metacpan.org/dist/OpenAPI-Modern>
and a star in L<GitHub|https://github.com/karenetheridge/OpenAPI-Modern>.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/OpenAPI-Modern/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=for stopwords OpenAPI

You can also find me on the L<JSON Schema Slack server|https://json-schema.slack.com> and L<OpenAPI
Slack server|https://open-api.slack.com>, which are also great resources for finding help.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Some schema files have their own licence, in share/oas/LICENSE.

=cut
