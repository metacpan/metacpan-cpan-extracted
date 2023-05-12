use strict;
use warnings;
package JSON::Schema::Modern::Document::OpenAPI;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: One OpenAPI v3.1 document
# KEYWORDS: JSON Schema data validation request response OpenAPI

our $VERSION = '0.043';

use 5.020;
use Moo;
use strictures 2;
use experimental qw(signatures postderef);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use JSON::Schema::Modern::Utilities 0.525 qw(E canonical_uri jsonp);
use Safe::Isa;
use File::ShareDir 'dist_dir';
use Path::Tiny;
use List::Util qw(any pairs);
use Ref::Util 'is_plain_hashref';
use MooX::HandlesVia;
use MooX::TypeTiny 0.002002;
use Types::Standard qw(InstanceOf HashRef Str);
use namespace::clean;

extends 'JSON::Schema::Modern::Document';

use constant DEFAULT_DIALECT => 'https://spec.openapis.org/oas/3.1/dialect/base';

use constant DEFAULT_SCHEMAS => {
  # local filename => identifier to add the schema as
  'oas/dialect/base.schema.json' => 'https://spec.openapis.org/oas/3.1/dialect/base', # metaschema for json schemas contained within openapi documents
  'oas/meta/base.schema.json' => 'https://spec.openapis.org/oas/3.1/meta/base',  # vocabulary definition
  'oas/schema-base.json' => 'https://spec.openapis.org/oas/3.1/schema-base',  # the main openapi document schema + draft2020-12 jsonSchemaDialect
  'oas/schema.json' => 'https://spec.openapis.org/oas/3.1/schema', # the main openapi document schema + permissive jsonSchemaDialect
  'strict-schema.json' => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/strict-schema.json',
  'strict-dialect.json' => 'https://raw.githubusercontent.com/karenetheridge/OpenAPI-Modern/master/share/strict-dialect.json',
};

use constant DEFAULT_BASE_METASCHEMA => 'https://spec.openapis.org/oas/3.1/schema-base/2022-10-07';
use constant DEFAULT_METASCHEMA => 'https://spec.openapis.org/oas/3.1/schema/2022-10-07';

has '+evaluator' => (
  required => 1,
);

has '+metaschema_uri' => (
  default => DEFAULT_BASE_METASCHEMA,
);

has json_schema_dialect => (
  is => 'rwp',
  isa => InstanceOf['Mojo::URL'],
  coerce => sub { $_[0]->$_isa('Mojo::URL') ? $_[0] : Mojo::URL->new($_[0]) },
);

# operationId => document path
has operationIds => (
  is => 'bare',
  isa => HashRef[Str],
   handles_via => 'Hash',
   handles => {
     _add_operationId => 'set',
     get_operationId_path => 'get',
  },
  lazy => 1,
  default => sub { {} },
);

sub traverse ($self, $evaluator) {
  $self->_add_vocab_and_default_schemas;

  my $schema = $self->schema;
  my $state = {
    initial_schema_uri => $self->canonical_uri,
    traversed_schema_path => '',
    schema_path => '',
    data_path => '',
    errors => [],
    evaluator => $evaluator,
    identifiers => [],
    configs => {},
    spec_version => $evaluator->SPECIFICATION_VERSION_DEFAULT,
    vocabularies => [],
  };

  # this is an abridged form of https://spec.openapis.org/oas/3.1/schema/latest
  # just to validate the parts of the document we need to verify before parsing jsonSchemaDialect
  # and switching to the real metaschema for this document
  state $top_schema = {
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    type => 'object',
    required => ['openapi'],
    properties => {
      openapi => {
        type => 'string',
        pattern => '',  # just here for the callback so we can customize the error
      },
      jsonSchemaDialect => {
        type => 'string',
        format => 'uri',
      },
    },
  };
  my $top_result = $self->evaluator->evaluate(
    $schema, $top_schema,
    {
      effective_base_uri => DEFAULT_METASCHEMA,
      callbacks => {
        pattern => sub ($data, $schema, $state) {
          return $data =~ /^3\.1\.[0-9]+(-.+)?$/ ? 1 : E($state, 'unrecognized openapi version %s', $data);
        },
      },
    },
  );
  if (not $top_result) {
    $_->mode('evaluate') foreach $top_result->errors;
    push $state->{errors}->@*, $top_result->errors;
    return $state;
  }

  # /jsonSchemaDialect: https://spec.openapis.org/oas/v3.1.0#specifying-schema-dialects
  {
    my $json_schema_dialect = $self->json_schema_dialect // $schema->{jsonSchemaDialect};

    # "If [jsonSchemaDialect] is not set, then the OAS dialect schema id MUST be used for these Schema Objects."
    $json_schema_dialect //= DEFAULT_DIALECT;

    # traverse an empty schema with this metaschema uri to confirm it is valid
    my $check_metaschema_state = $evaluator->traverse({}, {
      metaschema_uri => $json_schema_dialect,
      initial_schema_uri => $self->canonical_uri->clone->fragment('/jsonSchemaDialect'),
    });

    # we cannot continue if the metaschema is invalid
    if ($check_metaschema_state->{errors}->@*) {
      # these errors should be mode=traverse
      push $state->{errors}->@*, $check_metaschema_state->{errors}->@*;
      return $state;
    }

    $state->@{qw(spec_version vocabularies)} = $check_metaschema_state->@{qw(spec_version vocabularies)};
    $self->_set_json_schema_dialect($json_schema_dialect);
  }

  # evaluate the document against its metaschema to find any errors, to identify all schema
  # resources within to add to the global resource index, and to extract all operationIds
  my (@json_schema_paths, @operation_paths);
  my $result = $self->evaluator->evaluate(
    $schema, $self->metaschema_uri,
    {
      callbacks => {
        '$dynamicRef' => sub ($, $schema, $state) {
          push @json_schema_paths, $state->{data_path} if $schema->{'$dynamicRef'} eq '#meta';
          return 1;
        },
        '$ref' => sub ($data, $schema, $state) {
          push @operation_paths, [ $data->{operationId} => $state->{data_path} ]
            if $schema->{'$ref'} eq '#/$defs/operation' and defined $data->{operationId};
          return 1;
        },
      },
    },
  );

  if (not $result) {
    $_->mode('evaluate') foreach $result->errors;
    push $state->{errors}->@*, $result->errors;
    return $state;
  }

  # "Templated paths with the same hierarchy but different templated names MUST NOT exist as they
  # are identical."
  my %seen_path;
  foreach my $path (sort keys $schema->{paths}->%*) {
    my $normalized = $path =~ s/\{[^}]+\}/\x00/r;
    if (my $first_path = $seen_path{$normalized}) {
      ()= E({ %$state, data_path => jsonp('/paths', $path),
        initial_schema_uri => Mojo::URL->new(DEFAULT_METASCHEMA) },
        'duplicate of templated path %s', $first_path);
      $state->{errors}[-1]->mode('evaluate');
      next;
    }
    $seen_path{$normalized} = $path;
  }

  return $state if $state->{errors}->@*;

  my @real_json_schema_paths;
  foreach my $path (sort @json_schema_paths) {
    # disregard paths that are not the root of each embedded subschema.
    next if any { $path =~ m{^\Q$_\E(?:/|\z)} } @real_json_schema_paths;

    unshift @real_json_schema_paths, $path;
    $self->_traverse_schema($self->get($path), { %$state, schema_path => $path });
  }

  foreach my $pair (@operation_paths) {
    my ($operation_id, $path) = @$pair;
    if (my $existing = $self->get_operationId_path($operation_id)) {
      ()= E({ %$state, data_path => $path .'/operationId',
          initial_schema_uri => Mojo::URL->new(DEFAULT_METASCHEMA) },
        'duplicate of operationId at %s', $existing);
    }
    else {
      $self->_add_operationId($operation_id => $path);
    }
  }

  $_->mode('evaluate') foreach $state->{errors}->@*;
  return $state;
}

######## NO PUBLIC INTERFACES FOLLOW THIS POINT ########

sub _add_vocab_and_default_schemas ($self) {
  my $js = $self->evaluator;
  $js->add_vocabulary('JSON::Schema::Modern::Vocabulary::OpenAPI');

  $js->add_format_validation(
    int32 => +{ type => 'integer', sub => sub ($x) {
      require Math::BigInt;
      $x = Math::BigInt->new($x);
      my $bound = Math::BigInt->new(2) ** 31;
      $x >= -$bound && $x < $bound;
    } },
    int64 => +{ type => 'integer', sub => sub ($x) {
      require Math::BigInt;
      $x = Math::BigInt->new($x);
      my $bound = Math::BigInt->new(2) ** 63;
      $x >= -$bound && $x < $bound;
    } },
    float => +{ type => 'number', sub => sub ($) { 1 } },
    double => +{ type => 'number', sub => sub ($) { 1 } },
    password => +{ type => 'string', sub => sub ($) { 1 } },
  );

  foreach my $pairs (pairs DEFAULT_SCHEMAS->%*) {
    my ($filename, $uri) = @$pairs;
    my $document = $js->add_schema($uri,
      $js->_json_decoder->decode(path(dist_dir('OpenAPI-Modern'), $filename)->slurp_raw));
    $js->add_schema($uri.'/latest', $document) if $uri =~ /schema(-base)?$/;
  }
}

# https://spec.openapis.org/oas/v3.1.0#schema-object
sub _traverse_schema ($self, $schema, $state) {
  return if not is_plain_hashref($schema) or not keys %$schema;

  my $subschema_state = $self->evaluator->traverse($schema, {
    %$state,  # so we don't have to enumerate everything that may be in config_override
    initial_schema_uri => canonical_uri($state),
    traversed_schema_path => $state->{traversed_schema_path}.$state->{schema_path},
    metaschema_uri => $self->json_schema_dialect,
  });

  push $state->{errors}->@*, $subschema_state->{errors}->@*;
  return if $subschema_state->{errors}->@*;

  push $state->{identifiers}->@*, $subschema_state->{identifiers}->@*;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Modern::Document::OpenAPI - One OpenAPI v3.1 document

=head1 VERSION

version 0.043

=head1 SYNOPSIS

  use JSON::Schema::Modern;
  use JSON::Schema::Modern::Document::OpenAPI;

  my $js = JSON::Schema::Modern->new;
  my $openapi_document = JSON::Schema::Modern::Document::OpenAPI->new(
    evaluator => $js,
    canonical_uri => 'https://example.com/v1/api',
    schema => $schema,
    metaschema_uri => 'https://example.com/my_custom_dialect',
  );

=head1 DESCRIPTION

Provides structured parsing of an OpenAPI document, suitable as the base for more tooling such as
request and response validation, code generation or form generation.

The provided document must be a valid OpenAPI document, as specified by the schema identified by
C<https://spec.openapis.org/oas/3.1/schema-base/latest> (an alias for the latest document available)

and the L<OpenAPI v3.1 specification|https://spec.openapis.org/oas/v3.1.0>.

=head1 ATTRIBUTES

These values are all passed as arguments to the constructor.

This class inherits all options from L<JSON::Schema::Modern::Document> and implements the following
new ones:

=head2 evaluator

=for stopwords metaschema schemas

A L<JSON::Schema::Modern> object. Unlike in the parent class, this is B<REQUIRED>, because loaded
vocabularies, metaschemas and resource identifiers must be stored here as they are discovered in the
OpenAPI document. This is the object that will be used for subsequent evaluation of data against
schemas in the document, either manually or perhaps via a web framework plugin (coming soon).

=head2 metaschema_uri

The URI of the schema that describes the OpenAPI document itself. Defaults to
C<https://spec.openapis.org/oas/3.1/schema-base/latest> (an alias for the latest document
available).

=head2 json_schema_dialect

The URI of the metaschema to use for all embedded L<JSON Schemas|https://json-schema.org/> in the
document.

Overrides the value of C<jsonSchemaDialect> in the document, or the specification default
(C<https://spec.openapis.org/oas/3.1/dialect/base>).

If you specify your own dialect here or in C<jsonSchemaDialect>, then you need to add the
vocabularies and schemas to the implementation yourself. (see C<JSON::Schema::Modern/add_vocabulary>
and C<JSON::Schema::Modern/add_schema>).

Note this is B<NOT> the same as L<JSON::Schema::Modern::Document/metaschema_uri>, which contains the
URI describing the entire document (and is not a metaschema in this case, as the entire document is
not a JSON Schema). Note that you may need to explicitly set that attribute as well if you change
C<json_schema_dialect>, as the default metaschema used by the default C<metaschema_uri> can no
longer be assumed.

=head1 METHODS

=head2 get_operationId_path

Returns the json pointer location of the operation containing the provided C<operationId> (suitable
for passing to C<< $document->get(..) >>), or C<undef> if the location does not exist in the
document.

=head1 SEE ALSO

=over 4

=item *

L<Mojolicious::Plugin::OpenAPI::Modern>

=item *

L<OpenAPI::Modern>

=item *

L<JSON::Schema::Modern>

=item *

L<https://json-schema.org>

=item *

L<https://www.openapis.org/>

=item *

L<https://oai.github.io/Documentation/>

=item *

L<https://spec.openapis.org/oas/v3.1.0>

=back

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/OpenAPI-Modern/issues>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

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
