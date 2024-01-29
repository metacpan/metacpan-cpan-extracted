use strictures 2;
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
use Test::Needs;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use JSON::Schema::Modern;
use JSON::Schema::Modern::Document::OpenAPI;
use OpenAPI::Modern;
use Test::File::ShareDir -share => { -dist => { 'OpenAPI-Modern' => 'share' } };
use constant { true => JSON::PP::true, false => JSON::PP::false };
use YAML::PP 0.005;

# type can be
# 'lwp': classes of type URI, HTTP::Headers, HTTP::Request, HTTP::Response
# 'mojo': classes of type Mojo::URL, Mojo::Headers, Mojo::Message::Request, Mojo::Message::Response
# 'plack': classes of type Plack::Request, Plack::Response
our @TYPES = qw(lwp mojo plack);
our $TYPE;

# Note: if you want your query parameters or uri fragment to be normalized, set them afterwards
sub request ($method, $uri_string, $headers = [], $body_content = undef) {
  die '$TYPE is not set' if not defined $TYPE;

  my $req;
  if ($TYPE eq 'lwp' or $TYPE eq 'plack') {
    my $uri = URI->new($uri_string);
    my $host = $uri->$_call_if_can('host');
    $req = HTTP::Request->new($method => $uri, [], $body_content);
    $req->headers->header(Host => $host) if $host;
    $req->headers->push_header(@$_) foreach pairs @$headers;
    $req->headers->header('Content-Length' => length($body_content))
      if defined $body_content and not defined $req->headers->header('Content-Length');
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

  if ($TYPE eq 'plack') {
    test_needs('Plack::Request', 'HTTP::Message::PSGI', { 'HTTP::Headers::Fast' => 0.21 });
    my $uri = $req->uri;
    $req = Plack::Request->new($req->to_psgi);

    # Plack is unable to distinguish between %2F and /, so the raw (undecoded) uri can be passed
    # here. see PSGI::FAQ
    $req->env->{REQUEST_URI} = $uri . '';
  }

  return $req;
}

sub response ($code, $headers = [], $body_content = undef) {
  die '$TYPE is not set' if not defined $TYPE;

  my $res;
  if ($TYPE eq 'lwp') {
    $res = HTTP::Response->new($code, HTTP::Status::status_message($code), $headers, $body_content);
    $res->protocol('HTTP/1.1'); # not added by HTTP::Response constructor
    $res->headers->header('Content-Length' => length($body_content))
      if defined $body_content and not defined $res->headers->header('Content-Length');
  }
  elsif ($TYPE eq 'mojo') {
    $res = Mojo::Message::Response->new(code => $code);
    $res->message($res->default_message);
    while (my ($name, $value) = splice(@$headers, 0, 2)) {
      $res->headers->header($name, $value);
    }
    $res->body($body_content) if defined $body_content;

    # add missing Content-Length, etc
    $res->fix_headers;
  }
  elsif ($TYPE eq 'plack') {
    test_needs('Plack::Response', 'HTTP::Message::PSGI', { 'HTTP::Headers::Fast' => 0.21 });
    $res = Plack::Response->new($code, $headers, $body_content);
    $res->headers->header('Content-Length' => length($body_content))
      if defined $body_content and not defined $res->headers->header('Content-Length');
  }
  else {
    die '$TYPE '.$TYPE.' not supported';
  }

  return $res;
}

sub uri ($uri_string, @path_parts) {
  die '$TYPE is not set' if not defined $TYPE;

  my $uri;
  if ($TYPE eq 'lwp' or $TYPE eq 'plack') {
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
  elsif ($TYPE eq 'plack') {
    # this is the encoded query string portion of the URI
    $request->env->{QUERY_STRING} = Mojo::Parameters->new->pairs($pairs)->to_string;
    $request->env->{REQUEST_URI} .= '?' . $request->env->{QUERY_STRING};
  }
  else {
    die '$TYPE '.$TYPE.' not supported';
  }

  return $uri;
}

sub remove_header ($message, $header_name) {
  die '$TYPE is not set' if not defined $TYPE;

  if ($TYPE eq 'lwp') {
    $message->headers->remove_header($header_name);
  }
  elsif ($TYPE eq 'mojo') {
    $message->headers->remove($header_name);
  }
  elsif ($TYPE eq 'plack') {
    $message->headers->remove_header($header_name);
    delete $message->env->{uc $header_name =~ s/-/_/r} if $message->isa('Plack::Request');
  }
  else {
    die '$TYPE '.$TYPE.' not supported';
  }
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
