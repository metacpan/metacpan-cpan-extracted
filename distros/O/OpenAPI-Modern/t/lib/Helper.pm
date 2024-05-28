use strictures 2;
# no package, so things defined here appear in the namespace of the parent.
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use Safe::Isa;
use List::Util 'pairs';
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
# 'mojo': classes of type Mojo::URL, Mojo::Headers, Mojo::Message::Request, Mojo::Message::Response
# 'lwp': classes of type URI, HTTP::Headers, HTTP::Request, HTTP::Response
# 'plack': classes of type Plack::Request, Plack::Response
# 'catalyst': classes of type Catalyst::Request, Catalyst::Response
our @TYPES = qw(mojo lwp plack catalyst);
our $TYPE;

# Note: if you want your query parameters or uri fragment to be normalized, set them afterwards
sub request ($method, $uri_string, $headers = [], $body_content = undef) {
  die '$TYPE is not set' if not defined $TYPE;

  my $req;
  if ($TYPE eq 'lwp' or $TYPE eq 'plack' or $TYPE eq 'catalyst') {
    test_needs('HTTP::Request', 'URI');

    my $uri = URI->new($uri_string);
    my $host = $uri->$_call_if_can('host');
    $req = HTTP::Request->new($method => $uri, [], $body_content);
    $req->headers->push_header(@$_) foreach pairs @$headers, $host ? (Host => $host) : ();
    $req->headers->header('Content-Length' => length($body_content))
      if defined $body_content and not defined $req->headers->header('Content-Length')
        and not defined $req->headers->header('Transfer-Encoding');
    $req->protocol('HTTP/1.1'); # required, but not added by HTTP::Request constructor

    if ($TYPE eq 'plack' or $TYPE eq 'catalyst') {
      test_needs('Plack::Request', 'HTTP::Message::PSGI', { 'HTTP::Headers::Fast' => 0.21 });
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
  }
  elsif ($TYPE eq 'mojo') {
    my $uri = Mojo::URL->new($uri_string);
    $req = Mojo::Message::Request->new(method => $method, url => Mojo::URL->new($uri_string));
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
    test_needs('HTTP::Response', 'HTTP::Status');

    $res = HTTP::Response->new($code, HTTP::Status::status_message($code), $headers, $body_content);
    $res->protocol('HTTP/1.1'); # not added by HTTP::Response constructor
    $res->headers->header('Content-Length' => length($body_content)//0)
      if not defined $res->headers->header('Content-Length')
        and not defined $res->headers->header('Transfer-Encoding');
  }
  elsif ($TYPE eq 'mojo') {
    $res = Mojo::Message::Response->new(code => $code);
    $res->headers->add(@$_) foreach pairs @$headers;
    $res->body($body_content) if defined $body_content;

    # add missing Content-Length, etc
    $res->fix_headers;
  }
  elsif ($TYPE eq 'plack') {
    test_needs('Plack::Response', 'HTTP::Message::PSGI', { 'HTTP::Headers::Fast' => 0.21 });
    $res = Plack::Response->new($code, $headers, $body_content);
    $res->headers->header('Content-Length' => length $body_content)
      if defined $body_content and not defined $res->headers->header('Content-Length')
        and not defined $res->headers->header('Transfer-Encoding');
  }
  elsif ($TYPE eq 'catalyst') {
    test_needs('Catalyst::Response');
    $res = Catalyst::Response->new(status => $code, body => $body_content);
    $res->headers->push_header(@$_) foreach pairs @$headers;
    $res->headers->header('Content-Length' => length $body_content)
      if defined $body_content and not defined $res->headers->header('Content-Length')
        and not defined $res->headers->header('Transfer-Encoding');
  }
  else {
    die '$TYPE '.$TYPE.' not supported';
  }

  return $res;
}

sub uri ($uri_string, @path_parts) {
  die '$TYPE is not set' if not defined $TYPE;

  my $uri;
  if ($TYPE eq 'lwp' or $TYPE eq 'plack' or $TYPE eq 'catalyst') {
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
  elsif ($TYPE eq 'plack' or $TYPE eq 'catalyst') {
    # this is the encoded query string portion of the URI
    $request->env->{QUERY_STRING} = Mojo::Parameters->new->pairs($pairs)->to_string;
    $request->env->{REQUEST_URI} .= '?' . $request->env->{QUERY_STRING};
    # $request->_clear_parameters if $TYPE eq 'catalyst';  # might need this later
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
  elsif ($TYPE eq 'plack' or $TYPE eq 'catalyst') {
    $message->headers->remove_header($header_name);
    delete $message->env->{uc $header_name =~ s/-/_/r} if $message->can('env');
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

my $encoder = JSON::Schema::Modern::_JSON_BACKEND()->new
  ->allow_nonref(1)
  ->utf8(0)
  ->allow_bignum(1)
  ->allow_blessed(1)
  ->convert_blessed(1)
  ->canonical(1)
  ->pretty(1)
  ->indent_length(2);

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
      $ctx->note('structures differ'.($state->{path} ? ' starting at '.$state->{path} : ''));
      $ctx->${$ENV{AUTOMATED_TESTING} ? \'diag' : \'note'}("got result:\n".$encoder->encode($got));
    }
    return $equal;
  } $got, $expected, $test_name;
}

# deep comparison, with Test::Deep syntax sugar
sub cmp_result ($got, $expected, $test_name) {
  context_do {
    my $ctx = shift;
    my ($got, $expected, $test_name) = @_;
    my $equal = Test::Deep::cmp_deeply($got, $expected, $test_name);
    if ($equal) {
      $ctx->pass($test_name);
    }
    else {
      $ctx->fail($test_name);
      $ctx->${$ENV{AUTOMATED_TESTING} ? \'diag' : \'note'}("got result:\n".$encoder->encode($got));
    }
    return $equal;
  } $got, $expected, $test_name;
}

1;
