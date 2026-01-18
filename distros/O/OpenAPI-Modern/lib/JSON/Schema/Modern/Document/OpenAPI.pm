use strictures 2;
package JSON::Schema::Modern::Document::OpenAPI;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: One OpenAPI v3.0, v3.1 or v3.2 document
# KEYWORDS: JSON Schema data validation request response OpenAPI

our $VERSION = '0.121';

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
use JSON::Schema::Modern::Utilities 0.625 qw(E canonical_uri jsonp is_equal json_pointer_type assert_keyword_type assert_uri_reference load_cached_document get_type);
use JSON::Schema::Modern::Result 0.630;
use OpenAPI::Modern::Utilities qw(:constants add_vocab_and_default_schemas);
use Carp qw(croak carp);
use Digest::MD5 'md5_hex';
use Storable 'dclone';
use builtin::compat qw(blessed indexed);
use MooX::TypeTiny 0.002002;
use Types::Standard qw(HashRef ArrayRef Str Map Any);
use namespace::clean;

extends 'JSON::Schema::Modern::Document';

our @CARP_NOT = qw(Sereal Sereal::Decoder JSON::Schema::Modern::Document);

has '+schema' => (
  isa => HashRef,
);

# json pointer => entity name (indexed by integer); overrides parent
# these aren't all the different types of objects; for now we only track those that are the valid
# target of a $ref keyword in an openapi document.
sub __entities { qw(schema response parameter example request-body header security-scheme link callbacks path-item media-type) }

# operationId => document path
has _operationIds => (
  is => 'ro',
  isa => HashRef[json_pointer_type],
  lazy => 1,
  default => sub { {} },
);

*get_operationId_path = \&operationId_path; # deprecated

sub operationId_path { $_[0]->_operationIds->{$_[1]} }
sub _add_operationId { $_[0]->_operationIds->{$_[1]} = json_pointer_type->($_[2]) }

# tag name => document path of tag object
has _tags => (
  is => 'bare',
  isa => HashRef[json_pointer_type],
  lazy => 1,
  default => sub { {} },
);

sub tag_path { $_[0]->{_tags}{$_[1]} }

# tag name => document path of operation
has _operation_tags => (
  is => 'bare',
  isa => HashRef[ArrayRef[json_pointer_type]],
  lazy => 1,
  default => sub { {} },
);

sub operations_with_tag { ($_[0]->{_operation_tags}{$_[1]}//[])->@* }

# the minor.major version of the OpenAPI specification used for this document
has oas_version => (
  is => 'rwp',
  isa => Str->where(q{/^[1-9]\.(?:0|[1-9][0-9]*)\z/}),
);

# list of /paths/* path templates, in canonical search order
has path_templates => (
  is => 'rwp',
  isa => ArrayRef[Str],
);

has defaults => (
  is => 'rwp',
  isa => Map[json_pointer_type, Any],
  lazy => 1,
  default => sub { {} },
);

sub default { $_[0]->defaults->{$_[1]} }

# we define the sub directly, rather than using an 'around', since our root base class is not
# Moo::Object, so we never got a BUILDARGS to modify
sub BUILDARGS ($class, @args) {
  my $args = $class->Moo::Object::BUILDARGS(@args); # we do not inherit from Moo::Object

  carp 'json_schema_dialect has been removed as a constructor attribute: use jsonSchemaDialect in your document instead'
    if exists $args->{json_schema_dialect};

  carp 'specification_version argument is ignored by this subclass: use jsonSchemaDialect in your document instead'
    if defined(delete($args->{specification_version}));

  return $args;
}

# (probably) temporary, until the parent class evaluator is completely removed
sub evaluator { die 'improper attempt to use of document evaluator' }

# called by this class's base class constructor, in order to validate the integrity of the document
# and identify all important details about this document, such as entity locations, referenceable
# identifiers, operationIds, etc.
sub traverse ($self, $evaluator, $config_override = {}) {
  croak join(', ', sort keys %$config_override), ' not supported as a config override in traverse'
    if keys %$config_override;

  my $state = {
    initial_schema_uri => $self->canonical_uri,
    traversed_keyword_path => '',
    keyword_path => '',
    data_path => '',
    errors => [],
    evaluator => $evaluator,
    identifiers => {},
    # note that this is the JSON Schema specification version, not OpenAPI version
    specification_version => $evaluator->SPECIFICATION_VERSION_DEFAULT,
    vocabularies => [],
    subschemas => [],
    references => [],
    depth => 0,
    traverse => 1,
  };

  my $schema = $self->schema;

  ()= E($state, 'missing openapi version'), return $state if not exists $schema->{openapi};
  ()= E($state, 'bad openapi version: "%s"', $schema->{openapi}//''), return $state
    if ($schema->{openapi}//'') !~ /^\d+\.\d+\.\d+(-.+)?\z/a;

  my @oad_version = split /[.-]/, $schema->{openapi};
  $self->_set_oas_version(join('.', @oad_version[0..1]));

  my ($max_supported) = grep {
    my @supported = split /\./;
    $supported[0] == $oad_version[0] && $supported[1] == $oad_version[1]
  } reverse SUPPORTED_OAD_VERSIONS->@*;

  ()= E($state, 'unrecognized/unsupported openapi version: "%s"', $schema->{openapi}), return $state
    if not defined $max_supported;
  carp 'WARNING: your document was written for version ', $schema->{openapi},
      ' but this implementation has only been tested up to ', $max_supported,
      ': this may be okay but you should upgrade your OpenAPI::Modern installation soon',"\n"
    if defined $oad_version[2] and (split(/\./, $max_supported))[2] < $oad_version[2];

  add_vocab_and_default_schemas($evaluator, $self->oas_version);

  if (exists $schema->{'$self'}) {
    my $state = { %$state, keyword => '$self', initial_schema_uri => Mojo::URL->new };

    if ($oad_version[0] == 3 and $oad_version[1] < 2) {
      ()= E($state, 'additional property not permitted');
      return $state;
    }

    return $state
      if not assert_keyword_type($state, $schema, 'string')
        or not assert_uri_reference($state, $schema)
        or not ($schema->{'$self'} !~ /#/ || E($state, '$self cannot contain a fragment'));
  }

  # determine canonical uri using rules from v3.2.0 §4.1.2.2.1, "Establishing the Base URI"
  $self->_set_canonical_uri($state->{initial_schema_uri} =
    Mojo::URL->new($schema->{'$self'}//())->to_abs($self->retrieval_uri));

  # /jsonSchemaDialect: https://spec.openapis.org/oas/latest#specifying-schema-dialects
  {
    if (exists $schema->{jsonSchemaDialect}) {
      my $state = { %$state, keyword => 'jsonSchemaDialect' };
      return $state
        if not assert_keyword_type($state, $schema, 'string')
          or not assert_uri_reference($state, $schema);
    }

    # v3.2.0 §4.24.7, "Specifying Schema Dialects": "If [jsonSchemaDialect] is not set, then the OAS
    # dialect schema id MUST be used for these Schema Objects."
    # v3.2.0 §4.1.2.2, "Relative References in API Description URIs": "Unless specified otherwise,
    # all fields that are URIs MAY be relative references as defined by RFC3986 Section 4.2."
    my $json_schema_dialect = exists $schema->{jsonSchemaDialect}
      ? Mojo::URL->new($schema->{jsonSchemaDialect})->to_abs($self->canonical_uri)
      : DEFAULT_DIALECT->{$self->oas_version};

    # continue to support the old strict dialect and metaschema which didn't have "3.1" in the $id
    if ($json_schema_dialect eq (STRICT_DIALECT->{3.1} =~ s{/3.1/}{/}r)) {
      $json_schema_dialect =~ s{share/\K}{3.1/};
      $schema->{jsonSchemaDialect} = $json_schema_dialect;  # allow the 'const' check to pass
    }
    $self->_set_metaschema_uri($self->metaschema_uri =~ s{share/\K}{3.1/}r)
      if $self->_has_metaschema_uri and $self->metaschema_uri eq (STRICT_METASCHEMA->{3.1} =~ s{/3.1/}{/}r);

    # we used to always preload these, so we need to do it as needed for users who are using them
    load_cached_document($evaluator, STRICT_DIALECT->{$self->oas_version})
      if $self->_has_metaschema_uri and $self->metaschema_uri eq (STRICT_METASCHEMA->{$self->oas_version}//'')
        or $json_schema_dialect eq (STRICT_DIALECT->{$self->oas_version}//'');

    if ($json_schema_dialect eq DEFAULT_DIALECT->{'3.0'}
        or $json_schema_dialect eq (DEFAULT_DIALECT->{'3.0'} =~ s/\b\d{4}-\d{2}-\d{2}\b/latest/r)) {
      croak '3.0 dialect with a non-3.0 OAD is not currently supported' if $self->oas_version ne '3.0';

      $evaluator->add_vocabulary('JSON::Schema::Modern::Vocabulary::OpenAPI_3_0');
      $evaluator->_set_metaschema_vocabulary_classes($json_schema_dialect => [
        $state->@{qw(specification_version vocabularies)} =
          ('draft4', ['JSON::Schema::Modern::Vocabulary::OpenAPI_3_0'])
      ]);
    }
    else {
      # traverse an empty schema with this dialect uri to confirm it is valid, and add an entry in
      # the evaluator's _metaschema_vocabulary_classes
      my $check_metaschema_state = $evaluator->traverse({}, {
        metaschema_uri => $json_schema_dialect,
        initial_schema_uri => $self->canonical_uri->clone->fragment('/jsonSchemaDialect'),
        traversed_keyword_path => '/jsonSchemaDialect',
      });

      # we cannot continue if the metaschema is invalid
      if ($check_metaschema_state->{errors}->@*) {
        push $state->{errors}->@*, $check_metaschema_state->{errors}->@*;
        return $state;
      }

      $state->@{qw(specification_version vocabularies)} = $check_metaschema_state->@{qw(specification_version vocabularies)};
    }

    # subsequent '$schema' keywords can still override this
    $state->{json_schema_dialect} = $json_schema_dialect;

    $self->_set_metaschema_uri(DEFAULT_METASCHEMA->{$self->oas_version})
      if not $self->_has_metaschema_uri;

    load_cached_document($evaluator, STRICT_METASCHEMA->{$self->oas_version})
      if $self->_has_metaschema_uri and $self->metaschema_uri eq (STRICT_METASCHEMA->{$self->oas_version}//'');
  }

  $state->{identifiers}{$state->{initial_schema_uri}} = {
    path => '',
    canonical_uri => $state->{initial_schema_uri},
    specification_version => $state->{specification_version},
    vocabularies => $state->{vocabularies}, # reference, not copy
  };

  my $metaschema_doc;

  # evaluate the document against its metaschema to find any errors, to identify all schema
  # resources within to add to the global resource index, and to extract all operationIds
  my (@json_schema_paths, @operation_paths, %bad_path_item_refs, @servers_paths, %tag_operation_paths, @bad_3_0_paths, @references);
  my $result = $evaluator->evaluate(
    $schema, $self->metaschema_uri,
    {
      collect_annotations => 0,
      validate_formats => 1,
      with_defaults => 1,
      callbacks => {
        # we avoid producing errors here so we don't create extra errors for "not all additional
        # properties are valid" etc
        '$dynamicRef' => sub ($, $schema, $state) {
          # Note that if we are using the default metaschema
          # https://spec.openapis.org/oas/<version>/schema/<date>, we will only find the root of each
          # schema, not all subschemas. We will traverse each of these schemas later using
          # jsonSchemaDialect to find all subschemas and their $ids.
          push @json_schema_paths, $state->{data_path} if $schema->{'$dynamicRef'} eq '#meta';
          return 1;
        },
        '$ref' => sub ($data, $schema, $state) {
          my $entity;

          if ($self->oas_version eq '3.0') {
            # strip '#/definitions/'; convert CamelCase to kebab-case
            if ($entity = lc join('-', split /(?=[A-Z])/, substr($schema->{'$ref'}, 14))) {
              if ($entity eq 'schema') {
                push @bad_3_0_paths, [ items => $state->{data_path} ]
                  if ($data->{type}//'') eq 'array' and not exists $data->{items};

                push @bad_3_0_paths, [ minimum => $state->{data_path} ]
                  if exists $data->{exclusiveMinimum} and not exists $data->{minimum};

                push @bad_3_0_paths, [ maximum => $state->{data_path} ]
                  if exists $data->{exclusiveMaximum} and not exists $data->{maximum};
              }

              # "$ref" in path-item is not represented in the schema by a Reference object
              push @references, [ '$ref', $state->{data_path}, Mojo::URL->new($data->{'$ref'})->to_abs($self->canonical_uri), 'path-item' ]
                if $entity eq 'path-item' and exists $data->{'$ref'};

              if ($entity eq 'reference') {
                $metaschema_doc //= $evaluator->_get_resource($self->metaschema_uri)->{document};

                # in the 3.0 metaschema, entities are identified via:
                # "oneOf": [ { "$ref": "#/definitions/Foo" }, { "$ref": "#/definitions/Reference" } ]
                my $schema_path = ($state->{initial_schema_uri}->fragment//'').$state->{keyword_path};
                if ($schema_path =~ s{/oneOf/\K([01])\z}{$1 ^ 1}e) {
                  $entity = lc join('-', split /(?=[A-Z])/, substr($metaschema_doc->get($schema_path)->{'$ref'}, 14));
                  $entity .= 's' if $entity eq 'callback';
                  push @references, [ '$ref', $state->{data_path}, Mojo::URL->new($data->{'$ref'})->to_abs($self->canonical_uri), $entity ];
                }
              }

              $entity .= 's' if $entity eq 'callback';
              undef $entity if not grep $entity eq $_, __entities;

              # no need to push to @json_schema_paths, as all schema entities are already found
              # via $refs above, and there are no embedded identifiers to be identified
            }
          }
          else {
            # we only need to special-case path-item, because this is the only entity that is
            # referenced in the schema without an -or-reference
            ($entity) = (($schema->{'$ref'} =~ m{#/\$defs/([^/]+?)(?:-or-reference)\z}),
                         ($schema->{'$ref'} =~ m{#/\$defs/(path-item)\z}));

            push @references, [ '$ref', $state->{data_path}, Mojo::URL->new($data->{'$ref'})->to_abs($self->canonical_uri), 'path-item' ]
              if ($entity//'') eq 'path-item' and exists $data->{'$ref'};

            if ($schema->{'$ref'} eq '#/$defs/reference') {
              my ($e) = ($state->{initial_schema_uri}->fragment =~ m{/\$defs/([^/]+?)(?:-or-reference)\z});
              push @references, [ '$ref', $state->{data_path}, Mojo::URL->new($data->{'$ref'})->to_abs($self->canonical_uri), $e ];
            }
          }

          $self->_add_entity_location($state->{data_path}, $entity) if $entity;

          if ($schema->{'$ref'} eq '#/$defs/operation' or $schema->{'$ref'} eq '#/definitions/Operation') {
            push @operation_paths, [ $data->{operationId} => $state->{data_path} ]
              if defined $data->{operationId};

            { use autovivification 'store';
              push $tag_operation_paths{$_}->@*, $state->{data_path}
                foreach ($data->{tags}//[])->@*;
            }
          }

          # path-items are weird and allow mixing of fields adjacent to a $ref, which is burdensome
          # to properly support (see https://github.com/OAI/OpenAPI-Specification/issues/3734)
          if ($entity and $entity eq 'path-item' and exists $data->{'$ref'}) {
            my %path_item = $data->%*;
            delete @path_item{qw(summary description $ref)};
            $bad_path_item_refs{$state->{data_path}} = join(', ', sort keys %path_item) if keys %path_item;
          }

          # will contain duplicates; filter out later
          push @servers_paths, ($state->{data_path} =~ s{/[0-9]+\z}{}r)
            if $schema->{'$ref'} eq '#/$defs/server';

          return 1;
        },
      },
    },
  );

  if (not $result->valid) {
    foreach my $e ($result->errors) {
      if (($e->keyword//'') eq 'not'
          and $e->absolute_keyword_location->fragment eq '/$defs/parameters/not'
          and $e->absolute_keyword_location->clone->fragment(undef) eq DEFAULT_METASCHEMA->{$self->oas_version}
      ) {
        push $state->{errors}->@*, $e->clone(
          keyword_location => '',
          absolute_keyword_location => undef,
          error => 'cannot use query and querystring together',
        );
      }

      push $state->{errors}->@*, $e;
    }

    return $state;
  }

  $self->_set_defaults($result->defaults) if $result->defaults;

  foreach my $pair (@operation_paths) {
    my ($operation_id, $path) = @$pair;
    if (my $existing = $self->operationId_path($operation_id)) {
      ()= E({ %$state, keyword_path => $path .'/operationId' },
        'duplicate of operationId at %s', $existing);
    }
    else {
      $self->_add_operationId($operation_id => $path);
    }
  }

  ()= E({ %$state, keyword_path => $_->[1] },
      $_->[0] eq 'items' ? '"items" must be present if type is "array"'
    : $_->[0] eq 'minimum' ? '"minimum" must be present when "exclusiveMinimum" is used'
    : $_->[0] eq 'maximum' ? '"maximum" must be present when "exclusiveMaximum" is used'
    : die
  ) foreach @bad_3_0_paths;

  # v3.2.0 §4.8.1, "Patterned Fields": "When matching URLs, concrete (non-templated) paths would be
  # matched before their templated counterparts."

  # caution, Schwartzian transform ahead!
  $self->_set_path_templates(my $sorted_paths = [
    map $_->[0],                              # remove transformed entries
    sort { $a->[1] cmp $b->[1] || $a->[0] cmp $b->[0] }  # sort by the transformed entries
    map [ $_, s/\{[^{}]+\}/\x{10FFFF}/rg ],   # transform template names into the highest Unicode char
    grep !/^x-/,                              # remove extension keywords
    keys(($schema->{paths}//{})->%*)          # all entries in /paths/*
  ]);

  my %seen_path;
  foreach my $path (@$sorted_paths) {
    # see ABNF at v3.2.0 §4.8.2
    die "invalid path: $path" if substr($path, 0, 1) ne '/'; # schema validation catches this
    ()= E({ %$state, keyword_path => jsonp('/paths', $path) }, 'invalid path template "%s"', $path)
      if grep !/^(?:\{[^{}]+\}|%[0-9A-F]{2}|[:@!\$&'()*+,;=A-Za-z0-9._~-]+)+\z/,
        split('/', substr($path, 1)); # split by segment, omitting leading /

    my %seen_names;
    foreach my $name ($path =~ /\{([^{}]+)\}/g) {
      # v3.2.0 §4.8.1, "Patterned Fields": "Templated paths with the same hierarchy but different
      # templated names MUST NOT exist as they are identical."
      if (++$seen_names{$name} == 2) {
        ()= E({ %$state, keyword_path => jsonp('/paths', $path) },
          'duplicate path template variable "%s"', $name);
      }
    }

    my $normalized = $path =~ s/\{[^{}]+\}/\x00/gr;
    if (my $first_path = $seen_path{$normalized}) {
      ()= E({ %$state, keyword_path => jsonp('/paths', $path) },
        'duplicate of templated path "%s"', $first_path);
      next;
    }
    $seen_path{$normalized} = $path;
  }

  foreach my $path_item (sort keys %bad_path_item_refs) {
    ()= E({ %$state, keyword_path => $path_item },
      'invalid keywords used adjacent to $ref in a path-item: %s', $bad_path_item_refs{$path_item});
  }

  my %seen_servers;
  foreach my $servers_location (reverse @servers_paths) {
    next if $seen_servers{$servers_location}++;

    my $servers = $self->get($servers_location);
    my %seen_url;

    foreach my $server_idx (0 .. $servers->$#*) {
      # see ABNF at v3.2.0 §4.6
      ()= E({ %$state, keyword_path => jsonp($servers_location, $server_idx, 'url') },
          'invalid server url "%s"', $servers->[$server_idx]{url}), next
        if $servers->[$server_idx]{url} !~ /^(?:\{[^{}]+\}|%[0-9A-F]{2}|[\x21\x24\x26-\x3B\x3D\x40-\x5B\x5D\x5F\x61-\x7A\x7E\xA0-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFEF}\x{10000}-\x{1FFFD}\x{20000}-\x{2FFFD}\x{30000}-\x{3FFFD}\x{40000}-\x{4FFFD}\x{50000}-\x{5FFFD}\x{60000}-\x{6FFFD}\x{70000}-\x{7FFFD}\x{80000}-\x{8FFFD}\x{90000}-\x{9FFFD}\x{A0000}-\x{AFFFD}\x{B0000}-\x{BFFFD}\x{C0000}-\x{CFFFD}\x{D0000}-\x{DFFFD}\x{E1000}-\x{EFFFD}\x{E000}-\x{F8FF}\x{F0000}-\x{FFFFD}\x{100000}-\x{10FFFD}])+\z/;

      my $normalized = $servers->[$server_idx]{url} =~ s/\{[^{}]+\}/\x00/gr;
      my @url_variables = $servers->[$server_idx]{url} =~ /\{([^{}]+)\}/g;

      if (my $first_url = $seen_url{$normalized}) {
        ()= E({ %$state, keyword_path => jsonp($servers_location, $server_idx, 'url') },
          'duplicate of templated server url "%s"', $first_url);
      }
      $seen_url{$normalized} = $servers->[$server_idx]{url};

      my $variables_obj = $servers->[$server_idx]{variables};
      if (not $variables_obj) {
        # missing 'variables': needs variables/$varname/default
        ()= E({ %$state, keyword_path => jsonp($servers_location, $server_idx) },
          '"variables" property is required for templated server urls') if @url_variables;
        next;
      }

      my %seen_names;
      foreach my $name (@url_variables) {
        ()= E({ %$state, keyword_path => jsonp($servers_location, $server_idx) },
            'duplicate servers template variable "%s"', $name)
          if ++$seen_names{$name} == 2;

        ()= E({ %$state, keyword_path => jsonp($servers_location, $server_idx, 'variables') },
            'missing "variables" definition for servers template variable "%s"', $name)
          if $seen_names{$name} == 1 and not exists $variables_obj->{$name};
      }

      foreach my $varname (keys $variables_obj->%*) {
        ()= E({ %$state, keyword_path => jsonp($servers_location, $server_idx, 'variables', $varname, 'default') },
            'servers default is not a member of enum')
          if exists $variables_obj->{$varname}{enum}
            and not grep $variables_obj->{$varname}{default} eq $_, $variables_obj->{$varname}{enum}->@*;
      }
    }
  }

  # name -> index; for duplicates, will contain the first index where the tag can be found
  my %tag_to_index = reverse indexed map $_->{name}, ($schema->{tags}//[])->@*;

  foreach my $tag_idx (0 .. ($schema->{tags}//[])->$#*) {
    my $tag = $schema->{tags}[$tag_idx];
    ()= E({ %$state, keyword_path => '/tags/'.$tag_idx.'/name' },
        'duplicate of tag at /tags/%d: "%s"', $tag_to_index{$tag->{name}}, $tag->{name})
      if $tag_to_index{$tag->{name}} != $tag_idx;

    ()= E({ %$state, keyword_path => '/tags/'.$tag_idx.'/parent' },
        'parent of tag "%s" does not exist: "%s"', $tag->{name}, $tag->{parent})
      if exists $tag->{parent} and not exists $tag_to_index{$tag->{parent}};

    my @seen;
    while (defined $tag->{parent}) {
      push @seen, $tag->{name};
      last if not defined $tag_to_index{$tag->{parent}};
      $tag = $schema->{tags}[$tag_to_index{$tag->{parent}}];

      ()= E({ %$state, keyword_path => '/tags/'.$tag_idx.'/parent' },
            'circular reference between tags: '.join(' -> ', map '"'.$_.'"', @seen, $tag->{name})),
          last
        if grep $_ eq $tag->{name}, @seen;
    }
  }

  return $state if $state->{errors}->@*;

  $self->{_tags} = (HashRef[json_pointer_type])->({ map +($_ => '/tags/'.$tag_to_index{$_}), keys %tag_to_index });
  $self->{_operation_tags} = (HashRef[ArrayRef[json_pointer_type]])->(\%tag_operation_paths);

  # disregard paths that are not the root of each embedded subschema.
  # Because the callbacks are executed after the keyword has (recursively) finished evaluating,
  # for each nested schema group. the schema paths appear longest first, with the parent schema
  # appearing last. Therefore we can whittle down to the parent schema for each group by iterating
  # through the full list in reverse, and checking if it is a child of the last path we chose to save.
  # When the default metaschema is being used, there is no pruning to be done, as only the root of
  # each embedded schema will be found via callbacks.
  my @real_json_schema_paths;
  for (my $idx = $#json_schema_paths; $idx >= 0; --$idx) {
    next if $idx != $#json_schema_paths
      and substr($json_schema_paths[$idx], 0, length($real_json_schema_paths[-1])+1)
        eq $real_json_schema_paths[-1].'/';

    push @real_json_schema_paths, $json_schema_paths[$idx];
  }

  push $state->{references}->@*, @references if $state->{references};

  $self->_traverse_schema({ %$state, keyword_path => $_ }) foreach reverse @real_json_schema_paths;
  return $state if $state->{errors}->@*;

  $self->_add_entity_location($_, 'schema') foreach $state->{subschemas}->@*;

  return $state;
}

# just like the base class's version, except we skip the evaluate step because we already did
# that as part of traverse.
sub validate ($class, %args) {
  my $with_defaults = delete $args{with_defaults};

  my $document = blessed($class) ? $class : $class->new(%args);
  return JSON::Schema::Modern::Result->new(
    errors => [ $document->errors ],
    $with_defaults ? (defaults => $document->defaults) : (),
  );
}

sub upgrade ($self, $to_version = SUPPORTED_OAD_VERSIONS->[-1]) {
  croak 'cannot upgrade an invalid document' if $self->errors;

  croak 'new openapi version must be a dotted tuple or triple'
    if $to_version !~ /^(3\.\d+)(?:\.\d+)?\z/a;
  my $to_oas_version = $1;
  croak 'requested upgrade to an unsupported version: ', $to_version
    if not grep $to_oas_version eq $_, OAS_VERSIONS->@*;

  ($to_version) = grep /^$to_version\./, SUPPORTED_OAD_VERSIONS->@* if $to_version =~  /^(3\.\d+)\z/a;

  my $schema = $self->schema;

  my $from_version = $schema->{openapi};
  return $schema if $from_version eq $to_version;

  my ($from_oas_version) = $schema->{openapi} =~ /^(3\.\d+)\.\d+\b/a;
  croak 'downgrading is not supported' if $from_oas_version > $to_oas_version;

  $schema->{openapi} = $to_version;

  return $schema if $from_oas_version eq $to_oas_version;

  if ($from_oas_version eq '3.0') {
    delete $schema->{paths} if not keys $schema->{paths}->%*;

    foreach my $schema_path ($self->get_entity_locations('schema')) {
      my $subschema = $self->get($schema_path);

      if (exists $subschema->{nullable}) {
        $subschema->{type} = [ $subschema->{type}, 'null' ]
          if delete $subschema->{nullable} and exists $subschema->{type};
      }

      $subschema->{exclusiveMinimum} = delete $subschema->{minimum} if delete $subschema->{exclusiveMinimum};
      $subschema->{exclusiveMaximum} = delete $subschema->{maximum} if delete $subschema->{exclusiveMaximum};

      $subschema->{examples} = [ delete $subschema->{example} ] if exists $subschema->{example};

      if (exists $subschema->{format}) {
        if ($subschema->{format} eq 'binary') {
          $subschema->{contentMediaType} = 'application/octet-stream';
          delete $subschema->{format};
        }
        elsif ($subschema->{format} eq 'base64') {
          $subschema->{contentEncoding} = 'base64';
          delete $subschema->{format};
        }
      }
    }
  }

  if ($to_oas_version eq '3.2') {
    foreach my $schema_path ($self->get_entity_locations('response')) {
      my $subschema = $self->get($schema_path);
      delete $subschema->{description}
        if exists $subschema->{description} and $subschema->{description} eq '';
    }
  }

  return $schema;
}

######## NO PUBLIC INTERFACES FOLLOW THIS POINT ########

# https://spec.openapis.org/oas/latest#schema-object
# traverse this JSON Schema and identify all errors, subschema locations, and referenceable
# identifiers
sub _traverse_schema ($self, $state) {
  my $schema = $self->get($state->{keyword_path});

  if (get_type($schema) eq 'boolean' or not keys %$schema) {
    push $state->{subschemas}->@*, $state->{keyword_path};
    return;
  }

  my $subschema_state = $state->{evaluator}->traverse($schema, {
    initial_schema_uri => canonical_uri($state),
    traversed_keyword_path => $state->{traversed_keyword_path}.$state->{keyword_path},
    metaschema_uri => $state->{json_schema_dialect},  # can be overridden with the '$schema' keyword
  });

  push $state->{errors}->@*, $subschema_state->{errors}->@*;
  push $state->{subschemas}->@*, $subschema_state->{subschemas}->@*;
  push $state->{references}->@*, ($subschema_state->{references}//[])->@* if $state->{references};

  foreach my $new_uri (sort keys $subschema_state->{identifiers}->%*) {
    if (not $state->{identifiers}{$new_uri}) {
      $state->{identifiers}{$new_uri} = $subschema_state->{identifiers}{$new_uri};
      next;
    }

    my $existing = $state->{identifiers}{$new_uri};
    my $new = $subschema_state->{identifiers}{$new_uri};

    if (not is_equal(
        { canonical_uri => $new->{canonical_uri}.'', map +($_ => $new->{$_}), qw(path specification_version vocabularies) },
        { canonical_uri => $existing->{canonical_uri}.'', map +($_ => $existing->{$_}), qw(path specification_version vocabularies) })) {
      ()= E({ %$state, keyword_path => $new->{path} },
        'duplicate canonical uri "%s" found (original at path "%s")',
        $new_uri, $existing->{path});
      next;
    }

    foreach my $anchor (sort keys $new->{anchors}->%*) {
      if (my $existing_anchor = ($existing->{anchors}//{})->{$anchor}) {
        ()= E({ %$state, keyword_path => $new->{anchors}{$anchor}{path} },
          'duplicate anchor uri "%s" found (original at path "%s")',
          $new->{canonical_uri}->clone->fragment($anchor),
          $existing->{anchors}{$anchor}{path});
        next;
      }

      use autovivification 'store';
      $existing->{anchors}{$anchor} = $new->{anchors}{$anchor};
    }
  }
}

# Given a jsonSchemaDialect uri, generate a new schema that wraps the standard OAD schema
# to set the jsonSchemaDialect value for the #meta dynamic reference.
# This metaschema does not allow subschemas to select their own $schema; for that, you
# should construct your own, based on DEFAULT_BASE_METASCHEMA.
sub _dynamic_metaschema_uri ($self, $json_schema_dialect, $evaluator) {
  $json_schema_dialect .= '';
  my $dialect_uri = 'https://custom-dialect.example.com/' . md5_hex($json_schema_dialect);
  return $dialect_uri if $evaluator->_get_resource($dialect_uri);

  # we use the definition of https://spec.openapis.org/oas/<version>/schema-base/<date> but swap out
  # the dialect reference.
  my $schema = dclone($evaluator->_get_resource(DEFAULT_BASE_METASCHEMA->{$self->oas_version})->{document}->schema);
  $schema->{'$id'} = $dialect_uri;
  $schema->{'$defs'}{dialect}{const} = $json_schema_dialect;
  $schema->{'$defs'}{schema}{'$ref'} = $json_schema_dialect;

  $evaluator->add_document(
    Mojo::URL->new($dialect_uri),
    JSON::Schema::Modern::Document->new(
      schema => $schema,
      evaluator => $evaluator,
    ));

  return $dialect_uri;
}

# FREEZE is defined by parent class

# callback hook for Sereal::Decoder
sub THAW ($class, $serializer, $data) {
  delete $data->{evaluator};

  if (defined(my $dialect = delete $data->{json_schema_dialect})) {
    carp "use of no-longer-supported constructor argument: json_schema_dialect = \"$dialect\"; use \"jsonSchemaDialect\": \"...\"  in your OpenAPI document itself";
  }

  my $self = bless($data, $class);
  $self->{oas_version} = OAS_VERSIONS->[-1] if not exists $self->{oas_version};

  foreach my $attr (qw(schema _entities)) {
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

JSON::Schema::Modern::Document::OpenAPI - One OpenAPI v3.0, v3.1 or v3.2 document

=head1 VERSION

version 0.121

=head1 SYNOPSIS

  use JSON::Schema::Modern::Document::OpenAPI;

  my $openapi_document = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'https://example.com/v1/api',
    schema => decode_json(<<JSON),
  {
    "openapi": "3.2.0",
    "$self": "openapi.json",
    "info": {
      "title": "my title",
      "version": "1.2.3"
    },
    "paths": {
      "/foo": {
        "get": {}
      },
      "/foo/{foo_id}": {
        "post": {}
      }
    }
  }
  JSON
    metaschema_uri => 'https://example.com/my_custom_metaschema',
  );

=head1 DESCRIPTION

Provides structured parsing of an OpenAPI document, suitable as the base for more tooling such as
request and response validation, code generation or form generation.

The provided document must be a valid OpenAPI document, as specified by the schema identified by
one of:

=over 4

=item *

for v3.2 documents: L<https://spec.openapis.org/oas/3.2/schema-base/2025-09-17> (which is a wrapper around L<https://spec.openapis.org/oas/3.2/schema/2025-09-17>), and the L<OpenAPI v3.2.x specification|https://spec.openapis.org/oas/v3.2>

=item *

for v3.1 documents: L<https://spec.openapis.org/oas/3.1/schema-base/2025-09-15> (which is a wrapper around L<https://spec.openapis.org/oas/3.1/schema/2025-09-15>), and the L<OpenAPI v3.1.x specification|https://spec.openapis.org/oas/v3.1>

=back

=for Pod::Coverage THAW get_operationId_path

=head1 CONSTRUCTOR ARGUMENTS

Unless otherwise noted, these are also available as read-only accessors.

=head2 schema

The actual raw data representing the OpenAPI document. Required.

=head2 evaluator

=for stopwords metaschema schema

A L<JSON::Schema::Modern> object which is used for parsing the schema of this document. This is the
object that holds all other schemas that may be used for parsing: that is, metaschemas that define
the structure of the document.

Optional, unless you are using custom metaschemas for your OpenAPI document or embedded JSON Schemas
(in which case you should define the evaluator first and call L<JSON::Schema::Modern/add_schema> for
each customization, before calling this constructor).

This argument is not saved after object construction, so it is not available as an accessor.
However, if this document object was constructed via a call to L<OpenAPI::Modern/new>, it will be
saved on that object for use during request and response validation, so it is expected that the
evaluator object should also hold the other documents that are needed for runtime evaluation (which
may be other L<JSON::Schema::Modern::Document::OpenAPI> objects).

=head2 canonical_uri

This is the identifier that the document is known by, which is used to resolve any relative C<$ref>
keywords in the document (unless overridden by a subsequent C<$id> in a schema).
See L<Specification Reference: Relative References in API Description URIs|https://spec.openapis.org/oas/latest#relative-references-in-api-description-uris>.
It is strongly recommended that this URI is absolute.

In v3.2+ documents, it is used to resolve the C<$self> value in the document itself, which then
replaces this C<canonical_uri> value.

See also L</retrieval_uri>.

=head2 metaschema_uri

The URI of the schema that describes the OpenAPI document itself. Defaults to
C<https://spec.openapis.org/oas/3.2/schema/2025-09-17> (or the equivalent for the
L<OpenAPI version|https://spec.openapis.org/oas/latest#fixed-fields> you specify in the document),
which permits the customization of
L<C<jsonSchemaDialect>|https://spec.openapis.org/oas/latest#openapi-object>, which defines the
JSON Schema dialect to use for embedded JSON Schemas (which itself defaults to
C<https://spec.openapis.org/oas/3.2/dialect/2025-09-17> (or equivalent).

Note that if you are using custom schemas, both of these schemas described by C<metaschema_uri> and
by the C<jsonSchemaDialect> keyword should be loaded into the evaluator in advance with
L<JSON::Schema::Modern/add_schema>, and then this evaluator should be provided to the
L<OpenAPI::Modern> constructor.

=head1 METHODS

This class inherits all methods from L<JSON::Schema::Modern::Document>. In addition:

=head2 upgrade

  Mojo::File->new('new_openapi.yaml')->spew(YAML::PP->new->dump_string($doc->upgrade('3.2')));

Generates the equivalent schema for your document, with syntax altered for the new OpenAPI version.
Defaults to targeting the latest supported version, if not provided.

=head2 retrieval_uri

Also available as L<JSON::Schema::Modern::Document/original_uri>, this is known as the "retrieval
URI" in the OAS specification: the URL the document was originally sourced from, or the URI that
was used to add the document to the L<OpenAPI::Modern> instance.

In OpenAPI versions before 3.2.0, this is the same as L</canonical_uri>.

=head2 oas_version

The C<major.minor> version of the OpenAPI specification being used; derived from the C<openapi>
field at the top of the document. Used to determine the required document format and all derived
behaviours.

Read-only.

=head2 operationId_path

  my $path = $document->operationId_path($operation_id);

Returns the json pointer location of the operation containing the provided C<operationId> (suitable
for passing to C<< $document->get(..) >>), or C<undef> if the operation does not exist in the
document.

=head2 tag_path

  my $path = $document->tag_path($tag_name);

Returns the json pointer location of the provided tag (suitable for passing to
C<< $document->get(..) >>), or C<undef> if the tag is not defined.

Note that a tag name can still be used by an operation even if it has no definition.

=head2 operations_with_tag

Returns the list of json pointer location(s) of operations that use the provided tag.

=head2 path_templates

All path templates under C</paths/>, sorted in canonical search order.

=head2 defaults

A hashref, mapping json pointer locations in the instance data to the default value assigned
to the property at this location, taken from C<default> keywords in the metaschema under
C<properties> and C<patternProperties> keywords.

=head2 default

  my $path = '/components/parameters/MyParameter';
  my $style = $self->get($path.'/style') || $self->default($path.'/style');
  my $explode = $self->get($path.'/explode') || $self->default($path.'/explode');

Accesses an individual entry of L</defaults>.

=head1 SEE ALSO

=over 4

=item *

L<Mojolicious::Plugin::OpenAPI::Modern>

=item *

L<OpenAPI::Modern>

=item *

L<JSON::Schema::Modern>

=item *

L<JSON::Schema::Modern::Document>

=item *

L<https://json-schema.org>

=item *

L<https://www.openapis.org>

=item *

L<https://learn.openapis.org>

=item *

L<https://spec.openapis.org/oas/v3.0>

=item *

L<https://spec.openapis.org/oas/v3.1>

=item *

L<https://spec.openapis.org/oas/v3.2>

=item *

L<https://spec.openapis.org/oas/#schema-iterations>

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
