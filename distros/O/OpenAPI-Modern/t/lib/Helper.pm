use strict;
use warnings;
# no package, so things defined here appear in the namespace of the parent.
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use Safe::Isa;
use List::Util 'pairs';
use HTTP::Request;
use HTTP::Response;
use HTTP::Status ();
use Mojo::Message::Request;
use Mojo::Message::Response;
use Test2::API 'context_do';

# type can be
# 'lwp': classes of type URI, HTTP::Headers, HTTP::Request, HTTP::Response
# 'mojo': classes of type Mojo::URL, Mojo::Headers, Mojo::Message::Request, Mojo::Message::Response
our @TYPES = qw(lwp mojo);
our $TYPE;

# Note: if you want your query parameters or uri fragment to be normalized, set them afterwards
sub request ($method, $uri_string, $headers = [], $body_content = undef) {
  die '$TYPE is not set' if not defined $TYPE;

  my $req;
  if ($TYPE eq 'lwp') {
    my $uri = URI->new($uri_string);
    my $host = $uri->$_call_if_can('host');
    $req = HTTP::Request->new($method => $uri, [], $body_content);
    $req->headers->header(Host => $host) if $host;
    $req->headers->push_header(@$_) foreach pairs @$headers;
    $req->protocol('HTTP/1.1'); # required, but not added by HTTP::Request constructor
  }
  elsif ($TYPE eq 'mojo') {
    my $uri = Mojo::URL->new($uri_string);
    my $host = $uri->host;
    $req = Mojo::Message::Request->new(method => $method, url => Mojo::URL->new($uri_string));
    $req->headers->header('Host', $host) if $host;
    $req->headers->add(@$_) foreach pairs @$headers;
    $req->body($body_content) if defined $body_content;

    # add missing Content-Length, etc
    $req->fix_headers;
  }
  else {
    die '$TYPE '.$TYPE.' not supported';
  }

  return $req;
}

sub response ($code, $headers = [], $body_content = undef) {
  die '$TYPE is not set' if not defined $TYPE;

  my $res;
  if ($TYPE eq 'lwp') {
    $res = HTTP::Response->new($code, HTTP::Status::status_message($code), $headers, $body_content);
    $res->protocol('HTTP/1.1'); # not added by HTTP::Response constructor
  }
  elsif ($TYPE eq 'mojo') {
    $res = Mojo::Message::Response->new(code => $code);
    $res->message($res->default_message);
    while (my ($name, $value) = splice(@$headers, 0, 2)) {
      $res->headers->header($name, $value);
    }
    $res->body($body_content) if defined $body_content;
  }
  else {
    die '$TYPE '.$TYPE.' not supported';
  }

  return $res;
}

sub uri ($uri_string, @path_parts) {
  die '$TYPE is not set' if not defined $TYPE;

  my $uri;
  if ($TYPE eq 'lwp') {
    $uri = URI->new($uri_string);
    $uri->path_segments(@path_parts) if @path_parts;
  }
  elsif ($TYPE eq 'mojo') {
    $uri = Mojo::URL->new($uri_string);
    $uri->path->parts(\@path_parts) if @path_parts;
  }
  else {
    die '$TYPE '.$TYPE.' not supported';
  }

  return $uri;
}

# sets query parameters on the request
sub query_params ($request, $pairs) {
  die '$TYPE is not set' if not defined $TYPE;

  my $uri;
  if ($TYPE eq 'lwp') {
    $request->uri->query_form($pairs);
  }
  elsif ($TYPE eq 'mojo') {
    $request->url->query->pairs($pairs);
  }
  else {
    die '$TYPE '.$TYPE.' not supported';
  }

  return $uri;
}

# create a Result object out of the document errors; suitable for stringifying
# as the OpenAPI::Modern constructor might do.
sub document_result ($document) {
  JSON::Schema::Modern::Result->new(
    valid => $document->has_errors,
    errors => [ $document->errors ],
  );
}

# deep comparison, with strict typing
sub is_equal ($x, $y, $test_name = undef) {
  context_do {
    my $ctx = shift;
    my ($x, $y, $test_name) = @_;
    my $equal = JSON::Schema::Modern::Utilities::is_equal($x, $y, my $state = {});
    if ($equal) {
      $ctx->pass($test_name);
    }
    else {
      $ctx->fail($test_name);
      $ctx->note('structures differ'.($state->{path} ? ' starting at '.$state->{path} : ''));
    }
    return $equal;
  } $x, $y, $test_name;
}

1;
