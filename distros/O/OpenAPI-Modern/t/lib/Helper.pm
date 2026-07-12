# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
# no package, so things defined here appear in the namespace of the parent.
use strictures 2;
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test2::V0 qw(!bag !bool !warnings !subtest), -no_pragmas => 1;  # prefer Test::Deep and Test2::Warnings versions of these exports
use if $ENV{AUTHOR_TESTING}, 'Test2::Warnings', ':report_warnings';
sub subtest { Test2::V0::subtest(@_); bail_if_not_passing() if $ENV{AUTHOR_TESTING}; }
use if $ENV{AUTHOR_TESTING} || -d '.git', 'Test2::Plugin::SubtestFilter';
use List::Util qw(pairs pairgrep pairmap);
use Mojo::Message::Request;
use Mojo::Message::Response;
use Carp 'croak';
use Test::Needs;
use Test::Deep qw(!array !hash); # import symbols: ignore, re etc
use Test2::API 'context_do';
use Test::File::ShareDir -share => { -dist => { 'OpenAPI-Modern' => 'share' } };
use JSON::Schema::Modern::Document::OpenAPI;
use JSON::Schema::Modern::Utilities 0.628 qw(true false);
use OpenAPI::Modern;
use OpenAPI::Modern::Utilities qw(:constants elem);
use YAML::PP 0.005;

use constant OAS_VOCABULARIES => [ map 'JSON::Schema::Modern::Vocabulary::'.$_,
  qw(Core Applicator Validation FormatAnnotation Content MetaData Unevaluated OpenAPI) ];

# the default to use for the "openapi" property in tests, when we don't care much about the specific
# version
use constant OAD_VERSION => SUPPORTED_OAD_VERSIONS->[-1];

# the default version, but major.minor only: for hash lookup in constants
use constant OAS_VERSION => OAS_VERSIONS->[-1];

use constant OPENAPI_PREAMBLE => <<"YAML";
---
openapi: ${\ OAD_VERSION }
info:
  title: Test API
  version: 1.2.3
YAML

# type can be
# 'mojo': classes of type Mojo::URL, Mojo::Headers, Mojo::Message::Request, Mojo::Message::Response
# 'lwp': classes of type URI, HTTP::Headers, HTTP::Request, HTTP::Response
# 'plack': classes of type Plack::Request, Plack::Response
# 'catalyst': classes of type Catalyst::Request, Catalyst::Response
# 'dancer2': classes of type Dancer2::Core::Request, Dancer2::Core::Response
our @TYPES = $ENV{TYPE} ? split(/,/, $ENV{TYPE}) : qw(mojo lwp plack catalyst dancer2);
our $TYPE = $ENV{TYPE} ? (split(/,/, $ENV{TYPE}))[0] : 'mojo'; # safe default

# Note: if you want your query parameters or uri fragment to be normalized, set them afterwards
# body_content can be a reference; the Content-Type header is used to determine the encoding format:
# see _generate_body
sub request ($method, $uri_string, $headers = [], $body_content = undef) {
  die '$TYPE is not set at ', join(' line ', (caller)[1,2]), ".\n" if not defined $TYPE;
  die 'Wide character in body content at ', join(' line ', (caller)[1,2]), ".\n"
    if not ref $body_content and length $body_content and $body_content =~ /[^\x00-\xff]/;

  ($headers, $body_content) = _generate_body($headers, $body_content) if ref $body_content;

  my $req;
  if (elem($TYPE, [qw(lwp plack catalyst dancer2)])) {
    test_needs('HTTP::Request', 'URI');

    my $uri = URI->new($uri_string);
    my $host = $uri->can('host') && $uri->host;
    $req = HTTP::Request->new($method => $uri, [], $body_content);
    $req->headers->push_header(@$_) foreach pairs @$headers, $host ? (Host => $host) : ();
    $req->headers->header('Content-Length' => length($body_content))
      if defined $body_content and not defined $req->headers->header('Content-Length')
        and not defined $req->headers->header('Transfer-Encoding');
    $req->protocol('HTTP/1.1'); # required, but not added by HTTP::Request constructor

    if (elem($TYPE, [qw(plack catalyst dancer2)])) {
      test_needs('Plack::Request', 'HTTP::Message::PSGI', { 'HTTP::Headers::Fast' => 0.21 });
      die 'HTTP::Headers::Fast::XS is buggy and should not be used' if eval { HTTP::Headers::Fast::XS->VERSION };

      $req = Plack::Request->new($req->to_psgi);

      # Plack is unable to distinguish between %2F and /, so the raw (undecoded) uri can be passed
      # here. see PSGI::FAQ
      $req->env->{REQUEST_URI} = $uri . '';
      $req->env->{'psgi.url_scheme'} = $uri->scheme;
    }

    if ($TYPE eq 'catalyst') {
      test_needs('Catalyst::Request', 'Catalyst::Log');

      $req = Catalyst::Request->new(
        _log => Catalyst::Log->new,
        method => $method,
        uri => $uri,
        env => $req->env, # $req was Plack::Request
      );
    }
    elsif ($TYPE eq 'dancer2') {
      test_needs('Dancer2::Core::Request');
      $req = Dancer2::Core::Request->new(env => $req->env);
    }
  }
  elsif ($TYPE eq 'mojo') {
    $req = Mojo::Message::Request->new(method => $method, url => Mojo::URL->new($uri_string));
    $req->headers->add(@$_) foreach pairs @$headers;
    $req->body($body_content) if defined $body_content;

    # add missing Content-Length, etc
    $req->fix_headers;
  }
  else {
    die '$TYPE '.$TYPE.' not supported at ', join(' line ', (caller)[1,2]), ".\n";
  }

  return $req;
}

# body_content can be a reference; the Content-Type header is used to determine the encoding format:
# see _generate_body
sub response ($code, $headers = [], $body_content = undef) {
  die '$TYPE is not set at ', join(' line ', (caller)[1,2]), ".\n" if not defined $TYPE;
  die 'Wide character in body content at ', join(' line ', (caller)[1,2]), ".\n"
    if not ref $body_content and length $body_content and $body_content =~ /[^\x00-\xff]/;

  ($headers, $body_content) = _generate_body($headers, $body_content) if ref $body_content;

  my $res;
  if ($TYPE eq 'mojo') {
    $res = Mojo::Message::Response->new(code => $code);
    $res->headers->add(@$_) foreach pairs @$headers;
    $res->body($body_content) if defined $body_content;

    # add missing Content-Length, etc
    $res->fix_headers;
  }
  elsif ($TYPE eq 'lwp') {
    test_needs('HTTP::Response', 'HTTP::Status');

    $res = HTTP::Response->new($code, HTTP::Status::status_message($code), $headers, $body_content);
    $res->protocol('HTTP/1.1'); # not added by HTTP::Response constructor
  }
  elsif ($TYPE eq 'plack') {
    test_needs('Plack::Response', 'HTTP::Message::PSGI', { 'HTTP::Headers::Fast' => 0.21 });
    die 'HTTP::Headers::Fast::XS is buggy and should not be used' if eval { HTTP::Headers::Fast::XS->VERSION };

    $res = Plack::Response->new($code, $headers, $body_content);
  }
  elsif ($TYPE eq 'catalyst') {
    test_needs('Catalyst::Response', { 'HTTP::Headers' => '6.07' });

    $res = Catalyst::Response->new(status => $code, body => $body_content);
    $res->headers->push_header(@$_) foreach pairs @$headers;
  }
  elsif ($TYPE eq 'dancer2') {
    test_needs('Dancer2::Core::Response', 'HTTP::Message::PSGI', { 'HTTP::Headers::Fast' => 0.21 });
    die 'HTTP::Headers::Fast::XS is buggy and should not be used' if eval { HTTP::Headers::Fast::XS->VERSION };

    $res = Dancer2::Core::Response->new(
      status => $code,
      headers => $headers,
      defined $body_content ? (content => $body_content) : (),
    );
  }
  else {
    die '$TYPE '.$TYPE.' not supported at ', join(' line ', (caller)[1,2]), ".\n";
  }

  if ($TYPE eq 'lwp' or $TYPE eq 'plack' or $TYPE eq 'catalyst' or $TYPE eq 'dancer2') {
    $res->headers->header('Content-Length' => length $body_content)
      if defined $body_content
        and not defined $res->headers->header('Content-Length')
        and not defined $res->headers->header('Transfer-Encoding');
  }

  return $res;
}

sub uri ($uri_string, @path_parts) {
  die '$TYPE is not set at ', join(' line ', (caller)[1,2]), ".\n" if not defined $TYPE;

  my $uri;
  if (elem($TYPE, [qw(lwp plack catalyst dancer2)])) {
    test_needs('URI');
    $uri = URI->new($uri_string);
    $uri->path_segments(@path_parts) if @path_parts;
  }
  elsif ($TYPE eq 'mojo') {
    $uri = Mojo::URL->new($uri_string);
    $uri->path->parts(\@path_parts) if @path_parts;
  }
  else {
    die '$TYPE '.$TYPE.' not supported at ', join(' line ', (caller)[1,2]), ".\n";
  }

  return $uri;
}

# sets query parameters on the request
sub query_params ($request, $pairs) {
  die '$TYPE is not set at ', join(' line ', (caller)[1,2]), ".\n" if not defined $TYPE;

  my $uri;
  if ($TYPE eq 'lwp') {
    $request->uri->query_form($pairs);
  }
  elsif ($TYPE eq 'mojo') {
    $request->url->query->pairs($pairs);
  }
  elsif (elem($TYPE, [qw(plack catalyst dancer2)])) {
    # this is the encoded query string portion of the URI
    $request->env->{QUERY_STRING} = Mojo::Parameters->new->pairs($pairs)->to_string;
    $request->env->{REQUEST_URI} .= '?' . $request->env->{QUERY_STRING};
    $request->uri->query($request->env->{QUERY_STRING}) if $TYPE eq 'catalyst';
    # $request->_clear_parameters if $TYPE eq 'catalyst';  # might need this later
  }
  else {
    die '$TYPE '.$TYPE.' not supported at ', join(' line ', (caller)[1,2]), ".\n";
  }

  return $uri;
}

sub remove_header ($message, $header_name) {
  die '$TYPE is not set at ', join(' line ', (caller)[1,2]), ".\n" if not defined $TYPE;

  if ($TYPE eq 'lwp') {
    $message->headers->remove_header($header_name);
  }
  elsif ($TYPE eq 'mojo') {
    $message->headers->remove($header_name);
  }
  elsif (elem($TYPE, [qw(plack catalyst dancer2)])) {
    $message->headers->remove_header($header_name);
    delete $message->env->{uc $header_name =~ s/-/_/r} if $message->can('env');
  }
  else {
    die '$TYPE '.$TYPE.' not supported at ', join(' line ', (caller)[1,2]), ".\n";
  }
}

sub _generate_body ($headers, $body_content) {
  my (undef, $content_type) = pairgrep { $a eq 'Content-Type' } @$headers;

  die 'missing Content-Type header' if not defined $content_type;

  if ($content_type eq 'application/x-www-form-urlencoded') {
    $body_content = _form_urlencoded_content($body_content);
  }
  else {
    die 'unsupported Content-Type '.$content_type;
  }

  return ($headers, $body_content);
}

# Accepts a form specification as either:
# - a hashref of names and values: { name1 => value1, name2 => [ value2, value3 ], ... },
# - or an arrayref of pairs (which preserves order):
#   [ name1 => value1, name2 => value2, name2 => value3, ... ]
# Values can also be a form specification, to permit nesting forms (with limitations:
# an arrayref for a nested form cannot be used inside a hashref)
# ideally, this output would be deserialized back to the same input.
sub _form_urlencoded_content ($body_content) {
    ref $body_content eq 'ARRAY' ? Mojo::Parameters->new->pairs([
      pairmap { $a, (ref $b ? _form_urlencoded_content($b) : $b) } $body_content->@*
    ])->to_string
  : ref $body_content eq 'HASH'
  ? Mojo::Parameters->new->pairs([
    pairmap {
        ref $b eq 'HASH' ? ($a => _form_urlencoded_content($b))
      : ref $b eq 'ARRAY' ? (map +($a => $_), $b->@*) : ($a, $b) } $body_content->%*
  ])->to_string

  : die 'unknown ref type';
}

# prints the method and URI of the request, or the response code and message of the response,
# or the method and URI of the two-element hash
sub to_str (@args) {
  if (@args > 1) {
    my %hash = @args;
    return $hash{method}.' '.$hash{uri};
  }

  my ($message) = @args;

  if ($message->isa('Mojo::Message::Request') or $message->isa('HTTP::Request')) {
    return $message->method.' '.$message->url;
  }
  elsif ($message->isa('Plack::Request') or $message->isa('Catalyst::Request')) {
    return $message->method.' '.$message->uri;
  }
  if ($message->isa('Mojo::Message::Response')) {
    return $message->code.' '.($message->message//$message->default_message);
  }
  elsif ($message->isa('HTTP::Response')) {
    return $message->code.' '.$message->message;
  }
  elsif ($message->isa('Plack::Response') or $message->isa('Catalyst::Response')) {
    return $message->status.' '.HTTP::Status::status_message($message->status);
  }

  die 'unrecognized type ', ref $message, ' at ', join(' line ', (caller)[1,2]), ".\n";
}

# create a Result object out of the document errors; suitable for stringifying
# as the OpenAPI::Modern constructor might do.
sub document_result ($document) {
  JSON::Schema::Modern::Result->new(
    valid => !$document->has_errors,
    errors => [ $document->errors ],
  );
}

our $encoder = JSON::Schema::Modern::_JSON_BACKEND()->new
  ->allow_nonref(1)
  ->utf8(0)
  ->allow_bignum(1)
  ->allow_blessed(1)
  ->convert_blessed(1)
  ->canonical(1)
  ->pretty(1)
  ->space_before(0)
  ->indent_length(2);

our $dumper = JSON::Schema::Modern::_JSON_BACKEND()->new
  ->allow_nonref(1)
  ->utf8(0)
  ->allow_bignum(1)
  ->allow_blessed(1)
  ->convert_blessed(1)
  ->canonical(1);

*UNIVERSAL::TO_JSON = sub ($obj) { $obj.'' };
*Mojo::Message::Request::TO_JSON = sub ($obj) { $obj->to_string };
*Mojo::Message::Response::TO_JSON = sub ($obj) { $obj->to_string };
*HTTP::Request::TO_JSON = sub ($obj) { $obj->as_string };
*HTTP::Response::TO_JSON = sub ($obj) { $obj->as_string };
# Plack and Catalyst don't have serializers

my $yaml = YAML::PP->new(boolean => 'JSON::PP');
sub decode_yaml ($string) {
  $yaml->load_string($string);
}

# deep comparison, with strict typing
sub is_equal ($got, $expected, $test_name = undef) {
  context_do {
    my $ctx = shift;
    my ($got, $expected, $test_name) = @_;
    my $equal = JSON::Schema::Modern::Utilities::is_equal($got, $expected, my $state = {});
    if ($equal) {
      $ctx->pass($test_name);
    }
    else {
      $ctx->fail($test_name);
      my $method =
        # be less noisy for expected failures
        (grep $_->{todo}, Test2::API::test2_stack->top->{_pre_filters}->@*) ? 'note'
          : $ENV{AUTHOR_TESTING} || $ENV{AUTOMATED_TESTING} ? 'diag' : 'note';

      $ctx->$method('structures differ'.($state->{path} ? ' starting at '.$state->{path} : '')
        .': '.$state->{error});
      my ($equal, $stack) = Test::Deep::cmp_details($got, $expected);
      $ctx->$method(Test::Deep::deep_diag($stack)) if not $equal;
      $ctx->$method("got result:\n".$encoder->encode($got));
    }
    return $equal;
  } $got, $expected, $test_name;
}

# deep comparison, with Test::Deep syntax sugar
sub cmp_result ($got, $expected, $test_name) {
  context_do {
    my $ctx = shift;
    my ($got, $expected, $test_name) = @_;

    # dirty hack to check we always set operation_uri on success
    $ctx->fail('missing operation_uri on successful call')
      if ref $expected eq 'HASH' and $expected->{errors} and $expected->{method} and not $expected->{errors}->@*
      and not exists $expected->{operation_uri};

    my ($equal, $stack) = Test::Deep::cmp_details($got, $expected);
    if ($equal) {
      $ctx->pass($test_name);
    }
    else {
      $ctx->fail($test_name);
      my $method =
        # be less noisy for expected failures
        (grep $_->{todo}, Test2::API::test2_stack->top->{_pre_filters}->@*) ? 'note'
          : $ENV{AUTHOR_TESTING} || $ENV{AUTOMATED_TESTING} ? 'diag' : 'note';
      $ctx->$method(Test::Deep::deep_diag($stack));
      $ctx->$method("got result:\n".$encoder->encode($got));
    }
    return $equal;
  } $got, $expected, $test_name;
}

sub lives_result ($sub, $test_name) {
  context_do {
    my ($ctx, $result) = @_;
    if (not $ctx->ok(lives(\&$sub), $test_name)) {
      my $method =
        # be less noisy for expected failures
        (grep $_->{todo}, Test2::API::test2_stack->top->{_pre_filters}->@*) ? 'note'
          : $ENV{AUTHOR_TESTING} || $ENV{AUTOMATED_TESTING} ? 'diag' : 'note';
      $ctx->$method("got result:\n".$encoder->encode($result));
    }
  } $@;
}

sub die_result ($sub, $pattern, $test_name) {
  # we don't use Test2::Tools::Exception::dies because it tickles JSM::Result's boolean overload
  eval { $sub->() };
  my $result = $@;
  return fail($test_name) if not defined $result;
  context_do {
    my ($ctx, $result) = @_;
    if (not like($result, $pattern, $test_name)) {
      my $method =
        # be less noisy for expected failures
        (grep $_->{todo}, Test2::API::test2_stack->top->{_pre_filters}->@*) ? 'note'
          : $ENV{AUTHOR_TESTING} || $ENV{AUTOMATED_TESTING} ? 'diag' : 'note';
      $ctx->$method("got result:\n".$encoder->encode($result));
    }
  } $result;
}

sub exception :prototype(&) {
  eval { $_[0]->() };
  return $@ eq '' ? undef : $@;
}

sub bail_if_not_passing {
  context_do {
    my $ctx = shift;
    $ctx->bail if not $ctx->hub->is_passing;
  }
}

sub todo_maybe ($reason_or_undef, $sub) {
  if ($reason_or_undef) {
    todo $reason_or_undef => $sub;
  }
  else {
    $sub->();
  }
}

# turns an arrayref of arrayrefs into an arrayref of hashes,
# using the first element as the key names and the remaining
# elements as the values
sub arrays_to_hashes($arrayref) {
  my $headers = shift @$arrayref;
  my @result;
  foreach my $row (@$arrayref) {
    my $hashref = {};
    croak 'too many values at row: ', $encoder->encode($row) if @$row > @$headers;
    $hashref->@{@$headers} = @$row;
    push @result, $hashref;
  }

  return \@result;
}

1;
