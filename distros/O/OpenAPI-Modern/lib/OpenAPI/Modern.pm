use strictures 2;
package OpenAPI::Modern; # git description: v0.086-15-g8f56a9c
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Validate HTTP requests and responses against an OpenAPI v3.1 document
# KEYWORDS: validation evaluation JSON Schema OpenAPI v3.1 Swagger HTTP request response

our $VERSION = '0.087';

use 5.020;
use utf8;
use Moo;
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
use Carp 'croak';
use Safe::Isa;
use Ref::Util qw(is_plain_hashref is_plain_arrayref is_ref);
use List::Util qw(first pairs none);
use Scalar::Util 'looks_like_number';
use builtin::compat 'indexed';
use Feature::Compat::Try;
use Encode 2.89 ();
use JSON::Schema::Modern;
use JSON::Schema::Modern::Utilities qw(jsonp unjsonp canonical_uri E abort is_equal is_elements_unique);
use JSON::Schema::Modern::Document::OpenAPI;
use MooX::TypeTiny 0.002002;
use Types::Standard qw(InstanceOf Bool);
use constant { true => JSON::PP::true, false => JSON::PP::false };
use Mojo::Util 'url_unescape';
use Mojo::Message::Request;
use Mojo::Message::Response;
use Storable 'dclone';
use namespace::clean;

has openapi_document => (
  is => 'ro',
  isa => InstanceOf['JSON::Schema::Modern::Document::OpenAPI'],
  required => 1,
  handles => {
    openapi_uri => 'canonical_uri', # Mojo::URL
    openapi_schema => 'schema',     # hashref
    document_get => 'get',          # data access using a json pointer
  },
);

# held separately because $document->evaluator is a weak ref
has evaluator => (
  is => 'ro',
  isa => InstanceOf['JSON::Schema::Modern'],
  required => 1,
  handles => [ qw(get_media_type add_media_type) ],
);

our $DEBUG;
has debug => (
  is => 'ro',
  isa => Bool,
  default => $DEBUG,
);

around BUILDARGS => sub ($orig, $class, @args) {
  my $args = $class->$orig(@args);

  if (exists $args->{openapi_document}) {
    $args->{evaluator} = $args->{openapi_document}->evaluator;
  }
  else {
    # construct document out of openapi_uri, openapi_schema (and evaluator if provided).
    croak 'missing required constructor arguments: either openapi_document, or openapi_uri and openapi_schema'
      if not exists $args->{openapi_uri} or not exists $args->{openapi_schema};
  }

  $args->{evaluator} //= JSON::Schema::Modern->new(validate_formats => 1, max_traversal_depth => 80);

  $args->{openapi_document} //= JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => $args->{openapi_uri},
    schema => $args->{openapi_schema},
    evaluator => $args->{evaluator},
  );

  # if there were errors, this will die with a JSON::Schema::Modern::Result object
  $args->{evaluator}->add_document($args->{openapi_document});

  return $args;
};

sub validate_request ($self, $request, $options = {}) {
  croak 'missing request' if not $request;

  croak '$request and $options->{request} are inconsistent'
    if $options->{request} and $request != $options->{request};

  # mostly populated by find_path
  my $state = { data_path => '/request' };

  try {
    $options->{request} //= $request;
    my $path_ok = $self->find_path($options, $state);
    delete $options->{errors};

    # Reporting a failed find_path as an exception will result in a recommended response of
    # [ 500, Internal Server Error ], which is warranted if we consider the lack of a specification
    # entry for this incoming request as an unexpected, server-side error.
    # Callers can decide if this should instead be reported as a [ 404, Not Found ], but that sort
    # of response is likely to leave oversights in the specification go unnoticed.
    return $self->_result($state, 1) if not $path_ok;

    $request = $options->{request};   # now guaranteed to be a Mojo::Message::Request

    my $method = lc $request->method;
    my $path_item = delete $options->{_path_item};  # after following path-item $refs
    my $operation = $path_item->{$method};

    # PARAMETERS
    # { $in => { $name => 'path-item'|$method } }  as we process each one.
    my $request_parameters_processed = {};

    # first, consider parameters at the operation level.
    # parameters at the path-item level are also considered, if not already seen at the operation level
    SECTION:
    foreach my $section ($method, 'path-item') {
      ENTRY:
      foreach my $idx (0 .. (($section eq $method ? $operation : $path_item)->{parameters}//[])->$#*) {
        my $state = { %$state, schema_path => jsonp($state->{schema_path},
          ($section eq $method ? $method : ()), 'parameters', $idx) };
        my $param_obj = ($section eq $method ? $operation : $path_item)->{parameters}[$idx];
        while (my $ref = $param_obj->{'$ref'}) {
          $param_obj = $self->_resolve_ref('parameter', $ref, $state);
        }

        my $fc_name = $param_obj->{in} eq 'header' ? fc($param_obj->{name}) : $param_obj->{name};

        abort($state, 'duplicate %s parameter "%s"', $param_obj->{in}, $param_obj->{name})
          if (($request_parameters_processed->{$param_obj->{in}}//{})->{$fc_name} // '') eq $section;

        { use autovivification qw(exists store);
          next ENTRY if exists $request_parameters_processed->{$param_obj->{in}}{$fc_name};
          $request_parameters_processed->{$param_obj->{in}}{$fc_name} = $section;
        }

        $state->{data_path} = jsonp('/request',
          ((grep $param_obj->{in} eq $_, qw(path query)) ? 'uri' : ()), $param_obj->{in},
          $param_obj->{name});
        my $valid =
            $param_obj->{in} eq 'path' ? $self->_validate_path_parameter({ %$state, depth => $state->{depth}+1 }, $param_obj, $options->{path_captures})
          : $param_obj->{in} eq 'query' ? $self->_validate_query_parameter({ %$state, depth => $state->{depth}+1 }, $param_obj, $request->url)
          : $param_obj->{in} eq 'header' ? $self->_validate_header_parameter({ %$state, depth => $state->{depth}+1 }, $param_obj->{name}, $param_obj, $request->headers)
          : $param_obj->{in} eq 'cookie' ? $self->_validate_cookie_parameter({ %$state, depth => $state->{depth}+1 }, $param_obj, $request)
          : abort($state, 'unrecognized "in" value "%s"', $param_obj->{in});
      }
    }

    # §3.5: "Each template expression in the path MUST correspond to a path parameter that is
    # included in the Path Item itself and/or in each of the Path Item’s Operations."
    # We could validate this at document parse time, except the path-item can also be reached via a
    # $ref and the referencing path could be from another document and is therefore unknowable until
    # runtime.
    foreach my $path_name (sort keys $options->{path_captures}->%*) {
      abort({ %$state, data_path => jsonp('/request/uri/path', $path_name) },
          'missing path parameter specification for "%s"', $path_name)
        if not exists(($request_parameters_processed->{path}//{})->{$path_name});
    }

    $state->{schema_path} = jsonp($state->{schema_path}, $method);

    # RFC9112 §6.2-2: "A sender MUST NOT send a Content-Length header field in any message that
    # contains a Transfer-Encoding header field."
    ()= E({ %$state, data_path => '/request/header/Content-Length', },
        'Content-Length cannot appear together with Transfer-Encoding')
      if defined $request->headers->content_length and $request->content->is_chunked;

    # RFC9112 §6.3-7: "A user agent that sends a request that contains a message body MUST send
    # either a valid Content-Length header field or use the chunked transfer coding."
    ()= E({ %$state, data_path => '/request/header',
        recommended_response => [ 411 ] }, 'missing header: Content-Length')
      if $request->body_size and not $request->headers->content_length
        and not $request->content->is_chunked;

    if (my $body_obj = $operation->{requestBody}) {
      $state->{schema_path} = $state->{schema_path}.'/requestBody';

      while (my $ref = $body_obj->{'$ref'}) {
        $body_obj = $self->_resolve_ref('request-body', $ref, $state);
      }

      if ($request->body_size) {
        $state->{data_path} = '/request/body';
        $self->_validate_body_content({ %$state, depth => $state->{depth}+1 }, $body_obj->{content}, $request);
      }
      elsif ($body_obj->{required}) {
        ()= E({ %$state, keyword => 'required' }, 'request body is required but missing');
      }
    }
    else {
      $state->{data_path} = '/request/body';
      # we presume that no body specification for GET and HEAD requests -> no body is expected
      ()= E($state, 'unspecified body is present in %s request', uc $method)
        if ($method eq 'get' or $method eq 'head')
          and $request->headers->content_length // $request->body_size;
    }
  }
  catch ($e) {
    if ($e->$_isa('JSON::Schema::Modern::Result')) {
      return $e;
    }
    elsif ($e->$_isa('JSON::Schema::Modern::Error')) {
      push @{$state->{errors}}, $e;
    }
    else {
      ()= E({ %$state, exception => 1 }, 'EXCEPTION: '.$e);
    }
  }

  return $self->_result($state);
}

sub validate_response ($self, $response, $options = {}) {
  croak 'missing response' if not $response;

  # handle the existence of HTTP::Response::request
  if (my $request = $response->$_call_if_can('request')) {
    croak '$response->request and $options->{request} are inconsistent'
      if $request and $options->{request} and $request != $options->{request};
    $options->{request} //= $request;
  }

  # mostly populated by find_path
  my $state = { data_path => '/response' };

  try {
    # FIXME: if the operation is shared by multiple paths, path_template may not be inferrable, and
    # we also don't need path_captures
    my $path_ok = $self->find_path($options, $state);
    delete $options->{errors};
    return $self->_result($state, 1, 1) if not $path_ok;

    my $method = lc $options->{method};
    my $path_item = delete $options->{_path_item};
    my $operation = $path_item->{$method};

    return $self->_result($state, 0, 1) if not exists $operation->{responses};

    $state->{schema_path} = jsonp($state->{schema_path}, $method);
    $response = _convert_response($response);   # now guaranteed to be a Mojo::Message::Response

    if ($response->headers->header('Transfer-Encoding')) {
      ()= E({ %$state, data_path => '/response/header/Transfer-Encoding' },
        'RFC9112 §6.1-10: "A server MUST NOT send a Transfer-Encoding header field in any response with a status code of 1xx (Informational) or 204 (No Content)"')
        if $response->is_info or $response->code == 204;

      # connect method is not supported in openapi 3.1.1, but this may be possible in the future
      ()= E({ %$state, data_path => '/response/header/Transfer-Encoding' },
        'RFC9112 §6.1-10: "A server MUST NOT send a Transfer-Encoding header field in any 2xx (Successful) response to a CONNECT request"')
        if $response->is_success and $method eq 'connect';
    }

    # RFC9112 §6.2-2: "A sender MUST NOT send a Content-Length header field in any message that
    # contains a Transfer-Encoding header field."
    ()= E({ %$state, data_path => '/response/header/Content-Length' },
        'Content-Length cannot appear together with Transfer-Encoding')
      if defined $response->headers->content_length and $response->content->is_chunked;

    # RFC9112 §6.3-7: "A user agent that sends a request that contains a message body MUST send
    # either a valid Content-Length header field or use the chunked transfer coding."
    ()= E({ %$state, data_path => '/response/header' }, 'missing header: Content-Length')
      if $response->body_size and not $response->headers->content_length
        and not $response->content->is_chunked;

    if (not $response->code) {
      ()= E($state, 'Failed to parse response: %s', $response->error->{message});
      return $self->_result($state, 0, 1);
    }

    my $response_name = first { exists $operation->{responses}{$_} }
      $response->code, substr(sprintf('%03s', $response->code), 0, -2).'XX', 'default';

    if (not $response_name) {
      ()= E({ %$state, keyword => 'responses', data_path => $state->{data_path}.'/code' },
        'no response object found for code %s', $response->code);
      return $self->_result($state, 0, 1);
    }

    my $response_obj = $operation->{responses}{$response_name};
    $state->{schema_path} = jsonp($state->{schema_path}, 'responses', $response_name);
    while (my $ref = $response_obj->{'$ref'}) {
      $response_obj = $self->_resolve_ref('response', $ref, $state);
    }

    foreach my $header_name (sort keys(($response_obj->{headers}//{})->%*)) {
      next if fc $header_name eq fc 'Content-Type';
      my $state = { %$state, schema_path => jsonp($state->{schema_path}, 'headers', $header_name) };
      my $header_obj = $response_obj->{headers}{$header_name};
      while (my $ref = $header_obj->{'$ref'}) {
        $header_obj = $self->_resolve_ref('header', $ref, $state);
      }

      ()= $self->_validate_header_parameter({ %$state,
          data_path => jsonp('/response/header', $header_name), depth => $state->{depth}+1 },
        $header_name, $header_obj, $response->headers);
    }

    $self->_validate_body_content({ %$state, data_path => '/response/body', depth => $state->{depth}+1 },
        $response_obj->{content}, $response)
      if exists $response_obj->{content} and $response->headers->content_length // $response->body_size;
  }
  catch ($e) {
    if ($e->$_isa('JSON::Schema::Modern::Result')) {
      $e->recommended_response(undef);  # responses don't have responses
      return $e;
    }
    elsif ($e->$_isa('JSON::Schema::Modern::Error')) {
      push @{$state->{errors}}, $e;
    }
    else {
      ()= E({ %$state, exception => 1 }, 'EXCEPTION: '.$e);
    }
  }

  return $self->_result($state, 0, 1);
}

sub find_path ($self, $options, $state = {}) {
  # there are many $state fields used by JSM that we do not set here because we do not use them for
  # OpenAPI validation, such as document, document_path, vocabularies, spec_version, configs
  $state->{data_path} //= '';
  $state->{initial_schema_uri} = $self->openapi_uri;   # the canonical URI as of the start or last $id, or the last traversed $ref
  $state->{traversed_schema_path} = '';    # the accumulated traversal path as of the start, or last $id, or up to the last traversed $ref
  $state->{schema_path} = '';              # the rest of the path, since the last $id or the last traversed $ref
  $state->{errors} = $options->{errors} //= [];
  $state->{annotations} //= [];
  $state->{depth} = 0;
  $state->{debug} = $options->{debug} = {} if $DEBUG or $self->debug;

  # now guaranteed to be a Mojo::Message::Request
  if ($options->{request}) {
    $options->{request} = _convert_request($options->{request});

    # requests don't have response codes, so if 'error' is set, it is some sort of parsing error
    if (my $error = $options->{request}->error) {
      return E({ %$state, data_path => '/request', recommended_response => [ 500 ] }, 'Failed to parse request: %s', $error->{message});
    }
  }

  my $method;

  # method from options
  if (exists $options->{method}) {
    $method = lc $options->{method};
    return E({ %$state, data_path => '/request/method', recommended_response => [ 500 ] },
        'wrong HTTP method "%s"', $options->{request}->method)
      if $options->{request} and lc $options->{request}->method ne $method;
  }
  elsif ($options->{request}) {
    $method = $options->{method} = lc $options->{request}->method;
  }

  my ($path_template, $operation_path);

  # path_template and method from operation_id from options
  if (exists $options->{operation_id}) {
    # FIXME: what if the operation is defined in another document? Need to look it up across
    # all documents, and localize $state->{initial_schema_uri}
    $operation_path = $self->openapi_document->get_operationId_path($options->{operation_id});
    return E({ %$state, recommended_response => [ 500 ] }, 'unknown operation_id "%s"', $options->{operation_id})
      if not $operation_path;

    ($path_template, $method) = (unjsonp($operation_path))[-2,-1];

    # The path_template cannot be found if the operation path is not directly under /paths (such as
    # for path-items reached by a $ref): we will do a URI -> path_template lookup later on,
    # which will work as long as the operation does not correspond to a webhook or callback.
    # TODO: need a mechanism for specifying these
    if ($operation_path ne jsonp('/paths', $path_template, $method)) {
      undef $path_template;
    }
    else {
      # the path_template need not be provided, but if it is, the operation must be located at the
      # path-item directly underneath that /paths/<path_template>.
      return E({ %$state, schema_path => $operation_path.'/operationId', recommended_response => [ 500 ] },
          'operation at operation_id does not match provided path_template')
        if exists $options->{path_template} and $options->{path_template} ne $path_template;
    }

    if ($options->{method} and lc $options->{method} ne $method) {
      delete $options->{operation_id};
      return E({ %$state, ($options->{request} ? ( data_path => '/request/method' ) : ()), schema_path => $operation_path.'/operationId' },
        'operation at operation_id does not match HTTP method "%s"', $options->{method});
    }

    $options->{method} = $method;
  }

  # TODO: support passing $options->{operation_uri}

  # by now we will have extracted method from request or operation_id
  return E({ %$state, exception => 1, recommended_response => [ 500 ] }, 'at least one of $options->{request}, ($options->{path_template} and $options->{method}), or $options->{operation_id} must be provided')
    if not $options->{request}
      and not ($options->{path_template} and $method)
      and not $options->{operation_id};

  my $schema = $self->openapi_document->schema;

  # path_template from options
  if (exists $options->{path_template}) {
    $path_template = $options->{path_template};

    return E({ %$state, data_path => '/request/uri', keyword => 'paths' }, 'missing path-item "%s"', $path_template)
      if not exists $schema->{paths}{$path_template};
  }

  if (not $path_template and not $options->{request}) {
    # some operations don't exist directly under a /paths/$path_template - e.g. webhooks or
    # callbacks, but they are still usable
    my $path_item_path = $operation_path =~ s{/$method$}{}r;
    $state->{schema_path} = $path_item_path;
    $options->{_path_item} = $self->document_get($path_item_path);

    # FIXME: this is not accurate if the operation lives in another document
    # (and in that case, get_operation_uri_by_id can be returned as-is)
    $options->{operation_uri} = $state->{initial_schema_uri}->clone->fragment($operation_path);
    return 1;
  }

  my $captures;  # hashref of template variable names -> concrete values from the uri

  if (not $path_template and $options->{request}) {
    # derive path_template and capture values from the request URI

    # sorting (ascii-wise) gives us the desired results that concrete path components sort ahead of
    # templated components, except when the concrete component is a non-ascii character or matches
    # 0x7c (pipe), 0x7d (close-brace) or 0x7e (tilde)
    foreach my $pt (sort keys(($schema->{paths}//{})->%*)) {
      $state->{path_item} = $schema->{paths}{$pt};
      $state->{schema_path} = jsonp('/paths', $pt);
      $captures = $self->_match_uri($options->{request}->method, $options->{request}->url, $pt, $state);

      # note: this might not be the intended match, as multiple templates can match the same URI
      $path_template = $pt, last if $captures;

      # the initial match succeeded, but something else went wrong
      if ($state->{errors}->@*) {
        $options->{path_template} = $pt;
        $options->{_path_item} = $state->{path_item};
        return;
      }
    }

    return E({ %$state, data_path => '/request', schema_path => '', keyword => 'paths' },
        'no match found for request %s "%s"',
        $options->{request}->method, $options->{request}->url->clone->query('')->fragment(undef))
      if not $captures;
  }

  elsif ($options->{request}) {
    # we were passed path_template in options or we calculated it from operation_id, and now we
    # verify it against path_captures and the request URI.
    $state->{path_item} = $schema->{paths}{$path_template};
    $state->{schema_path} = jsonp('/paths', $path_template);
    $captures = $self->_match_uri($options->{request}->method, $options->{request}->url, $path_template, $state);

    if (not $captures) {
      delete $options->{operation_id};

      # the initial match succeeded, but something else went wrong
      if ($state->{errors}->@*) {
        $options->{path_template} = $path_template;
        $options->{_path_item} = $state->{path_item};
        return;
      }

      if (exists $options->{path_template}) {
        return E({ %$state, data_path => '/request/uri',
            schema_path => jsonp('/paths', $path_template), recommended_response => [ 500 ] },
          'provided path_template does not match request URI "%s"',
          $options->{request}->url->clone->query('')->fragment(undef));
      }
      else {
        return E({ %$state, data_path => '/request/uri',
            schema_path => jsonp('/paths', $path_template, $method, 'operationId'), recommended_response => [ 500 ] },
          'provided operation_id does not match request %s %s',
          $options->{request}->method, $options->{request}->url->clone->query('')->fragment(undef));
      }
    }
  }

  else {
    $state->{path_item} = $schema->{paths}{$path_template};
    $state->{schema_path} = jsonp('/paths', $path_template);
    while (my $ref = $state->{path_item}{'$ref'}) {
      $state->{path_item} = $self->_resolve_ref('path-item', $ref, $state);
    }
  }

  # if we weren't passed a request, we can't verify that the path_template matches, but we may have
  # derived it from looking upward from the operation_id
  $options->{path_template} = $path_template;
  $options->{_path_item} = $state->{path_item};

  # this can only happen if we were not able to derive the path_template from the provided
  # operation_id earlier, but we still matched the request against some other path-item
  return E({ %$state, recommended_response => [ 500 ] }, 'templated operation does not match provided operation_id')
    if $options->{operation_id} and ($options->{_path_item}{$method}{operationId}//'') ne $options->{operation_id};

  # this can only happen if we do not have a request object, as otherwise a missing operation is
  # simply reported as a match failure
  return E({ %$state, data_path => '/request/method', recommended_response => [ 405 ] },
      'missing operation for HTTP method "%s" under "%s"', uc $method, $path_template)
    if not exists $options->{_path_item}{$method};

  # if initial_schema_uri still points to the head of the entry document, then we have not followed
  # a $ref and the path-item is located at /paths/<path_template>
  $options->{operation_uri} = $state->{initial_schema_uri}->clone
    ->fragment(($state->{initial_schema_uri}->fragment // $state->{schema_path}).'/'.$method);

  $options->{operation_id} = $options->{_path_item}{$method}{operationId} if exists $options->{_path_item}{$method}{operationId};

  # note: we aren't doing anything special with escaped slashes. this bit of the spec is hazy.
  # { for the editor
  my @path_capture_names = ($path_template =~ m!\{([^}]+)\}!g);
  return E({ %$state, $options->{request} ? ( data_path => '/request/uri' ) : (), recommended_response => [ 500 ] }, 'provided path_captures names do not match path template "%s"', $path_template)
    if exists $options->{path_captures}
      and not is_equal([ sort keys $options->{path_captures}->%* ], [ sort @path_capture_names ]);

  return 1 if not $captures;

  my @uri_capture_names = keys %$captures;

  if (exists $options->{uri_captures}) {
    return E({ %$state, $options->{request} ? ( data_path => '/request/uri' ) : (), recommended_response => [ 500 ] },
        'provided uri_captures names do not match extracted values')
      if not is_equal([ sort keys $options->{uri_captures}->%* ], [ sort @uri_capture_names ]);

    # $equal_state will contain { path => '/0' } indicating the index of the mismatch
    if (not is_equal([ $options->{uri_captures}->@{@uri_capture_names} ], [ $captures->@{@uri_capture_names} ], my $equal_state = { stringy_numbers => 1 })) {
      return E({ %$state, data_path => '/request/uri', recommended_response => [ 500 ] },
        'provided uri_captures values do not match request URI (value for %s differs)', $uri_capture_names[substr($equal_state->{path}, 1)]);
    }
  }
  else {
    $options->{uri_captures} = $captures;
  }

  if (exists $options->{path_captures}) {
    # $equal_state will contain { path => '/0' } indicating the index of the mismatch
    if (not is_equal([ $options->{path_captures}->@{@path_capture_names} ], [ $captures->@{@path_capture_names} ], my $equal_state = { stringy_numbers => 1 })) {
      return E({ %$state, data_path => '/request/uri', recommended_response => [ 500 ] },
        'provided path_captures values do not match request URI (value for %s differs)', $path_capture_names[substr($equal_state->{path}, 1)]);
    }
  }
  else {
    $options->{path_captures} = +{ $captures->%{@path_capture_names} };
  }

  return 1;
}

# TODO: this should (also?) be available at JSON::Schema::Modern
sub recursive_get ($self, $uri_reference, $entity_type = undef) {
  my $base = $self->openapi_document->canonical_uri;
  my $ref = $uri_reference;
  my ($depth, $schema);

  while ($ref) {
    die 'maximum evaluation depth exceeded' if $depth++ > $self->evaluator->max_traversal_depth;
    my $uri = Mojo::URL->new($ref)->to_abs($base);

    my $schema_info = $self->evaluator->_fetch_from_uri($uri);

    die('unable to find resource "', $uri, '"') if not $schema_info;
    die sprintf('bad $ref to %s: not a%s "%s"', $schema_info->{canonical_uri}, ($entity_type =~ /^[aeiou]/ ? 'n' : ''), $entity_type)
      if $entity_type
        and $schema_info->{document}->get_entity_at_location($schema_info->{document_path}) ne $entity_type;

    $entity_type //= $schema_info->{document}->get_entity_at_location($schema_info->{document_path});
    $schema = $schema_info->{schema};
    $base = $schema_info->{canonical_uri};
    $ref = $schema->{'$ref'};
  }

  $schema = dclone($schema);
  return wantarray ? ($schema, $base) : $schema;
}

######## NO PUBLIC INTERFACES FOLLOW THIS POINT ########

# given a request uri and a path_template, check that these match, and extract capture values.
# returns false on error, possibly adding errors to $state.
sub _match_uri ($self, $method, $uri, $path_template, $state) {
  my $uri_path = $uri->path->to_string;

  # RFC9112 §3.2.1-3: "If the target URI's path component is empty, the client MUST send "/" as the
  # path within the origin-form of request-target."
  $uri_path = '/' if not length $uri_path;

  # §3.5: "The value for these path parameters MUST NOT contain any unescaped “generic syntax”
  # characters described by [RFC3986]: forward slashes (/), question marks (?), or hashes (#)."
  my $path_pattern = join '',
    map +(substr($_, 0, 1) eq '{' ? '([^/?#]*)' : quotemeta($_)), # { for the editor
    split /(\{[^}]+\})/, $path_template;

  # if the uri doesn't match against the path alone, we can immediately bail (and keep looking for
  # another /paths entry that might match)... this also saves us needless parsing of server objects
  do { use autovivification 'store'; push $state->{debug}{uri_patterns}->@*, $path_pattern.'$' }
    if exists $state->{debug};
  return if $uri_path !~ m/$path_pattern$/;

  my $local_state = +{ %$state };

  while (my $ref = $local_state->{path_item}{'$ref'}) {
    $local_state->{path_item} = $self->_resolve_ref('path-item', $ref, $local_state);
  }

  # §4.8.8.1: "In case of ambiguous matching, it’s up to the tooling to decide which one to use."
  # There could be another paths entry that matches this URI that does have this method
  # implemented, so we return false and keep searching. Since we may still match to the wrong URI,
  # the correct operation can be forced to match by explicitly passing the corresponding
  # path_template or (preferrably) operationId to be used in the search.
  return if not exists $local_state->{path_item}{lc $method};

  my $full_uri = $uri->clone->path($uri_path)->fragment(undef)->query('')->to_string;

  # we need to keep track of the traversed path to the servers object, as well as its absolute
  # location, for usage in error objects
  my ($servers, $more_schema_path, $base_schema_uri) =
      exists $local_state->{path_item}{lc $method}{servers}
        ? ($local_state->{path_item}{lc $method}{servers}, [lc $method, 'servers'])
    : exists $local_state->{path_item}{servers}
        ? ($local_state->{path_item}{servers}, ['servers'])
    : exists $self->openapi_document->schema->{servers}
        ? ($self->openapi_document->schema->{servers}, ['servers'], $self->openapi_uri)
    : ();

  # §4.8.1.1 "If the servers field is not provided, or is an empty array, the default value would
  # be [an array consisting of a single] Server Object with a url value of `/`."
  $servers = [{ url => '/' }] if not $servers or not @$servers;

  foreach my $index_and_server (pairs indexed @$servers) {
    my ($index, $server) = @$index_and_server;

    # we need a full uri to match against the full uri taken from the request (scheme and host)
    # we fall back to using the request's scheme, host and port, otherwise the match can never
    # succeed.
    my $server_url = Mojo::URL->new($server->{url})->to_abs($self->openapi_document->retrieval_uri);
    $server_url = $server_url->to_abs($uri)->query('');
    $server_url->path->leading_slash(0)->trailing_slash(0);

    # turn %7B and %7D back into { and }
    my $uri_template = url_unescape($server_url) . $path_template;

    my $uri_pattern = join '',
      map +(substr($_, 0, 1) eq '{' ? '([^/?#]*)' : quotemeta($_)), # { for the editor
      split /(\{[^}]+\})/, $uri_template;
    do { use autovivification 'store'; push $state->{debug}{uri_patterns}->@*, '^'.$uri_pattern.'$' }
      if exists $state->{debug};
    next if $full_uri !~ m/^$uri_pattern$/;

    # extract all capture values from server variables and path template variables: ($1 .. $n)
    # perldoc perlvar, @-: $n coincides with "substr $_, $-[n], $+[n] - $-[n]" if "$-[n]" is defined
    my @uri_capture_values = map
      Encode::decode('UTF-8', url_unescape(substr($full_uri, $-[$_], $+[$_]-$-[$_])),
        Encode::FB_CROAK | Encode::LEAVE_SRC), 1 .. $#-;

    # we have a match, so preserve our new $state values created via _resolve_ref
    %$state = %$local_state;

    # note: we aren't doing anything special with escaped slashes. this bit of the spec is hazy.
    # { for the editor
    my @uri_capture_names = ($uri_template =~ m!\{([^}]+)\}!g);

    my ($valid, %seen) = (1);
    foreach my $name (@uri_capture_names) {
      $valid = E({ %$state, keyword => 'url', data_path => '/request/uri',
            schema_path => jsonp($state->{schema_path}, @$more_schema_path, $index),
            defined $base_schema_uri ? (initial_schema_uri => $base_schema_uri) : () },
          'duplicate template name "%s" in server url and path template', $name)
        if $seen{$name}++;
    }
    return if not $valid;

    my %captures;
    @captures{@uri_capture_names} = @uri_capture_values;

    foreach my $name (@uri_capture_names) {
      next if not exists((($server->{variables}//{})->{$name}//{})->{enum});

      $valid = E({ %$state, data_path => '/request/uri', keyword => 'enum',
            schema_path => jsonp($state->{schema_path}, @$more_schema_path, $index, 'variables', $name),
            defined $base_schema_uri ? (initial_schema_uri => $base_schema_uri) : () },
          'server url value does not match any of the allowed values')
        if none { $captures{$name} eq $_ } $server->{variables}{$name}{enum}->@*;
    }

    return if not $valid;
    return \%captures;
  }

  # no match against any servers urls
  return;
}

sub _validate_path_parameter ($self, $state, $param_obj, $path_captures) {
  # 'required' is always true for path parameters
  return E({ %$state, data_path => $state->{data_path} =~ s{/$param_obj->{name}$}{}r, keyword => 'required' },
      'missing path parameter: %s', $param_obj->{name})
    if not exists $path_captures->{$param_obj->{name}};

  my $value = $path_captures->{$param_obj->{name}};
  $value .= '';

  return $self->_validate_parameter_content({ %$state, depth => $state->{depth}+1 }, $param_obj, \$value)
    if exists $param_obj->{content};

  return E({ %$state, keyword => 'style' }, 'only style: simple is supported in path parameters')
    if ($param_obj->{style}//'simple') ne 'simple';

  my $types = $self->_type_in_schema($param_obj->{schema}, { %$state, schema_path => $state->{schema_path}.'/schema' });
  if (grep $_ eq 'array', @$types or grep $_ eq 'object', @$types) {
    return E($state, 'deserializing to non-primitive types is not yet supported in path parameters');
  }

  $self->_evaluate_subschema(\$value, $param_obj->{schema}, { %$state, schema_path => $state->{schema_path}.'/schema', stringy_numbers => 1, depth => $state->{depth}+1 });
}

sub _validate_query_parameter ($self, $state, $param_obj, $uri) {
  # parse the query parameters out of uri
  my $query_params = +{ $uri->query->pairs->@* };

  if (not exists $query_params->{$param_obj->{name}}) {
    return E({ %$state, data_path => $state->{data_path} =~ s{/$param_obj->{name}$}{}r, keyword => 'required' },
        'missing query parameter: %s', $param_obj->{name})
      if $param_obj->{required};
    return 1;
  }

  return $self->_validate_parameter_content({ %$state, depth => $state->{depth}+1 }, $param_obj, \ $query_params->{$param_obj->{name}})
    if exists $param_obj->{content};

  # §4.8.12.2.1: "If `true`, clients MAY pass a zero-length string value in place of parameters that
  # would otherwise be omitted entirely, which the server SHOULD interpret as the parameter being
  # unused."
  return if $param_obj->{allowEmptyValue}
    and ($param_obj->{style}//'form') eq 'form'
    and not length($query_params->{$param_obj->{name}});

  # TODO: check 'allowReserved'; difficult to do without access to the raw request string

  # TODO: support different styles.
  # for now, we only support style=form and do not allow for multiple values per
  # property (i.e. 'explode' is not checked at all.)
  # (other possible style values: spaceDelimited, pipeDelimited, deepObject)

  return E({ %$state, keyword => 'style' }, 'only style: form is supported in query parameters')
    if ($param_obj->{style}//'form') ne 'form';

  my $types = $self->_type_in_schema($param_obj->{schema}, { %$state, schema_path => $state->{schema_path}.'/schema' });
  if (grep $_ eq 'array', @$types or grep $_ eq 'object', @$types) {
    return E($state, 'deserializing to non-primitive types is not yet supported in query parameters');
  }

  $state = { %$state, schema_path => $state->{schema_path}.'/schema', stringy_numbers => 1, depth => $state->{depth}+1 };
  $self->_evaluate_subschema(\ $query_params->{$param_obj->{name}}, $param_obj->{schema}, $state);
}

# validates a header, from either the request or the response
sub _validate_header_parameter ($self, $state, $header_name, $header_obj, $headers) {
  return 1 if grep fc $header_name eq fc $_, qw(Accept Content-Type Authorization);

  if (not $headers->every_header($header_name)->@*) {
    return E({ %$state, data_path => $state->{data_path} =~ s{/$header_name$}{}r,
        keyword => 'required' }, 'missing header: %s', $header_name)
      if $header_obj->{required};
    return 1;
  }

  # validate as a single comma-concatenated string, presumably to be decoded
  return $self->_validate_parameter_content({ %$state, depth => $state->{depth}+1 }, $header_obj, \ $headers->header($header_name))
    if exists $header_obj->{content};

  # RFC9112 §5.1-3: "The field line value does not include that leading or trailing whitespace: OWS
  # occurring before the first non-whitespace octet of the field line value, or after the last
  # non-whitespace octet of the field line value, is excluded by parsers when extracting the field
  # line value from a field line."
  my @values = map s/^\s*//r =~ s/\s*$//r, map split(/,/, $_), $headers->every_header($header_name)->@*;

  my $types = $self->_type_in_schema($header_obj->{schema}, { %$state, schema_path => $state->{schema_path}.'/schema' });

  # RFC9110 §5.3-1: "A recipient MAY combine multiple field lines within a field section that have
  # the same field name into one field line, without changing the semantics of the message, by
  # appending each subsequent field line value to the initial field line value in order, separated
  # by a comma (",") and optional whitespace (OWS, defined in Section 5.6.3). For consistency, use
  # comma SP."
  my $data;
  if (grep $_ eq 'array', @$types) {
    # style=simple, explode=false or true: "blue,black,brown" -> ["blue","black","brown"]
    $data = \@values;
  }
  elsif (grep $_ eq 'object', @$types) {
    if ($header_obj->{explode}//false) {
      # style=simple, explode=true: "R=100,G=200,B=150" -> { "R": 100, "G": 200, "B": 150 }
      $data = +{ map m/^([^=]*)=?(.*)$/g, @values };
    }
    else {
      # style=simple, explode=false: "R,100,G,200,B,150" -> { "R": 100, "G": 200, "B": 150 }
      $data = +{ @values, (@values % 2 ? '' : ()) };
    }
  }
  else {
    # when validating as a single string, preserve internal whitespace in each individual header
    # but strip leading/trailing whitespace
    $data = join ', ', map s/^\s*//r =~ s/\s*$//r, $headers->every_header($header_name)->@*;
  }

  $state = { %$state, schema_path => $state->{schema_path}.'/schema', stringy_numbers => 1, depth => $state->{depth}+1 };
  $self->_evaluate_subschema(\ $data, $header_obj->{schema}, $state);
}

sub _validate_cookie_parameter ($self, $state, $param_obj, $request) {
  return E($state, 'cookie parameters not yet supported');
}

sub _validate_parameter_content ($self, $state, $param_obj, $content_ref) {
  abort({ %$state, keyword => 'content' }, 'more than one media type entry present')
    if keys $param_obj->{content}->%* > 1;  # TODO: remove, when the spec schema is updated
  my ($media_type) = keys $param_obj->{content}->%*;  # there can only be one key

  my $media_type_decoder = $self->get_media_type($media_type);  # case-insensitive, wildcard lookup

  return $self->_validate_media_type($state, $param_obj->{content}, $media_type, $media_type_decoder, $content_ref);
}

sub _validate_body_content ($self, $state, $content_obj, $message) {
  # strip charset from Content-Type
  my $content_type = (split(/;/, $message->headers->content_type//'', 2))[0] // '';

  return E({ %$state, data_path => $state->{data_path} =~ s{body}{header}r, keyword => 'content' },
      'missing header: Content-Type')
    if not length $content_type;

  my $media_type = (first { fc($content_type) eq fc } keys $content_obj->%*)
    // (first { m{([^/]+)/\*$} && fc($content_type) =~ m{^\F\Q$1\E/[^/]+$} } keys $content_obj->%*);
  $media_type //= '*/*' if exists $content_obj->{'*/*'};
  return E({ %$state, keyword => 'content', recommended_response => [ 415 ] },
      'incorrect Content-Type "%s"', $content_type)
    if not defined $media_type;

  # §4.8.14.1: "The encoding field SHALL only apply to Request Body Objects, and only when the media
  # type is multipart or application/x-www-form-urlencoded."
  if ($content_type =~ m{^\Fmultipart/} or fc($content_type) eq 'application/x-www-form-urlencoded') {
    if (exists $content_obj->{$media_type}{encoding}) {
      my $state = { %$state, schema_path => jsonp($state->{schema_path}, 'content', $media_type) };
      # §4.8.14.1: "The key, being the property name, MUST exist in the schema as a property."
      foreach my $property (sort keys $content_obj->{$media_type}{encoding}->%*) {
        ()= E({ $state, schema_path => jsonp($state->{schema_path}, 'schema', 'properties', $property) },
            'encoding property "%s" requires a matching property definition in the schema')
          if not exists(($content_obj->{$media_type}{schema}{properties}//{})->{$property});
      }
      return E({ %$state, keyword => 'encoding' }, 'encoding not yet supported');
    }

    return E($state, '%s is not yet supported', $content_type);
  }

  # TODO: handle Content-Encoding header; https://github.com/OAI/OpenAPI-Specification/issues/2868
  my $content_ref = \ $message->body;

  # decode the charset, for text content
  if ($content_type =~ m{^text/} and my $charset = $message->content->charset) {
    try {
      $content_ref = \ Encode::decode($charset, $content_ref->$*, Encode::FB_CROAK | Encode::LEAVE_SRC);
    }
    catch ($e) {
      return E({ %$state, keyword => 'content', _schema_path_suffix => $media_type },
        'could not decode content as %s: %s', $charset, $e =~ s/^(.*)\n/$1/r);
    }
  }

  # use the original Content-Type, NOT the possibly wildcard media type from the openapi document
  # lookup is case-insensitive and falls back to wildcard definitions
  my $media_type_decoder = $self->get_media_type($content_type);

  return $self->_validate_media_type($state, $content_obj, $media_type, $media_type_decoder, $content_ref);
}

sub _validate_media_type ($self, $state, $content_obj, $media_type, $media_type_decoder, $content_ref) {
  $media_type_decoder = sub ($content_ref) { $content_ref } if $media_type eq '*/*';
  if (not $media_type_decoder) {
    # don't fail if the schema would pass on any input
    my $schema = $content_obj->{$media_type}{schema};
    return if not defined $schema or is_plain_hashref($schema) ? !keys %$schema : $schema;

    abort({ %$state, keyword => 'content', _schema_path_suffix => $media_type},
      'EXCEPTION: unsupported media type "%s": add support with $openapi->add_media_type(...)', $media_type);
  }

  try {
    $content_ref = $media_type_decoder->($content_ref);
  }
  catch ($e) {
    return E({ %$state, keyword => 'content', _schema_path_suffix => $media_type },
      'could not decode content as %s: %s', $media_type, $e =~ s/^(.*)\n/$1/r);
  }

  return if not exists $content_obj->{$media_type}{schema};

  $state = { %$state, schema_path => jsonp($state->{schema_path}, 'content', $media_type, 'schema'), depth => $state->{depth}+1 };
  $self->_evaluate_subschema($content_ref, $content_obj->{$media_type}{schema}, $state);
}

# wrap a result object around the errors
sub _result ($self, $state, $is_exception = 0, $is_response = 0) {
  croak 'no errors provided for exception' if $is_exception and not $state->{errors}->@*;
  return JSON::Schema::Modern::Result->new(
    output_format => $self->evaluator->output_format,
    formatted_annotations => 0,
    valid => !$state->{errors}->@*,
    $is_exception ? ( exception => 1 ) : (), # -> recommended_response: [ 500, 'Internal Server Error' ]
    !$state->{errors}->@*
      ? (annotations => $state->{annotations}//[])
      : (errors => $state->{errors}),
    $is_response ? ( recommended_response => undef ) : (),  # responses don't have responses
  );
}

sub _resolve_ref ($self, $entity_type, $ref, $state) {
  my $uri = Mojo::URL->new($ref)->to_abs($state->{initial_schema_uri});
  my $schema_info = $self->evaluator->_fetch_from_uri($uri);
  abort({ %$state, keyword => '$ref' }, 'EXCEPTION: unable to find resource "%s"', $uri)
    if not $schema_info;

  abort({ %$state, keyword => '$ref' }, 'EXCEPTION: maximum evaluation depth exceeded')
    if $state->{depth}++ > $self->evaluator->max_traversal_depth;

  abort({ %$state, keyword => '$ref' }, 'EXCEPTION: bad $ref to %s: not a "%s"', $schema_info->{canonical_uri}, $entity_type)
    if $schema_info->{document}->get_entity_at_location($schema_info->{document_path}) ne $entity_type;

  $state->{initial_schema_uri} = $schema_info->{canonical_uri};
  $state->{traversed_schema_path} = $state->{traversed_schema_path}.$state->{schema_path}.'/$ref';
  $state->{schema_path} = '';

  return $schema_info->{schema};
}

# determines the type(s) requested in a schema, and the new schema.
sub _type_in_schema ($self, $schema, $state) {
  return [] if not is_plain_hashref($schema);

  while (my $ref = $schema->{'$ref'}) {
    $schema = $self->_resolve_ref('schema', $ref, $state);
  }
  my $types = is_plain_hashref($schema) ? $schema->{type}//[] : [];
  $types = [ $types ] if not is_plain_arrayref($types);

  return $types;
}

# evaluates data against the subschema at the current state location
sub _evaluate_subschema ($self, $dataref, $schema, $state) {
  # boolean schema
  if (not is_plain_hashref($schema)) {
    return 1 if $schema;

    my @location = unjsonp($state->{data_path});
    my $location =
        $location[-1] eq 'body' ? join(' ', @location[-2..-1])
      : $location[-2] eq 'query' ? 'query parameter'
      : $location[-2] eq 'path' ? 'path parameter'  # this should never happen
      : $location[-2] eq 'header' ? join(' ', @location[-3..-2])
      : $location[-2];  # cookie
    return E($state, '%s not permitted', $location);
  }

  return 1 if !keys(%$schema);  # schema is {}

  # this is not necessarily the canonical uri of the location, but it is still a valid location
  my $uri = $state->{initial_schema_uri}->clone;
  $uri->fragment(($uri->fragment//'').$state->{schema_path});

  my $result = $self->evaluator->evaluate(
    $dataref->$*,
    # reference by uri ensures all schema information is available to the evaluator, e.g. dialect
    $uri,
    {
      data_path => $state->{data_path},
      traversed_schema_path => $state->{traversed_schema_path}.$state->{schema_path},
      $state->{stringy_numbers} ? ( stringy_numbers => 1 ) : (),
    },
  );

  push $state->{errors}->@*, $result->errors;
  push $state->{annotations}->@*, $result->annotations;

  return $result;
}

# results may be unsatisfactory if not a valid HTTP request.
sub _convert_request ($request) {
  return $request if $request->isa('Mojo::Message::Request');

  my $req = Mojo::Message::Request->new;

  if ($request->isa('HTTP::Request')) {
    $req->parse($request->as_string);
  }
  elsif ($request->isa('Plack::Request') or $request->isa('Catalyst::Request')) {
    $req->parse($request->env);

    my $plack_request = $request->isa('Plack::Request') ? $request
      : do { +require Plack::Request; Plack::Request->new($request->env) };

    my $body = $plack_request->content;
    $req->parse($body) if length $body;

    # Plack is unable to distinguish between %2F and /, so the raw (undecoded) uri can be passed
    # here. see PSGI::FAQ
    $req->url(Mojo::URL->new($request->env->{REQUEST_URI})) if exists $request->env->{REQUEST_URI};
  }
  else {
    return $req->error({ message => 'unknown type '.ref($request) });
  }

  # we could call $req->fix_headers here to add a missing Content-Length, but proper requests from
  # the network should always have it set.

  warn 'parse error when converting '.ref($request) if not $req->is_finished;
  return $req;
}

# results may be unsatisfactory if not a valid HTTP response.
sub _convert_response ($response) {
  return $response if $response->isa('Mojo::Message::Response');

  my $res = Mojo::Message::Response->new;

  if ($response->isa('HTTP::Response')) {
    $res->parse($response->as_string);
    warn 'parse error when converting HTTP::Response' if not $res->is_finished;
  }
  elsif ($response->isa('Plack::Response')) {
    $res->code($response->status);
    $res->headers->add(@$_) foreach pairs $response->headers->psgi_flatten_without_sort->@*;
    my $body = $response->body;
    $res->body($body) if length $body;
  }
  elsif ($response->isa('Catalyst::Response')) {
    $res->code($response->status);
    HTTP::Headers->VERSION('6.07');
    $res->headers->add(@$_) foreach pairs $response->headers->flatten;
    my $body = $response->body;
    $res->body($body) if length $body;
  }
  else {
    return $res->error({ message => 'unknown type '.ref($response) });
  }

  # we could call $res->fix_headers here to add a missing Content-Length, but proper responses from
  # the network should always have it set.

  return $res;
}

# callback hook for Sereal::Encoder
sub FREEZE ($self, $serializer) { +{ %$self } }

# callback hook for Sereal::Decoder
sub THAW ($class, $serializer, $data) {
  my $self = bless($data, $class);

  foreach my $attr (qw(openapi_document evaluator)) {
    die "serialization missing attribute '$attr': perhaps your serialized data was produced for an older version of $class?"
      if not exists $self->{$attr};
  }

  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenAPI::Modern - Validate HTTP requests and responses against an OpenAPI v3.1 document

=head1 VERSION

version 0.087

=head1 SYNOPSIS

  my $openapi = OpenAPI::Modern->new(
    openapi_uri => 'https://prod.example.com/api',
    openapi_schema => YAML::PP->new(boolean => 'JSON::PP')->load_string(<<'YAML'));
  openapi: 3.1.1
  info:
    title: Test API
    version: 1.2.3
  paths:
    /foo/{foo_id}:
      servers:
        - url: https://{host}.example.com
          variables:
            host:
              default: prod
              enum: [dev, stg, prod]
      parameters:
      - name: foo_id
        in: path
        required: true
        schema:
          pattern: ^[a-z]+$
      post:
        operationId: my_foo_request
        parameters:
        - name: My-Request-Header
          in: header
          required: true
          schema:
            pattern: ^[0-9]+$
        requestBody:
          required: true
          content:
            application/json:
              schema:
                type: object
                properties:
                  hello:
                    type: string
                    pattern: ^[0-9]+$
        responses:
          200:
            description: success
            headers:
              My-Response-Header:
                required: true
                schema:
                  pattern: ^[0-9]+$
            content:
              application/json:
                schema:
                  type: object
                  required: [ status ]
                  properties:
                    status:
                      const: ok
  YAML

  say 'request:';
  my $request = Mojo::Message::Request->new;
  $request->url->parse("https://dev.example.com/foo/bar");
  $request->headers('My-Request-Header' => '123');
  $request->headers('Content-Type' => 'application/json');
  $request->body('{"hello": 123}');
  my $results = $openapi->validate_request($request);
  say $results;
  say ''; # newline
  say JSON::MaybeXS->new(convert_blessed => 1, canonical => 1, pretty => 1, indent_length => 2)->encode($results);

  say 'response:';
  my $response = Mojo::Message::Response->new(code => 200, message => 'OK');
  $response->headers->content_type('application/json');
  $response->headers->header('My-Response-Header', '123');
  $response->body('{"status": "ok"}');
  $results = $openapi->validate_response($response, { request => $request });
  say $results;
  say ''; # newline
  say JSON::MaybeXS->new(convert_blessed => 1, canonical => 1, pretty => 1, indent_length => 2)->encode($results);

prints:

  request:
  '/request/body/hello': got integer, not string
  '/request/body': not all properties are valid

  {
    "errors" : [
      {
        "absoluteKeywordLocation" : "https://production.example.com/api#/paths/~1foo~1%7Bfoo_id%7D/post/requestBody/content/application~1json/schema/properties/hello/type",
        "error" : "got integer, not string",
        "instanceLocation" : "/request/body/hello",
        "keywordLocation" : "/paths/~1foo~1{foo_id}/post/requestBody/content/application~1json/schema/properties/hello/type"
      },
      {
        "absoluteKeywordLocation" : "https://production.example.com/api#/paths/~1foo~1%7Bfoo_id%7D/post/requestBody/content/application~1json/schema/properties",
        "error" : "not all properties are valid",
        "instanceLocation" : "/request/body",
        "keywordLocation" : "/paths/~1foo~1{foo_id}/post/requestBody/content/application~1json/schema/properties"
      }
    ],
    "valid" : false
  }

  response:
  valid

  {
    "valid" : true
  }

=head1 DESCRIPTION

This module provides various tools for working with an
L<OpenAPI Specification v3.1 document|https://spec.openapis.org/oas/v3.1#openapi-document> within
your application. The JSON Schema evaluator is fully specification-compliant; the OpenAPI evaluator
aims to be but some features are not yet available. My belief is that missing features are better
than features that seem to work but actually cut corners for simplicity.

=for Pod::Coverage BUILDARGS FREEZE THAW

=for stopwords schemas jsonSchemaDialect metaschema subschema perlish operationId openapi Mojolicious

=head1 CONSTRUCTOR ARGUMENTS

If construction of the object is not successful, for example the document has a syntax error, the
call to C<new()> will throw an exception, which will likely be a L<JSON::Schema::Modern::Result>
object containing details.

Unless otherwise noted, these are also available as read-only accessors.

=head2 openapi_uri

The URI that identifies the OpenAPI document; an alias to C<< ->openapi_document->canonical_uri >>.
See L<JSON::Schema::Modern::Document::OpenAPI/canonical_uri>.
Ignored if L</openapi_document> is provided.

This URI will be used at runtime to resolve relative URIs used in
the OpenAPI document, such as for C<jsonSchemaDialect> or C<servers url> values, as well as used
for locations in L<JSON::Schema::Modern::Result> objects (see below).

The value of C<$self> in the document (if present) is resolved against this value.
It is strongly recommended that this URI is absolute.

=head2 openapi_schema

The data structure describing the OpenAPI v3.1 document (as specified at
L<https://spec.openapis.org/oas/v3.1>); an alias to C<< ->openapi_document->schema >>.
See L<JSON::Schema::Modern::Document::OpenAPI/schema>.
Ignored if L</openapi_document> is provided.

=head2 openapi_document

The L<JSON::Schema::Modern::Document::OpenAPI> document that holds the OpenAPI information to be
used for validation. If it is not provided to the constructor, then both L</openapi_uri> and
L</openapi_schema> B<MUST> be provided, and L</evaluator> will also be used if provided.

=head2 evaluator

The L<JSON::Schema::Modern> object to use for all URI resolution and JSON Schema evaluation.
Ignored if L</openapi_document> is provided. Optional (a default is constructed when omitted).

=head2 debug

Boolean; defaults to false (can also be set via C<$DEBUG>).

When set, useful diagnostic information is stored in the C<$options> hash used in public methods
described below.

=head1 METHODS

=head2 document_get

  my $parameter_data = $openapi->document_get('/paths/~1foo~1{foo_id}/get/parameters/0');

Fetches the subschema at the provided JSON pointer.
Proxies to L<JSON::Schema::Modern::Document::OpenAPI/get>.
This is not recursive (does not follow C<$ref> chains) -- for that, use
C<< $openapi->recursive_get(Mojo::URL->new->fragment($json_pointer)) >>, see
L</recursive_get>.

=head2 validate_request

  $result = $openapi->validate_request(
    $request,
    # optional second argument can contain any combination of:
    my $options = {
      path_template => '/foo/{arg1}/bar/{arg2}',
      operation_id => 'my_operation_id',
      path_captures => { arg1 => 1, arg2 => 2 },
      method => 'get',
    },
  );

Validates an L<HTTP::Request>, L<Plack::Request>, L<Catalyst::Request> or L<Mojo::Message::Request>
object against the corresponding OpenAPI v3.1 document, returning a
L<JSON::Schema::Modern::Result> object.

Absolute URIs in the result object are constructed by resolving the openapi document path against
the L</openapi_uri> (which is derived from the document's C<$self> keyword as well as the URI
provided to the document constructor).

The second argument is an optional hashref that contains extra information about the request,
corresponding to the values expected by L</find_path> below. The method populates the hashref
with some information about the request:
save it and pass it to a later L</validate_response> call (that corresponds to a response for this request)
to improve performance.

=head2 validate_response

  $result = $openapi->validate_response(
    $response,
    {
      path_template => '/foo/{arg1}/bar/{arg2}',
      request => $request,
    },
  );

Validates an L<HTTP::Response>, L<Plack::Response>, L<Catalyst::Response> or L<Mojo::Message::Response>
object against the corresponding OpenAPI v3.1 document, returning a
L<JSON::Schema::Modern::Result> object.

Absolute URIs in the result object are constructed by resolving the openapi document path against
the L</openapi_uri> (which is derived from the document's C<$self> keyword as well as the URI
provided to the document constructor).

The second argument is an optional hashref that contains extra information about the request
corresponding to the response, as in L</find_path>.

C<request> is also accepted as a key in the hashref, representing the original request object that
corresponds to this response (as not all HTTP libraries link to the request in the response object).

=head2 find_path

  $result = $self->find_path($options);

Finds the appropriate entry in the OpenAPI document corresponding to a request. Called
internally by both L</validate_request> and L</validate_response>.

The single argument is a hashref that contains information about the request. Possible values
include:

=over 4

=item *

C<request>: the object representing the HTTP request. Should be provided when available. Supported types are: L<HTTP::Request>, L<Plack::Request>, L<Catalyst::Request>, L<Mojo::Message::Request>.

=item *

C<path_template>: a string representing the request URI, with placeholders in braces (e.g. C</pets/{petId}>); see L<https://spec.openapis.org/oas/v3.1#paths-object>.

=item *

C<operation_id>: a string corresponding to the L<operationId|https://learn.openapis.org/specification/paths.html#the-endpoints-list> at a particular path-template and HTTP location under C</paths>. In the case of ambiguous matches (such as the possibility of more than one C<path_template> matching the request URI), providing this value will serve to unambiguously state which path-item and operation are intended, and is also more efficient as not all path-item entries need to be searched to find a match.

=item *

C<path_captures>: a hashref mapping placeholders in the path template to their actual values in the request URI

=item *

C<method>: the HTTP method used by the request (used case-insensitively)

=item *

C<debug>: when C<$OpenAPI::Modern::DEBUG> or L</debug> is set on the OpenAPI::Modern object, additional diagnostic information is stored here in separate keys:

=over 4

=item *

C<uri_patterns>: an arrayref of patterns that are attempted to be matched against the URI

=back

=back

All of these values are optional (unless C<request> is omitted), and will be derived from the
request as needed (albeit less
efficiently than if they were provided). All passed-in values MUST be consistent with each other and
the request or the return value from this method is false and appropriate errors will be included
in the C<$options> hash.

When successful, the options hash will be populated (or updated) with all the above keys,
and the return value is true.
When not successful, the options hash will be populated with key C<errors>, an arrayref containing
a L<JSON::Schema::Modern::Error> object, and the return value is false.

In addition, these values are also populated in the options hash (when available):

=over 4

=item *

C<uri_captures>: a hashref mapping placeholders in the entire uri template (server url plus path template) to their actual values in the request URI

=item *

C<operation_uri>: a URI indicating the document location of the operation object for the request, after following any references (usually something under C</paths/>, but may be in another document). Use C<< $openapi->evaluator->get($uri) >> to fetch this content (see L<JSON::Schema::Modern/get>). Note that this is the same as C<< $openapi->recursive_get(Mojo::URL->new->fragment(JSON::Schema::Modern::Utilities::jsonp('/paths', $options->{path_template}{$options->{method}}))) >>. (See the documentation for an operation at L<https://learn.openapis.org/specification/paths.html#the-endpoints-list> or in the specification at L<§4.8.10 of the specification|https://spec.openapis.org/oas/v3.1#operation-object>.)

=item *

C<request> (not necessarily what was passed in: this is always a L<Mojo::Message::Request>)

=back

You can find the associated operation object in the OpenAPI document by using either C<operation_uri>,
or by calling C<< $openapi->openapi_document->get_operationId_path($operation_id) >>
(see L<JSON::Schema::Modern::Document::OpenAPI/get_operationId_path>) (note that the latter will
be changed in a subsequent release, in order to support operations existing in other documents).

=head2 recursive_get

Given a uri or uri-reference (resolved against the main OpenAPI document's C<canonical_uri>),
get the definition at that location, following any C<$ref>s along the
way. Include the expected definition type
(one of C<schema>, C<response>, C<parameter>, C<example>, C<request-body>, C<header>,
C<security-scheme>, C<link>, C<callbacks>, or C<path-item>)
for validation of the entire reference chain.

Returns the data in scalar context, or a tuple of the data and the canonical URI of the
referenced location in list context.

If the provided location is relative, the main openapi document is used for the base URI.
If you have a local json pointer you want to resolve, you can turn it into a uri-reference by
prepending C<#> and url-encoding it, e.g. C<< Mojo::URL->new->fragment($jsonp) >>.

  my $param = $openapi->recursive_get('#/components/parameters/Content-Encoding', 'parameter');
  my $operation_schema = $openapi->recursive_get(Mojo::URL->new('https://example.com/api.json')
    ->fragment(jsonp(qw(/paths /foo/{foo_id} get requestBody content application/json schema)));

  # starts with a JSON::Schema::Modern object (TODO)
  my $schema = $js->recursive_get('https:///openapi_doc.yaml#/components/schemas/my_object')
  my $schema = $js->recursive_get('https://localhost:1234/my_spec#/$defs/my_object')

=head2 canonical_uri

An accessor that delegates to L<JSON::Schema::Modern::Document/canonical_uri>.

=head2 schema

An accessor that delegates to L<JSON::Schema::Modern::Document/schema>.

=head2 get_media_type

An accessor that delegates to L<JSON::Schema::Modern/get_media_type>.

=head2 add_media_type

A setter that delegates to L<JSON::Schema::Modern/add_media_type>.

=head1 CACHING

=for stopwords preforking

Very large OpenAPI documents may take a noticeable time to be
loaded and parsed. You can reduce the impact to your preforking application by loading all necessary
documents at startup, and impact can be further reduced by saving objects to cache and then
reloading them (perhaps by using a timestamp or checksum to determine if a fresh reload is needed).

  sub get_openapi (...) {
    my $serialized_file = Path::Tiny::path($serialized_filename);
    my $openapi_file = Path::Tiny::path($openapi_filename);
    my $openapi;
    if ($serialized_file->stat->mtime < $openapi_file->stat->mtime)) {
      $openapi = OpenAPI::Modern->new(
        openapi_uri => '/api',
        openapi_schema => decode_json($openapi_file->slurp_raw), # your openapi document
      );
      $openapi->evaluator->add_schema(decode_json(...));  # any other needed schemas
      my $frozen = Sereal::Encoder->new({ freeze_callbacks => 1 })->encode($openapi);
      $serialized_file->spew_raw($frozen);
    }
    else {
      my $frozen = $serialized_file->slurp_raw;
      $openapi = Sereal::Decoder->new->decode($frozen);
    }

    # add custom format validations, media types and encodings here
    $openapi->evaluator->add_media_type(...);

    return $openapi;
  }

See also L<JSON::Schema::Modern/CACHING>.

=head1 ON THE USE OF JSON SCHEMAS

Embedded JSON Schemas, through the use of the C<schema> keyword, are fully draft2020-12-compliant,
as per the spec, and implemented with L<JSON::Schema::Modern>. Unless overridden with the use of the
L<jsonSchemaDialect|https://spec.openapis.org/oas/v3.1#specifying-schema-dialects> keyword, their
metaschema is L<https://spec.openapis.org/oas/3.1/dialect/base>, which allows for use of the
OpenAPI-specific keywords (C<discriminator>, C<xml>, C<externalDocs>, and C<example>), as defined in
L<the specification/https://spec.openapis.org/oas/v3.1#schema-object>. Format validation is turned
B<on>, and the use of content* keywords is off (see
L<JSON::Schema::Modern/validate_content_schemas>).

References (with the C<$ref>) keyword may reference any position within the entire OpenAPI document;
as such, json pointers are relative to the B<root> of the document, not the root of the subschema
itself. References to other documents are also permitted, provided those documents have been loaded
into the evaluator in advance (see L<JSON::Schema::Modern/add_schema>).

Values are generally treated as strings for the purpose of schema evaluation. However, if the top
level of the schema contains C<"type": "number"> or C<"type": "integer">, then the value will be
(attempted to be) coerced into a number before being passed to the JSON Schema evaluator.
Type coercion will B<not> be done if the C<type> keyword is omitted.
This lets you use numeric keywords such as C<maximum> and C<multipleOf> in your schemas.
It also resolves inconsistencies that can arise when request and response objects are created
manually in a test environment (as opposed to being parsed from incoming network traffic) and can
therefore inadvertently contain perlish numbers rather than strings.

=head1 LIMITATIONS

All message validation is done using L<Mojolicious> objects (L<Mojo::Message::Request> and
L<Mojo::Message::Response>). If messages of other types are passed, conversion is done on a
best-effort basis, but since different implementations have different levels of adherence to the RFC
specs, some validation errors may occur e.g. if a certain required header is missing on the
original. For best results in validating real messages from the network, parse them directly into
Mojolicious messages (see L<Mojo::Message/parse>).

Only certain permutations of OpenAPI documents are supported at this time:

=over 4

=item *

for path parameters, only C<style: simple> and C<explode: false> is supported

=item *

for query parameters, only C<style: form> and C<explode: true> is supported, only the first value of each parameter name is considered, and C<allowEmptyValue> and C<allowReserved> are not checked

=item *

cookie parameters are not checked at all yet

=item *

C<application/x-www-form-urlencoded> and C<multipart/*> messages are not yet supported

=item *

OpenAPI descriptions must be contained in a single document; C<$ref>erences to other documents are not fully supported at this time.

=item *

The use of C<$ref> within a path-item object is only allowed when not adjacent to any other path-item properties (C<parameters>, C<servers>, request methods)

=item *

Security schemes in the OpenAPI description, and the use of any C<Authorization> headers in requests, are not currently supported.

=back

=head1 SEE ALSO

=over 4

=item *

L<Mojolicious::Plugin::OpenAPI::Modern>

=item *

L<Test::Mojo::Role::OpenAPI::Modern>

=item *

L<JSON::Schema::Modern::Document::OpenAPI>

=item *

L<JSON::Schema::Modern>

=item *

L<https://json-schema.org>

=item *

L<https://www.openapis.org/>

=item *

L<https://learn.openapis.org/>

=item *

L<https://spec.openapis.org/oas/v3.1>

=back

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
