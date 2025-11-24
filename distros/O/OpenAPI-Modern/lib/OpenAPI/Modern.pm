use strictures 2;
package OpenAPI::Modern; # git description: v0.106-6-g819d02fa
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Validate HTTP requests and responses against an OpenAPI v3.1 or v3.2 document
# KEYWORDS: validation evaluation JSON Schema OpenAPI v3.1 v3.2 Swagger HTTP request response

our $VERSION = '0.107';

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
use List::Util qw(first pairs);
use if "$]" < 5.041010, 'List::Util' => 'any';
use if "$]" >= 5.041010, experimental => 'keyword_any';
use Scalar::Util 'looks_like_number';
use builtin::compat 'indexed';
use Feature::Compat::Try;
use Encode 2.89 ();
use JSON::Schema::Modern;
use JSON::Schema::Modern::Utilities qw(jsonp unjsonp canonical_uri E abort is_equal is_elements_unique true false);
use OpenAPI::Modern::Utilities qw(add_vocab_and_default_schemas);
use JSON::Schema::Modern::Document::OpenAPI;
use MooX::TypeTiny 0.002002;
use Types::Standard qw(InstanceOf Bool);
use Mojo::Util qw(url_unescape punycode_decode);
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

  croak 'missing required constructor arguments: either openapi_document or openapi_schema'
    if not exists $args->{openapi_document} and not exists $args->{openapi_schema};

  my $had_document = exists $args->{openapi_document};

  $args->{evaluator} //= JSON::Schema::Modern->new(validate_formats => 1, max_traversal_depth => 80);

  $args->{openapi_document} //= JSON::Schema::Modern::Document::OpenAPI->new(
    exists $args->{openapi_uri} ? (canonical_uri => $args->{openapi_uri}) : (),
    schema => $args->{openapi_schema},
    evaluator => $args->{evaluator},
  );

  # add the OpenAPI vacabulary, formats and metaschemas to the evaluator if they weren't there already
  add_vocab_and_default_schemas($args->{evaluator}) if $had_document;

  # if there were errors, this will die with a JSON::Schema::Modern::Result object
  $args->{evaluator}->add_document($args->{openapi_document});

  return $args;
};

sub validate_request ($self, $request, $options = {}) {
  croak 'missing request' if not $request;

  croak '$request and $options->{request} are inconsistent'
    if $options->{request} and $request != $options->{request};

  # mostly populated by find_path_item
  my $state = { data_path => '/request' };

  try {
    $options->{request} //= $request;
    my $path_ok = $self->find_path_item($options, $state);
    delete $options->{errors};

    # Reporting a failed find_path_item as an exception will result in a recommended response of
    # [ 500, Internal Server Error ], which is warranted if we consider the lack of a specification
    # entry for this incoming request as an unexpected, server-side error.
    # Callers can decide if this should instead be reported as a [ 404, Not Found ], but that sort
    # of response is likely to leave oversights in the specification go unnoticed.
    return $self->_result($state, 1) if not $path_ok;

    $request = $options->{request};   # now guaranteed to be a Mojo::Message::Request

    my $path_item = delete $options->{_path_item};  # after following path-item $refs
    my $operation = delete $options->{_operation};
    my $ops = delete $options->{_operation_path_suffix};   # jsonp-encoded

    # PARAMETERS
    # { $in => { $name => path-item|operation } }  as we process each one.
    my $request_parameters_processed = {};
    my %seen_q;

    # first, consider parameters at the operation level.
    # parameters at the path-item level are also considered, if not already seen at the operation level
    SECTION:
    foreach my $section (qw(operation path-item)) {
      ENTRY:
      foreach my $idx (0 .. (($section eq 'operation' ? $operation : $path_item)->{parameters}//[])->$#*) {
        my $state = { %$state, keyword_path => $state->{keyword_path}.($section eq 'operation' ? $ops : '').'/parameters/'.$idx };
        my $param_obj = ($section eq 'operation' ? $operation : $path_item)->{parameters}[$idx];
        while (defined(my $ref = $param_obj->{'$ref'})) {
          $param_obj = $self->_resolve_ref('parameter', $ref, $state);
        }

        my $fc_name = $param_obj->{in} eq 'header' ? fc($param_obj->{name}) : $param_obj->{name};

        abort($state, 'duplicate %s parameter "%s"', $param_obj->{in}, $param_obj->{name})
          if (($request_parameters_processed->{$param_obj->{in}}//{})->{$fc_name} // '') eq $section;

        ++$seen_q{$param_obj->{in}};
        abort({ %$state, data_path => '/request/uri/query' }, 'cannot use query and querystring together')
          if $seen_q{query} and $seen_q{querystring};

        abort({ %$state, data_path => '/request/uri/query' }, 'cannot use more than one querystring')
          if ($seen_q{querystring}//0) >= 2;

        { use autovivification qw(exists store);
          next ENTRY if exists $request_parameters_processed->{$param_obj->{in}}{$fc_name};
          $request_parameters_processed->{$param_obj->{in}}{$fc_name} = $section;
        }

        my $valid =
            $param_obj->{in} eq 'path' ? $self->_validate_path_parameter({ %$state, depth => $state->{depth}+1 }, $param_obj, $options->{path_captures})
          : $param_obj->{in} eq 'query' ? $self->_validate_query_parameter({ %$state, depth => $state->{depth}+1 }, $param_obj, $request->url)
          : $param_obj->{in} eq 'header' ? $self->_validate_header_parameter({ %$state, depth => $state->{depth}+1 }, $param_obj->{name}, $param_obj, $request->headers)
          : $param_obj->{in} eq 'cookie' ? $self->_validate_cookie_parameter({ %$state, depth => $state->{depth}+1 }, $param_obj)
          : $param_obj->{in} eq 'querystring' ? $self->_validate_querystring_parameter({ %$state, depth => $state->{depth}+1 }, $param_obj, $request->url)
          : abort($state, 'unrecognized "in" value "%s"', $param_obj->{in});
      }
    }

    # v3.2.0 §4.8.2, "Path Templating": "Each template expression in the path MUST correspond to a path
    # parameter that is included in the Path Item itself and/or in each of the Path Item’s
    # Operations."
    # We could validate this at document parse time, except the path-item can also be reached via a
    # $ref and the referencing path could be from another document and is therefore unknowable until
    # runtime.
    foreach my $path_name (sort keys $options->{path_captures}->%*) {
      abort({ %$state, data_path => jsonp('/request/uri/path', $path_name) },
          'missing path parameter specification for "%s"', $path_name)
        if not exists(($request_parameters_processed->{path}//{})->{$path_name});
    }

    $state->{keyword_path} .= $ops;

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
      $state->{keyword_path} .= '/requestBody';

      while (defined(my $ref = $body_obj->{'$ref'})) {
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
      ()= E($state, 'unspecified body is present in %s request', $request->method)
        if ($request->method eq 'GET' or $request->method eq 'HEAD')
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

  # mostly populated by find_path_item
  my $state = { data_path => '/response' };

  try {
    # we only need the operation location, and do not need to verify the request uri, path template
    # and path_captures, so do not pass unnecessary information to find_path_item
    my $fp_options = +{ %$options };
    delete $fp_options->@{qw(request uri method path_template path_captures)} if exists $options->{operation_id};
    delete $fp_options->@{qw(request uri path_captures)} if exists $options->{path_template} and exists $options->{method};
    my $path_ok = $self->find_path_item($fp_options, $state);
    $options->@{keys $fp_options->%*} = values $fp_options->%*;

    delete $options->@{qw(errors _path_item)};
    my $operation = delete $options->{_operation};

    return $self->_result($state, 1, 1) if not $path_ok;

    $state->{keyword_path} .= delete $options->{_operation_path_suffix};  # jsonp-encoded
    return $self->_result($state, 0, 1) if not exists $operation->{responses};

    $response = _convert_response($response);   # now guaranteed to be a Mojo::Message::Response

    if ($response->headers->header('Transfer-Encoding')) {
      ()= E({ %$state, data_path => '/response/header/Transfer-Encoding' },
        'RFC9112 §6.1-10: "A server MUST NOT send a Transfer-Encoding header field in any response with a status code of 1xx (Informational) or 204 (No Content)"')
        if $response->is_info or $response->code == 204;

      ()= E({ %$state, data_path => '/response/header/Transfer-Encoding' },
        'RFC9112 §6.1-10: "A server MUST NOT send a Transfer-Encoding header field in any 2xx (Successful) response to a CONNECT request"')
        if $response->is_success and $options->{method} eq 'CONNECT';
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
    $state->{keyword_path} = jsonp($state->{keyword_path}, 'responses', $response_name);
    while (defined(my $ref = $response_obj->{'$ref'})) {
      $response_obj = $self->_resolve_ref('response', $ref, $state);
    }

    foreach my $header_name (sort keys(($response_obj->{headers}//{})->%*)) {
      next if fc $header_name eq fc 'Content-Type';
      my $state = { %$state, keyword_path => jsonp($state->{keyword_path}, 'headers', $header_name) };
      my $header_obj = $response_obj->{headers}{$header_name};
      while (defined(my $ref = $header_obj->{'$ref'})) {
        $header_obj = $self->_resolve_ref('header', $ref, $state);
      }

      ()= $self->_validate_header_parameter({ %$state, depth => $state->{depth}+1 },
        $header_name, $header_obj, $response->headers);
    }

    # FIXME: can we have a 'required' property here, just like in request?
    # why do we check for the 'content' property here, and Content-Length, but not for request?

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

# deprecated, but we'll continue to support it
*find_path = \&find_path_item;

sub find_path_item ($self, $options, $state = {}) {
  # there are many $state fields used by JSM that we do not set here because we do not use them for
  # OpenAPI validation, such as document, document_path, vocabularies, specification_version
  $state->{data_path} //= '';
  $state->{initial_schema_uri} = $self->openapi_uri;   # the canonical URI as of the start or last $id, or the last traversed $ref
  $state->{traversed_keyword_path} = '';   # the accumulated traversal path as of the start, or last $id, or up to the last traversed $ref
  $state->{keyword_path} = '';             # the rest of the path, since the last $id or the last traversed $ref
  $state->{errors} = $options->{errors} //= [];
  $state->{annotations} //= [];
  $state->{depth} = 0;
  $state->{debug} = $options->{debug} = {} if $DEBUG or $self->debug;

  return E({ %$state, exception => 1, recommended_response => [ 500 ] },
      'at least one of $options->{request}, ($options->{uri} and $options->{method}), ($options->{path_template} and $options->{method}), or $options->{operation_id} must be provided')
    if not $options->{request}
      and not (exists $options->{uri} and exists $options->{method})
      and not ($options->{path_template} and exists $options->{method})
      and not exists $options->{operation_id};

  # now guaranteed to be a Mojo::Message::Request
  if ($options->{request}) {
    $options->{request} = _convert_request($options->{request});

    # requests don't have response codes, so if 'error' is set, it is some sort of parsing error
    if (my $error = $options->{request}->error) {
      return E({ %$state, data_path => '/request', recommended_response => [ 500 ] }, 'Failed to parse request: %s', $error->{message});
    }

    return E({ %$state, data_path => '/request/uri', recommended_response => [ 500 ] },
        'mismatched uri "%s"', $options->{request}->url)
      if exists $options->{uri} and $options->{request}->url ne $options->{uri};
    $options->{uri} = $options->{request}->url; # a Mojo::URL object

    return E({ %$state, data_path => '/request/method', recommended_response => [ 500 ] },
        'wrong HTTP method "%s"', $options->{request}->method)
      if exists $options->{method} and $options->{request}->method ne $options->{method};
    $options->{method} = $options->{request}->method;
  }
  elsif (exists $options->{uri}) {
    $options->{uri} = Mojo::URL->new($options->{uri}.'') if not $options->{uri}->$_isa('Mojo::URL');
  }

  # method from operation_id from options
  if (exists $options->{operation_id}) {
    # FIXME: what if the operation is defined in another document? Need to look it up across
    # all documents, and localize $state->{initial_schema_uri}
    my $operation_path = $self->openapi_document->operationId_path($options->{operation_id});
    return E({ %$state, recommended_response => [ 500 ] }, 'unknown operation_id "%s"', $options->{operation_id})
      if not $operation_path;

    # The path_template cannot be unambiguously found by looking at the path of the operation:
    # the operation path may be under /components/pathItems or /webhooks, or the intended /paths
    # entry might contain a $ref to this location.
    # We can do a URI -> path_template lookup later on, which will succeed if the operation is
    # reachable from a /paths entry, but as this can possibly match more than once, in order to
    # provide an unambiguous result, provide the operation_id as well.

    # the operation path always ends with the method
    my @parts = unjsonp($operation_path);
    my ($path_item_path, $method) = $parts[-2] ne 'additionalOperations'
          # differentiate between these operation paths:
          # /components/pathItems/additionalOperations/get (method = 'GET') vs
          # /components/pathItems/additionalOperations/additionalOperations/get (method = 'get')
        || $self->openapi_document->get_entity_at_location(jsonp(@parts[0..$#parts-1])) eq 'path-item'
      ? (jsonp(@parts[0..$#parts-1]), uc($parts[-1]))
      : (jsonp(@parts[0..$#parts-2]), $parts[-1]);

    return E({ %$state, ($options->{uri} ? (data_path => '/request/method') : ()), keyword_path => $operation_path.'/operationId' },
        'operation at operation_id does not match %s method "%s"%s',
          $options->{uri} ? 'request' : 'provided HTTP', $options->{method},
          (!$options->{uri} && $options->{method} eq lc $options->{method}
              && exists $self->openapi_document->get($path_item_path)->{$options->{method}}
            ? (' (should be '.uc $options->{method}.')') : ''))
      if exists $options->{method} and $options->{method} ne $method;

    $options->{method} = $method;

    if (not $options->{path_template} and not $options->{uri}) {
      # some operations don't live under a /paths/$path_template (even via a $ref), e.g. webhooks or
      # callbacks, but they are still usable via operationId for validating responses
      $state->{keyword_path} = $path_item_path;
      $options->{_path_item} = $self->document_get($path_item_path);
      $options->{_operation} = $self->document_get($operation_path);
      $options->{_operation_path_suffix} = substr($operation_path, length($path_item_path));

      # FIXME: this is not accurate if the operation lives in another document
      # (and in that case, get_operation_uri_by_id can be returned as-is)
      $options->{operation_uri} = $state->{initial_schema_uri}->clone->fragment($operation_path);
      return 1;
    }
  }

  my $schema = $self->openapi_document->schema;

  # path_template from options
  return E({ %$state, ($options->{uri} ? (data_path => '/request/uri') : ()),
        keyword => 'paths' }, 'missing path "%s"', $options->{path_template})
    if exists $options->{path_template} and not exists $schema->{paths}{$options->{path_template}};

  my $captures;  # hashref of template variable names -> concrete values from the uri

  if (not $options->{path_template} and $options->{uri}) {
    # derive path_template and capture values from the request URI

    foreach my $pt ($self->openapi_document->path_templates->@*) {
      my $local_state = +{ %$state };
      $local_state->{path_item} = $schema->{paths}{$pt};
      $local_state->{keyword_path} = jsonp('/paths', $pt);
      $captures = $self->_match_uri($options->@{qw(method uri)}, $pt, $local_state);

      if ($captures) {
        # a URI can match multiple /paths entries, and an operationId can be reachable from multiple
        # /paths entries, so keep searching until both are a match
        next if exists $options->{operation_id}
          and (not exists $local_state->{operation}{operationId}
            or $local_state->{operation}{operationId} ne $options->{operation_id});

        %$state = %$local_state;
        $options->{path_template} = $pt;
        last;
      }

      # something went wrong, but the match succeeded so we will stop iterating
      if ($local_state->{errors}->@*) {
        %$state = %$local_state;
        $options->{path_template} = $pt;
        $options->@{qw(_path_item _operation _operation_path_suffix)} = $state->@{qw(path_item operation operation_path_suffix)};
        return;
      }
    }

    return E({ %$state, data_path => '/request', keyword => 'paths' },
        'no match found for request %s %s',
        $options->{method}, $options->{uri}->clone->query('')->fragment(undef))
      if not exists $options->{path_template};
  }

  elsif ($options->{uri}) {
    # we were passed path_template in options, and now we verify it against the request URI
    $state->{path_item} = $schema->{paths}{$options->{path_template}};
    $state->{keyword_path} = jsonp('/paths', $options->{path_template});
    $captures = $self->_match_uri($options->@{qw(method uri path_template)}, $state);

    if (not $captures) {
      #  no path-item and operation found that matches the request's method and uri
      delete $options->{operation_id};

      # the initial match succeeded, but something else went wrong
      if ($state->{errors}->@*) {
        $options->@{qw(_path_item _operation _operation_path_suffix)} = $state->@{qw(path_item operation operation_path_suffix)};
        return;
      }

      return E({ %$state, data_path => '/request/uri', recommended_response => [ 500 ] },
        'provided path_template does not match request URI "%s"',
        $options->{uri}->clone->query('')->fragment(undef));
    }

    if (exists $options->{operation_id}
        and (not exists $state->{operation}{operationId}
          or $state->{operation}{operationId} ne $options->{operation_id})) {
      delete $options->@{qw(_path_item _operation _operation_path_suffix path_captures uri_captures operation_uri)};
      return E({ %$state, keyword_path => $state->{keyword_path}.$state->{operation_path_suffix}
          .(exists $state->{operation}{operationId} ? '/operationId' : ''),
          recommended_response => [ 500 ] },
        'provided path_template and operation_id do not match request %s %s',
        $options->{method}, $options->{uri}->clone->query('')->fragment(undef));
    }
  }

  else {
    # we were provided $options->{path_template}, and we have already confirmed that it exists.
    $state->{path_item} = $schema->{paths}{$options->{path_template}};
    $state->{keyword_path} = jsonp('/paths', $options->{path_template});
    while (defined(my $ref = $state->{path_item}{'$ref'})) {
      $state->{path_item} = $self->_resolve_ref('path-item', $ref, $state);
    }

    $state->@{qw(operation operation_path_suffix)} =
        (any { $options->{method} eq $_ } qw(GET PUT POST DELETE OPTIONS HEAD PATCH TRACE QUERY))
      ? ($state->{path_item}{lc $options->{method}}, '/'.lc $options->{method})
      : (($state->{path_item}{additionalOperations}//{})->{$options->{method}}, jsonp('/additionalOperations', $options->{method}));

    return E({ %$state, recommended_response => [ 405 ] },
        'missing operation for HTTP method "%s" under "%s"%s', $options->@{qw(method path_template)},
        exists $options->{method} && $options->{method} eq lc $options->{method}
          && exists $state->{path_item}{$options->{method}} ? (' (should be '.uc $options->{method}.')') : '')
      if not $state->{operation};

    return E({ %$state, keyword_path => $state->{keyword_path}.$state->{operation_path_suffix}
          .(exists $state->{operation}{operationId} ? '/operationId' : ''),
        recommended_response => [ 500 ] },
        'templated operation does not match provided operation_id')
      if exists $options->{operation_id}
        and (not exists $state->{operation}{operationId}
          or $state->{operation}{operationId} ne $options->{operation_id});
  }

  $options->@{qw(_path_item _operation _operation_path_suffix)} = $state->@{qw(path_item operation operation_path_suffix)};

  # if initial_schema_uri still points to the head of the entry document, then we have not followed
  # a $ref and the path-item is located at /paths/<path_template>
  $options->{operation_uri} = $state->{initial_schema_uri}->clone
    ->fragment(($state->{initial_schema_uri}->fragment // $state->{keyword_path}).$options->{_operation_path_suffix});

  $options->{operation_id} = $options->{_operation}{operationId}
    if exists $options->{_operation}{operationId};

  my @path_capture_names = ($options->{path_template} =~ /\{([^{}]+)\}/g);
  return E({ %$state, $options->{uri} ? (data_path => '/request/uri') : (), recommended_response => [ 500 ] }, 'provided path_captures names do not match path template "%s"', $options->{path_template})
    if exists $options->{path_captures}
      and not is_equal([ sort keys $options->{path_captures}->%* ], [ sort @path_capture_names ]);

  return 1 if not $captures;

  my @uri_capture_names = keys %$captures;

  if (exists $options->{uri_captures}) {
    return E({ %$state, $options->{uri} ? (data_path => '/request/uri') : (), recommended_response => [ 500 ] },
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
    croak 'maximum evaluation depth exceeded' if $depth++ > $self->evaluator->max_traversal_depth;
    my $uri = Mojo::URL->new($ref)->to_abs($base);

    my $schema_info = $self->evaluator->_fetch_from_uri($uri);

    croak 'unable to find resource "', $uri, '"' if not $schema_info;
    croak sprintf('bad $ref to %s: not a%s "%s"', $schema_info->{canonical_uri}, ($entity_type =~ /^[aeiou]/ ? 'n' : ''), $entity_type)
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

# given a request's method and uri, and a path_template, check that these match (taking into
# consideration additional information in the current path-item), and extract capture values.
# returns false on error, possibly adding errors to $state.
sub _match_uri ($self, $method, $uri, $path_template, $state) {
  $uri = $uri->clone->fragment(undef)->query('');

  # RFC9112 §3.2.1-3: "If the target URI's path component is empty, the client MUST send "/" as the
  # path within the origin-form of request-target." This also lets us match a path template of "/".
  $uri->path->leading_slash(1); # no effect on stringified URI unless path is empty

  # v3.2.0 §4.8.2, "Path Templating": "The value for these path parameters MUST NOT contain any
  # unescaped “generic syntax” characters described by [RFC3986]: forward slashes (/), question
  # marks (?), or hashes (#)."
  my $path_pattern = join '',
    map +(substr($_, 0, 1) eq '{' ? '([^/?#]*)' : quotemeta($_)), # { for the editor
    split /(\{[^{}]+\})/, $path_template;

  # if the uri doesn't match against the path alone, we can immediately bail (and keep looking for
  # another /paths entry that might match)... this also saves us needless parsing of server objects
  do { use autovivification 'store'; push $state->{debug}{uri_patterns}->@*, $path_pattern.'$' }
    if exists $state->{debug};
  return if $uri !~ m/$path_pattern$/;

  # identify the unmatched part of the request URI, to be later matched against server urls
  my $uri_prefix = substr($uri, 0, -length($&));

  # extract all capture values from path template variables: ($1 .. $n)
  # perldoc perlvar, @-: $n coincides with "substr $_, $-[n], $+[n] - $-[n]" if "$-[n]" is defined
  my @path_capture_values = map _uri_decode(substr($uri, $-[$_], $+[$_]-$-[$_])), 1 .. $#-;

  # we set aside $state for potential restoration because we might still encounter issues later on
  # that require us to keep iterating for another URI match
  my $local_state = +{ %$state };

  while (defined(my $ref = $local_state->{path_item}{'$ref'})) {
    $local_state->{path_item} = $self->_resolve_ref('path-item', $ref, $local_state);
  }

  # v3.2.0 §4.8.1, "Patterned Fields": "In case of ambiguous matching, it’s up to the tooling to
  # decide which one to use."
  # There could be another paths entry that matches this URI that does have this method
  # implemented, so we return false and keep searching. Since we may still match to the wrong URI,
  # the correct operation can be forced to match by explicitly passing the corresponding
  # path_template or (preferably) operationId to be used in the search.

  $local_state->@{qw(operation operation_path_suffix)} =
    (any { $method eq $_ } qw(GET PUT POST DELETE OPTIONS HEAD PATCH TRACE QUERY))
      ? ($local_state->{path_item}{lc $method}, '/'.lc $method)
      : (($local_state->{path_item}{additionalOperations}//{})->{$method}, jsonp('/additionalOperations', $method));

  return if not $local_state->{operation};

  # we need to keep track of the traversed path to the servers object, as well as its absolute
  # location, for usage in error objects
  my ($servers, $more_keyword_path, $base_schema_uri) =
      exists $local_state->{operation}{servers}
        ? ($local_state->{operation}{servers}, $local_state->{operation_path_suffix})
    : exists $local_state->{path_item}{servers}
        ? ($local_state->{path_item}{servers}, '')
    : exists $self->openapi_document->schema->{servers}
        ? ($self->openapi_document->schema->{servers}, '', $self->openapi_uri)
    : ();

  # v3.2.0 §4.1.1, "OpenAPI Object -> servers": "If the servers field is not provided, or is an
  # empty array, the default value would be an array consisting of a single Server Object with a
  # url value of `/`."
  $servers = [{ url => '/' }] if not $servers or not @$servers;

  my @path_capture_names = ($path_template =~ /\{([^{}]+)\}/g);

  foreach my $index_and_server (pairs indexed @$servers) {
    my ($index, $server) = @$index_and_server;

    # We need a full uri to match against the full uri taken from the request (scheme and host)
    # we fall back to using the request's scheme, host and port, otherwise the match can never
    # succeed.
    # But before we apply URI logic to the server url, we must first protect any templated sections
    # so they are not altered by normalization. We use NUL, as it is unchanged in the host during
    # punycode-encoding
    my $normalized_server_url = Mojo::URL->new($server->{url} =~ s/\{[^{}]+\}/\x00/gr)
      ->to_abs($self->openapi_document->retrieval_uri)
      ->to_abs($uri);

    # strips slash if path is '/'; otherwise has no effect on stringified URI
    $normalized_server_url->path->leading_slash(0);

    my $server_pattern = join '',
      map +($_ eq '%00' ? '([^/?#]*)' : quotemeta($_)),
      split /(%00)/, $normalized_server_url;  # all NULs appear as %00 in the stringified form
    do { use autovivification 'store'; push $state->{debug}{uri_patterns}->@*, '^'.$server_pattern }
      if exists $state->{debug};
    next if $uri_prefix !~ m/^$server_pattern$/;

    # extract all capture values from server variables: ($1 .. $n)...
    # perldoc perlvar, @-: $n coincides with "substr $_, $-[n], $+[n] - $-[n]" if "$-[n]" is defined
    my @server_capture_values = map substr($uri_prefix, $-[$_], $+[$_]-$-[$_]), 1 .. $#-;

    # ...and punycode-decode those from the host, and url-unescape those from the path
    my $host_variable_count = ()= ($normalized_server_url->host//'') =~ /\x00/g;
    @server_capture_values = (
      (map +(/^xn--(.+)$/ ? punycode_decode($1) : $_), @server_capture_values[0 .. $host_variable_count-1]),
      (map _uri_decode($_), @server_capture_values[$host_variable_count .. $#server_capture_values]));

    # we have a match, so preserve our new $state values created via _resolve_ref
    %$state = %$local_state;

    my @server_capture_names = ($server->{url} =~ /\{([^{}]+)\}/g);

    my ($valid, %seen) = (1);
    foreach my $name (@server_capture_names, @path_capture_names) {
      # TODO: ideally this should be caught at document load time, but the use of $refs between
      # /paths entries and path-items makes this difficult
      $valid = E({ %$state, keyword => 'url', data_path => '/request/uri',
            defined $base_schema_uri
              ? (initial_schema_uri => $base_schema_uri, traversed_keyword_path => '', keyword_path => '/servers/'.$index)
              : (keyword_path => $state->{keyword_path}.$more_keyword_path.'/servers/'.$index) },
          'duplicate template name "%s" in server url and path template', $name)
        if $seen{$name}++;
    }
    return if not $valid;

    my %captures;
    @captures{@server_capture_names} = @server_capture_values;

    foreach my $name (@server_capture_names) {
      next if not exists((($server->{variables}//{})->{$name}//{})->{enum});

      $valid = E({ %$state, data_path => '/request/uri', keyword => 'enum',
            defined $base_schema_uri
              ? (initial_schema_uri => $base_schema_uri, traversed_keyword_path => '',
                  keyword_path => jsonp('/servers', $index, 'variables', $name))
              : (keyword_path => jsonp($state->{keyword_path}.$more_keyword_path, 'servers', $index, 'variables', $name)) },
          'server url value does not match any of the allowed values')
        if not any { $captures{$name} eq $_ } $server->{variables}{$name}{enum}->@*;
    }

    return if not $valid;

    @captures{@path_capture_names} = @path_capture_values;
    return \%captures;
  }

  # no match against any servers urls
  return;
}

sub _validate_path_parameter ($self, $state, $param_obj, $path_captures) {
  $state->{data_path} .= '/uri/path';

  # 'required' is always true for path parameters
  return E({ %$state, keyword => 'required' }, 'missing path parameter: %s', $param_obj->{name})
    if not exists $path_captures->{$param_obj->{name}};

  $state->{data_path} = jsonp($state->{data_path}, $param_obj->{name});

  my $data = $path_captures->{$param_obj->{name}};
  $data .= '';

  return $self->_validate_parameter_content({ %$state, depth => $state->{depth}+1 }, $param_obj, \$data)
    if exists $param_obj->{content};

  return E({ %$state, keyword => 'style' }, 'only style: simple is supported in path parameters')
    if ($param_obj->{style}//'simple') ne 'simple';

  my @types = $self->_type_in_schema($param_obj->{schema}, { %$state, keyword_path => $state->{keyword_path}.'/schema' });
  if (grep $_ eq 'array', @types or grep $_ eq 'object', @types) {
    return E($state, 'deserializing to non-primitive types is not yet supported in path parameters');
  }
  if (grep $_ eq 'boolean', @types) {
    $data = false if $data eq '0' or $data eq 'false' or $data eq '';
    $data = true if $data eq '1' or $data eq 'true';
  }
  $data = undef if $data eq '' and grep $_ eq 'null', @types;

  $self->_evaluate_subschema(\$data, $param_obj->{schema}, { %$state, keyword_path => $state->{keyword_path}.'/schema', stringy_numbers => 1, depth => $state->{depth}+1 });
}

sub _validate_query_parameter ($self, $state, $param_obj, $uri) {
  $state->{data_path} .= '/uri/query';

  # parse the query parameters out of uri
  my $query_params = +{ $uri->query->pairs->@* };

  if (not exists $query_params->{$param_obj->{name}}) {
    return E({ %$state, keyword => 'required' }, 'missing query parameter: %s', $param_obj->{name})
      if $param_obj->{required};
    return 1;
  }

  $state->{data_path} = jsonp($state->{data_path}, $param_obj->{name});
  my $data = $query_params->{$param_obj->{name}};

  return $self->_validate_parameter_content({ %$state, depth => $state->{depth}+1 }, $param_obj, \$data)
    if exists $param_obj->{content};

  # v3.2.0 §4.12, "Parameter Object -> allowEmptyValue": "If `true`, clients MAY pass a zero-length
  # string value in place of parameters that would otherwise be omitted entirely, which the server
  # SHOULD interpret as the parameter being unused."
  return if $param_obj->{allowEmptyValue}
    and ($param_obj->{style}//'form') eq 'form'
    and not length($data);

  # TODO: check 'allowReserved'; difficult to do without access to the raw request string

  # TODO: support different styles.
  # for now, we only support style=form and do not allow for multiple values per
  # property (i.e. 'explode' is not checked at all.)
  # (other possible style values: spaceDelimited, pipeDelimited, deepObject)

  return E({ %$state, keyword => 'style' }, 'only style: form is supported in query parameters')
    if ($param_obj->{style}//'form') ne 'form';

  my @types = $self->_type_in_schema($param_obj->{schema}, { %$state, keyword_path => $state->{keyword_path}.'/schema' });
  if (grep $_ eq 'array', @types or grep $_ eq 'object', @types) {
    return E($state, 'deserializing to non-primitive types is not yet supported in query parameters');
  }

  if (grep $_ eq 'boolean', @types) {
    $data = false if $data eq '0' or $data eq 'false' or $data eq '';
    $data = true if $data eq '1' or $data eq 'true';
  }
  $data = undef if $data eq '' and grep $_ eq 'null', @types;

  $state = { %$state, keyword_path => $state->{keyword_path}.'/schema', stringy_numbers => 1, depth => $state->{depth}+1 };
  $self->_evaluate_subschema(\$data, $param_obj->{schema}, $state);
}

# validates a header, from either the request or the response
sub _validate_header_parameter ($self, $state, $header_name, $header_obj, $headers) {
  return 1 if grep fc $header_name eq fc $_, qw(Accept Content-Type Authorization);

  $state->{data_path} .= '/header';

  if (not $headers->every_header($header_name)->@*) {
    return E({ %$state, keyword => 'required' }, 'missing header: %s', $header_name)
      if $header_obj->{required};
    return 1;
  }

  $state->{data_path} = jsonp($state->{data_path}, $header_name);

  # validate as a single comma-concatenated string, presumably to be decoded
  return $self->_validate_parameter_content({ %$state, depth => $state->{depth}+1 }, $header_obj, \ $headers->header($header_name))
    if exists $header_obj->{content};

  # RFC9112 §5.1-3: "The field line value does not include that leading or trailing whitespace: OWS
  # occurring before the first non-whitespace octet of the field line value, or after the last
  # non-whitespace octet of the field line value, is excluded by parsers when extracting the field
  # line value from a field line."
  my @values = map s/^\s*//r =~ s/\s*$//r, map split(/,/, $_), $headers->every_header($header_name)->@*;

  my @types = $self->_type_in_schema($header_obj->{schema}, { %$state, keyword_path => $state->{keyword_path}.'/schema' });

  # RFC9110 §5.3-1: "A recipient MAY combine multiple field lines within a field section that have
  # the same field name into one field line, without changing the semantics of the message, by
  # appending each subsequent field line value to the initial field line value in order, separated
  # by a comma (",") and optional whitespace (OWS, defined in Section 5.6.3). For consistency, use
  # comma SP."
  my $data;
  if (grep $_ eq 'array', @types) {
    # style=simple, explode=false or true: "blue,black,brown" -> ["blue","black","brown"]
    $data = \@values;
  }
  elsif (grep $_ eq 'object', @types) {
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

    if (grep $_ eq 'boolean', @types) {
      $data = false if $data eq '0' or $data eq 'false' or $data eq '';
      $data = true if $data eq '1' or $data eq 'true';
    }
    $data = undef if $data eq '' and grep $_ eq 'null', @types;
  }

  $state = { %$state, keyword_path => $state->{keyword_path}.'/schema', stringy_numbers => 1, depth => $state->{depth}+1 };
  $self->_evaluate_subschema(\$data, $header_obj->{schema}, $state);
}

sub _validate_cookie_parameter ($self, $state, $param_obj, @args) {
  $state->{data_path} = jsonp($state->{data_path}, qw(headers Cookie), $param_obj->{name});

  return E($state, 'cookie parameters not yet supported');
}

sub _validate_querystring_parameter ($self, $state, $param_obj, $uri) {
  $state->{data_path} = '/request/uri/query';

  # note: if something has caused the Mojo::Parameters object to be normalized (e.g. calling
  # 'pairs'), the raw string value is lost
  return E({ %$state, keyword => 'required' }, 'missing querystring')
    if $param_obj->{required} and not length $uri->query->{string};

  # Replace "+" with whitespace, unescape and decode as in Mojo::Parameters::pairs
  # We do not UTF-8-decode the content: this is the responsibility of the media-type decoder.
  my $content = url_unescape($uri->query->{string} =~ s/\+/ /gr);

  $self->_validate_parameter_content({ %$state, depth => $state->{depth}+1 }, $param_obj, \$content)
}

sub _validate_parameter_content ($self, $state, $param_obj, $content_ref) {
  my ($media_type) = keys $param_obj->{content}->%*;  # there can only be one key

  # FIXME: handle media-type parameters better when selecting for a decoder, see RFC9110 §8.3.1

  if ($media_type =~ m{^text/}
      and my $charset = ($media_type =~ /\bcharset\s*=\s*"?([^"\s;]+)"?/i ? $1 : undef)) {
    try {
      # we don't use Mojo::Util::decode because it doesn't die on failure
      $content_ref = \ Encode::decode($charset, $content_ref->$*, Encode::DIE_ON_ERR);
    }
    catch ($e) {
      return E({ %$state, keyword => 'content', _keyword_path_suffix => $media_type },
        'could not decode content as %s: %s', $charset, $e =~ s/^(.*)\n/$1/r);
    }
  }

  my $media_type_decoder = $self->get_media_type($media_type);  # case-insensitive, wildcard lookup

  return $self->_validate_media_type($state, $param_obj->{content}, $media_type, $media_type_decoder, $content_ref);
}

sub _validate_body_content ($self, $state, $content_obj, $message) {
  # strip media-type parameters (e.g. charset) from Content-Type
  my $content_type = (split(/;/, $message->headers->content_type//'', 2))[0] // '';

  return E({ %$state, data_path => $state->{data_path} =~ s{body$}{header}r, keyword => 'content' },
      'missing header: Content-Type')
    if not length $content_type;

  # FIXME: needs to handle media-type parameters when selecting for a decoder, see RFC9110 §8.3.1

  my $media_type = (first { fc($content_type) eq fc } keys $content_obj->%*)
    // (first { m{([^/]+)/\*$} && fc($content_type) =~ m{^\F\Q$1\E/[^/]+$} } keys $content_obj->%*);
  $media_type //= '*/*' if exists $content_obj->{'*/*'};
  return E({ %$state, keyword => 'content', recommended_response => [ 415 ] },
      'incorrect Content-Type "%s"', $content_type)
    if not defined $media_type;

  # §4.14, "Media Type Object -> encoding": "The encoding field SHALL only apply when the media type
  # is multipart or application/x-www-form-urlencoded."
  if ($content_type =~ m{^\Fmultipart/} or fc($content_type) eq 'application/x-www-form-urlencoded') {
    if (exists $content_obj->{$media_type}{encoding}) {
      my $state = { %$state, keyword_path => jsonp($state->{keyword_path}, 'content', $media_type) };
      # v3.1 §4.8.14.1: "The key, being the property name, MUST exist in the schema as a property."
      # TODO: encoding semantics have been changed and improved; see the 3.2 spec.
      foreach my $property (sort keys $content_obj->{$media_type}{encoding}->%*) {
        ()= E({ $state, keyword_path => jsonp($state->{keyword_path}, 'schema', 'properties', $property) },
            'encoding property "%s" requires a matching property definition in the schema')
          if not exists(($content_obj->{$media_type}{schema}{properties}//{})->{$property});
      }
      return E({ %$state, keyword => 'encoding' }, 'encoding not yet supported');
    }

    return E($state, '%s is not yet supported', $content_type);
  }

  # TODO: handle Content-Encoding header; https://github.com/OAI/OpenAPI-Specification/issues/2868
  my $content_ref = \ $message->body;

  # use charset to decode text content
  if ($content_type =~ m{^text/} and defined(my $charset = $message->content->charset)) {
    try {
      # we don't use $message->text or Mojo::Util::decode because they don't die on failure
      $content_ref = \ Encode::decode($charset, $content_ref->$*, Encode::DIE_ON_ERR);
    }
    catch ($e) {
      return E({ %$state, keyword => 'content', _keyword_path_suffix => $media_type },
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

    abort({ %$state, keyword => 'content', _keyword_path_suffix => $media_type},
      'EXCEPTION: unsupported media type "%s": add support with $openapi->add_media_type(...)', $media_type);
  }

  try {
    $content_ref = $media_type_decoder->($content_ref);
  }
  catch ($e) {
    return E({ %$state, keyword => 'content', _keyword_path_suffix => $media_type },
      'could not decode content as %s: %s', $media_type, $e =~ s/^(.*)\n/$1/r);
  }

  return if not exists $content_obj->{$media_type}{schema};

  $state = { %$state, keyword_path => jsonp($state->{keyword_path}, 'content', $media_type, 'schema'), depth => $state->{depth}+1 };
  $self->_evaluate_subschema($content_ref, $content_obj->{$media_type}{schema}, $state);
}

# wrap a result object around the errors
sub _result ($self, $state, $is_exception = 0, $is_response = 0) {
  croak 'no errors provided for exception' if $is_exception and not $state->{errors}->@*;
  return JSON::Schema::Modern::Result->new(
    output_format => $self->evaluator->output_format,
    formatted_annotations => 0,
    valid => !$state->{errors}->@*,
    $is_exception ? (exception => 1) : (), # -> recommended_response: [ 500, 'Internal Server Error' ]
    !$state->{errors}->@*
      ? (annotations => $state->{annotations}//[])
      : (errors => $state->{errors}),
    $is_response ? (recommended_response => undef) : (),  # responses don't have responses
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
  $state->{traversed_keyword_path} = $state->{traversed_keyword_path}.$state->{keyword_path}.'/$ref';
  $state->{keyword_path} = '';

  return $schema_info->{schema};
}

# determines the type(s) expected in a schema: array, object, null, boolean, string.
# "" will be interpreted as null when type = null
# 0, 1, false, true will be interpreted as boolean when type = boolean
# (number and integer are implicit via evaluation with "stringy_numbers" enabled)
sub _type_in_schema ($self, $schema, $state) {
  return [] if not is_plain_hashref($schema);

  my @types;

  push @types, is_plain_arrayref($schema->{type}) ? ($schema->{types}->@*) : ($schema->{type})
    if exists $schema->{type};

  push @types, map $self->_type_in_schema($schema->{allOf}[$_],
      { %$state, keyword_path => $state->{keyword_path}.'/allOf/'.$_ }), 0..$schema->{allOf}->$#*
    if exists $schema->{allOf};

  if (defined(my $ref = $schema->{'$ref'})) {
    $schema = $self->_resolve_ref('schema', $ref, $state);
    push @types, $self->_type_in_schema($schema, $state);
  }

  return @types;
}

# evaluates data against the subschema at the current state location
sub _evaluate_subschema ($self, $dataref, $schema, $state) {
  # boolean schema
  if (not is_plain_hashref($schema)) {
    return 1 if $schema;

    my @location = unjsonp($state->{data_path});
    my $location =
        $location[-1] eq 'body' ? join(' ', @location[-2..-1])
      : $location[-2] eq 'query' ? 'query parameter'  # query
      : $location[-2] eq 'path' ? 'path parameter'    # this should never happen
      : $location[-2] eq 'header' ? join(' ', @location[-3..-2])
      : $location[-1] eq 'query' ? 'query parameter'  # querystring
      : die 'unknown location';  # cookie TBD
    return E($state, '%s not permitted', $location);
  }

  return 1 if !keys(%$schema);  # schema is {}

  # this is not necessarily the canonical uri of the location, but it is still a valid location
  my $uri = $state->{initial_schema_uri}->clone;
  $uri->fragment(($uri->fragment//'').$state->{keyword_path});

  my $result = $self->evaluator->evaluate(
    $dataref->$*,
    # reference by uri ensures all schema information is available to the evaluator, e.g. dialect
    $uri,
    {
      data_path => $state->{data_path},
      traversed_keyword_path => $state->{traversed_keyword_path}.$state->{keyword_path},
      $state->{stringy_numbers} ? (stringy_numbers => 1) : (),
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
    $req->method($request->method);
    $req->url(Mojo::URL->new($request->uri));
    $req->version($request->protocol =~ s{^HTTP/(\d\.\d)$}{$1}r) if $request->protocol;
    $req->headers->add(@$_) foreach pairs $request->headers->flatten;

    my $body = $request->content;
    $req->body($body) if length $body;
  }
  elsif ($request->isa('Plack::Request') or $request->isa('Catalyst::Request')) {
    $req->parse($request->env);

    my $plack_request = $request->isa('Plack::Request') ? $request
      : do { +require Plack::Request; Plack::Request->new($request->env) };

    my $body = $plack_request->content;
    $req->body($body) if length $body;

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

# results may be unsatisfactory if not a valid HTTP response.
sub _convert_response ($response) {
  return $response if $response->isa('Mojo::Message::Response');

  my $res = Mojo::Message::Response->new;

  if ($response->isa('HTTP::Response')) {
    $res->code($response->code);
    $res->version($response->protocol =~ s{^HTTP/(\d\.\d)$}{$1}r) if $response->protocol;
    $res->headers->add(@$_) foreach pairs $response->headers->flatten;
    my $body = $response->content;
    $res->body($body) if length $body;
  }
  elsif ($response->isa('Plack::Response')) {
    $res->code($response->status);
    $res->headers->add(@$_) foreach pairs $response->headers->psgi_flatten_without_sort->@*;
    my $body = $response->content;
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

  $res->finish;
  return $res;
}

# url-percent-decode and UTF-8-decode a string
sub _uri_decode ($str) {
  Encode::decode('UTF-8', url_unescape($str), Encode::DIE_ON_ERR);
}

# callback hook for Sereal::Encoder
sub FREEZE ($self, $serializer) { +{ %$self } }

# callback hook for Sereal::Decoder
sub THAW ($class, $serializer, $data) {
  my $self = bless($data, $class);

  foreach my $attr (qw(openapi_document evaluator)) {
    croak "serialization missing attribute '$attr': perhaps your serialized data was produced for an older version of $class?"
      if not exists $self->{$attr};
  }

  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenAPI::Modern - Validate HTTP requests and responses against an OpenAPI v3.1 or v3.2 document

=head1 VERSION

version 0.107

=head1 SYNOPSIS

  my $openapi = OpenAPI::Modern->new(
    openapi_uri => 'https://prod.example.com',  # adjust for each deployment environment
    openapi_schema => YAML::PP->new(boolean => 'JSON::PP')->load_string(<<'YAML'));
  $self: /api         # canonical_uri will become https://prod.example.com/api
  openapi: 3.2.0
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
      - name: bar_id
        in: path
        required: true
        schema:
          pattern: ^\d+$
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
        "absoluteKeywordLocation" : "https://production.example.com/api#/paths/~1foo~1%7Bfoo_id%7D~1bar~1%7Bbar_id%7D/post/requestBody/content/application~1json/schema/properties/hello/type",
        "error" : "got integer, not string",
        "instanceLocation" : "/request/body/hello",
        "keywordLocation" : "/paths/~1foo~1{foo_id}~1bar~1%7Bbar_id%7D/post/requestBody/content/application~1json/schema/properties/hello/type"
      },
      {
        "absoluteKeywordLocation" : "https://production.example.com/api#/paths/~1foo~1%7Bfoo_id%7D~1bar~1%7Bbar_id%7D/post/requestBody/content/application~1json/schema/properties",
        "error" : "not all properties are valid",
        "instanceLocation" : "/request/body",
        "keywordLocation" : "/paths/~1foo~1{foo_id}~1bar~1%7Bbar_id%7D/post/requestBody/content/application~1json/schema/properties"
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
L<OpenAPI Specification v3.1 or v3.2 document|https://spec.openapis.org/oas/latest#openapi-document> within
your application. The JSON Schema evaluator is fully specification-compliant; the OpenAPI evaluator
aims to be but some features are not yet available.

=for Pod::Coverage BUILDARGS FREEZE THAW

=for stopwords schemas jsonSchemaDialect metaschema subschema perlish operationId openapi Mojolicious

=head1 CONSTRUCTOR ARGUMENTS

If construction of the object is not successful, for example the document has a syntax error, the
call to C<new()> will throw an exception, which will likely be a L<JSON::Schema::Modern::Result>
object containing details.

Unless otherwise noted, these are also available as read-only accessors.

=head2 openapi_uri

Optional.

The URI that identifies the OpenAPI document; an alias to C<< ->openapi_document->canonical_uri >>.
See L<JSON::Schema::Modern::Document::OpenAPI/canonical_uri>.
Ignored if L</openapi_document> is provided.

This URI will be used at runtime to resolve relative URIs used in
the OpenAPI document, such as for C<jsonSchemaDialect> or C<servers url> values and C<$ref>
locations, as well as used for locations in L<JSON::Schema::Modern::Result> objects (see below).

The value of C<$self> in the document (if present) is resolved against this value.
It is strongly recommended that this resulting URI is absolute.

=head2 openapi_schema

The data structure describing the OpenAPI document (as specified at
L<https://spec.openapis.org/oas/latest>; an alias to C<< ->openapi_document->schema >>.
See L<JSON::Schema::Modern::Document::OpenAPI/schema>.
Ignored if L</openapi_document> is provided, otherwise required.

=head2 openapi_document

The L<JSON::Schema::Modern::Document::OpenAPI> document that holds the OpenAPI information to be
used for validation. If it is not provided to the constructor, then
L</openapi_schema> B<MUST> be provided, and L</evaluator> will also be used if provided.

=head2 evaluator

The L<JSON::Schema::Modern> object to use for all URI resolution and JSON Schema evaluation.
Optional (a default is constructed when omitted).

This must be prepared in advance if custom metaschemas are to be used, as the evaluator is what
holds the information about all available schemas (which are used by keywords such as
C<jsonSchemaDialect> and C<$ref>.

=head2 debug

Boolean; defaults to false (can also be set via C<$DEBUG>).

When set, useful diagnostic information is stored in the C<$options> hash used in public methods
described below.

=head1 METHODS

=head2 document_get

  my $parameter_data = $openapi->document_get('/paths/~1foo~1{foo_id}~1bar~1%7Bbar_id%7D/post/parameters/0');

Fetches the subschema at the provided JSON pointer from the main OpenAPI document.
Proxies to L<JSON::Schema::Modern::Document::OpenAPI/get>.
This is not recursive (does not follow C<$ref> chains) -- for that, use
C<< $openapi->recursive_get(Mojo::URL->new->fragment($json_pointer)) >>, see
L</recursive_get>.

=head2 validate_request

  $result = $openapi->validate_request(
    $request,
    # optional second argument can contain any combination of these keys+values:
    my $options = {
      path_template => '/foo/{foo_id}/bar/{bar_id}',
      operation_id => 'my_foo_request',
      path_captures => { foo_id => 'abc', bar_id => 2 },
      method => 'POST',
    },
  );

Validates an L<HTTP::Request>, L<Plack::Request>, L<Catalyst::Request> or L<Mojo::Message::Request>
object against the corresponding OpenAPI document, returning a
L<JSON::Schema::Modern::Result> object.

Absolute URIs in the result object are constructed by resolving the openapi document path against
the L</openapi_uri> (which is derived from the document's C<$self> keyword as well as the URI
provided to the document constructor).

The second argument is an optional hashref that contains extra information about the request,
corresponding to the values expected by L</find_path_item> below. The method populates the hashref
with some information about the request:
save it and pass it to a later L</validate_response> call (that corresponds to a response for this request)
to improve performance.

=head2 validate_response

  $result = $openapi->validate_response(
    $response,
    {
      request => $request,
    },
  );

Validates an L<HTTP::Response>, L<Plack::Response>, L<Catalyst::Response> or L<Mojo::Message::Response>
object against the corresponding OpenAPI document, returning a
L<JSON::Schema::Modern::Result> object.

Absolute URIs in the result object are constructed by resolving the openapi document path against
the L</openapi_uri> (which is derived from the document's C<$self> keyword as well as the URI
provided to the document constructor).

The second argument is an optional hashref that contains extra information about the request
corresponding to the response, as in L</validate_request> and L</find_path_item>.

C<request> in the hashref represents the original request object that
corresponds to this response, which can be used to find the appropriate section of the document if
other values (such as C<operationId>) are not known.

=head2 find_path_item

=for Pod::Coverage find_path

  $result = $self->find_path_item($options);

Finds the appropriate L<path-item|https://spec.openapis.org/oas/latest#path-item-object> entry
in the OpenAPI document corresponding to a request. Called
internally by both L</validate_request> and L</validate_response>.

The single argument is a hashref that contains information about the request. Various combinations
of values can be provided; possible values are:

=over 4

=item *

C<request>: the object representing the HTTP request. Supported types are: L<HTTP::Request>, L<Plack::Request>, L<Catalyst::Request>, L<Mojo::Message::Request>. Converted to a L<Mojo::Message::Request>.

=item *

C<uri>: the URI of the HTTP request. Converted from any string-compatible type to a L<Mojo::URL>.

=item *

C<method>: the HTTP method used by the request (case-sensitive)

=item *

C<path_template>: a string representing the (possibly partial) path portion of the request URI, with placeholders in braces (e.g. C</pets/{petId}>); see L<https://spec.openapis.org/oas/latest#paths-object>.

=item *

C<operation_id>: a string corresponding to the L<operationId|https://learn.openapis.org/specification/paths.html#the-endpoints-list> at a particular path-template and HTTP location under C</paths>. In the case of ambiguous matches (such as the possibility of more than one C<path_template> matching the request URI), providing this value will serve to unambiguously state which path-item and operation are intended, and is also more efficient as not all path-item entries need to be searched to find a match.

=item *

C<path_captures>: a hashref mapping placeholders in the path template to their actual values in the request URI; these will be url-unescaped

=back

All values are optional, and will be derived from each other as needed (albeit less
efficiently than if they were provided). All passed-in values MUST be consistent with each other and
the request or the return value from this method is false and appropriate errors will be included
in the C<$options> hash.

When successful, the options hash will be populated (or updated) with all the above keys,
and the return value is true.
When not successful, the options hash will be populated with key C<errors>, an arrayref containing
a L<JSON::Schema::Modern::Error> object, and the return value is false.

In addition, these values are also populated in the options hash (when available):

=for stopwords punycode

=over 4

=item *

C<uri_captures>: a hashref mapping placeholders in the entire uri template (server url plus path template) to their actual values in the request URI; these will be url-unescaped (for values coming from the path) and punycode-decoded (for values coming from the host).

=item *

C<operation_uri>: a URI indicating the document location of the operation object for the request, after following any references (usually something under C</paths/>, but may be in another document). Use C<< $openapi->evaluator->get($uri) >> to fetch this content (see L<JSON::Schema::Modern/get>). Note that this is the same as:

    $openapi->document_get(Mojo::URL->new($openapi->openapi_uri)->fragment($path_to_operation);

(See the L<documentation for an operation/https://learn.openapis.org/specification/paths.html#the-endpoints-list>
or in
L<§4.10 of the specification|https://spec.openapis.org/oas/latest#operation-object>.)

=item *

C<debug>: when C<$OpenAPI::Modern::DEBUG> or L</debug> is set on the OpenAPI::Modern object, additional diagnostic information is stored here in separate keys:

=over 4

=item *

C<uri_patterns>: an arrayref of patterns that were attempted to be matched against the URI, in match order

=back

=back

You can find the associated operation object in the OpenAPI document by using either C<operation_uri>,
or by calling C<< $openapi->openapi_document->operationId_path($operation_id) >>
(see L<JSON::Schema::Modern::Document::OpenAPI/operationId_path>) (note that the latter will
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

=head1 BUNDLED SCHEMA DOCUMENTS

This distribution comes bundled with all the metaschema documents you need to build your application,
or build custom schemas on top of. It aims to always use the latest versions of the documents; if
you need earlier versions, you can find them at
L<https://spec.openapis.org/#openapi-specification-schemas>.

The default metaschema used by this tool does not permit the use of C<$schema> keywords
in subschemas (unless the value is equal to the default OAS dialect), but a more permissive
dialect is also available (or you can define your own), which you declare by providing the
C<L<jsonSchemaDialect/https://spec.openapis.org/oas/latest#openapi-object>> property in your OpenAPI
Document.

The schemas are also available under the URIs C<< s/<date>/latest/ >> so you don't have to change your
code or configurations to keep pace with internal changes.

An even stricter schema and dialect are available, via the metaschema_uri
C<https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/3.2/strict-schema.json>,
which treats the `format` keyword as an assertion, and also prevents any unknown keywords from being
used in JSON Schemas. This is useful to avoid
spelling mistakes from going unnoticed and resulting in false positive results.

=head1 ON THE USE OF JSON SCHEMAS

Embedded JSON Schemas, through the use of the C<schema> keyword, are fully draft2020-12-compliant,
as per the spec, and implemented with L<JSON::Schema::Modern>. Unless overridden with the use of the
L<jsonSchemaDialect|https://spec.openapis.org/oas/latest#specifying-schema-dialects> keyword, their
metaschema is the "dialect" schema listed at L<https://spec.openapis.org/oas/#schema-iterations>, which allows for use of the
OpenAPI-specific keywords (C<discriminator>, C<xml>, C<externalDocs>, and C<example>), as defined in
L<the specification/https://spec.openapis.org/oas/latest#schema-object>. Format validation is turned
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

C<multipart/*> messages are not yet supported

=item *

OpenAPI descriptions must be contained in a single document; while C<$ref>erences to other documents (such as within a C</components> structure) are supported, C</paths> entries in other documents are not considered at this time.

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

=item *

L<https://spec.openapis.org/oas/v3.2>

=item *

L<https://spec.openapis.org/oas/>

=back

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
