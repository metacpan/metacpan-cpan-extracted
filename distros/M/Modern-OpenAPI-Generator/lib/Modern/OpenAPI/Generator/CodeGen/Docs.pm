package Modern::OpenAPI::Generator::CodeGen::Docs;

use v5.26;
use strict;
use warnings;
use utf8;
use Carp qw(croak);
use Modern::OpenAPI::Generator ();

sub _perl_method {
    my ($operation_id) = @_;
    return 'operation' unless defined $operation_id && length $operation_id;
    ( my $s = $operation_id ) =~ s{([a-z])([A-Z])}{$1_$2}g;
    $s =~ s{[^A-Za-z0-9]+}{_}g;
    return lc $s;
}

# First OpenAPI tag -> OpenAPI-Generator-style name (e.g. "Recurring Payments" -> RecurringPaymentsApi).
sub _tag_to_api_class {
    my ($tags) = @_;
    my $t = ( ref $tags eq 'ARRAY' && @$tags ) ? $tags->[0] : 'Default';
    $t =~ s/^\s+|\s+$//g;
    return 'DefaultApi' unless length $t;
    my @w = grep { length } split /\s+/, $t;
    my $pascal = join '', map { ucfirst lc $_ } @w;
    $pascal =~ s/[^A-Za-z0-9]//g;
    return 'DefaultApi' unless length $pascal;
    return $pascal . 'Api';
}

sub _first_tag_label {
    my ($tags) = @_;
    return 'Default' unless ref $tags eq 'ARRAY' && @$tags;
    my $t = $tags->[0];
    $t =~ s/^\s+|\s+$//g;
    return length $t ? $t : 'Default';
}

sub _md_cell {
    my ($s) = @_;
    return '' unless defined $s;
    $s =~ s/\r?\n/ /g;
    $s =~ s/\|/\\\|/g;
    return $s;
}

sub _ref_to_schema_name {
    my ($ref) = @_;
    return '' unless defined $ref && length $ref;
    return $1 if $ref =~ m{\#/components/schemas/([^/]+)\z};
    return $1 if $ref =~ m{/([^/]+)\z};
    return $ref;
}

# Same rule as CodeGen::ClientModels: Perl package for components/schemas name.
sub _model_pkg {
    my ( $base, $schema_name ) = @_;
    ( my $safe = $schema_name ) =~ s/[^A-Za-z0-9_]/_/g;
    return "$base\::Model::$safe";
}

sub _schema_type_line {
    my ( $sch, $for_doc_link ) = @_;
    $for_doc_link //= 0;
    return '' unless ref $sch eq 'HASH';
    my $ref = $sch->{'$ref'} // '';
    if ( length $ref ) {
        my $n = _ref_to_schema_name($ref);
        return $for_doc_link && length $n ? "[$n]($n.md)" : $n;
    }
    my $t = $sch->{type} // 'any';
    if ( $t eq 'array' && ref $sch->{items} eq 'HASH' ) {
        return 'array[' . _schema_type_line( $sch->{items}, $for_doc_link ) . ']';
    }
    if ( $t eq 'object' && ref $sch->{properties} eq 'HASH' ) {
        return 'object';
    }
    $t .= ' / ' . $sch->{format} if $sch->{format};
    return $t;
}

sub _merged_parameters_list {
    my ( $spec, $op ) = @_;
    my $path = $op->{path};
    my $item = $spec->raw->{paths}{$path} // {};
    my @p;
    push @p, @{ $item->{parameters} } if ref $item->{parameters} eq 'ARRAY';
    my $m = lc $op->{method};
    my $opobj = $item->{$m} // {};
    push @p, @{ $opobj->{parameters} } if ref $opobj->{parameters} eq 'ARRAY';
    return \@p;
}

sub _security_summary_md {
    my ( $spec, $op ) = @_;
    my @defs = @{ $spec->raw->{security} // [] };
    my @opsec = @{ $op->{operation_hash}{security} // [] };
    my @sec = @opsec ? @opsec : @defs;
    my $schemes = $spec->raw->{components}{securitySchemes} // {};
    return 'None (or inherited from global `security` in the OpenAPI document).' unless @sec;

    my @names;
    for my $h (@sec) {
        next unless ref $h eq 'HASH';
        push @names, keys %$h;
    }
    @names = sort keys %{ { map { $_ => 1 } @names } };
    return join ', ', map { '`' . _md_cell($_) . '`' } @names;
}

sub _resolve_request_body_schema {
    my ($op) = @_;
    my $rb = $op->{operation_hash}{requestBody} // return undef;
    return undef unless ref $rb eq 'HASH';
    my $c = $rb->{content} // {};
    my $json = $c->{'application/json'} // $c->{'application/*+json'};
    return undef unless ref $json eq 'HASH';
    my $sch = $json->{schema};
    return ref $sch eq 'HASH' ? $sch : undef;
}

sub _documentation_for_api_endpoints {
    my ( $spec, $ops, $client ) = @_;
    my $raw = $spec->raw;
    my $base_url = '';
    if ( ref $raw->{servers} eq 'ARRAY' && @{ $raw->{servers} } ) {
        $base_url = $raw->{servers}[0]{url} // '';
    }

    my @lines = ( '## DOCUMENTATION FOR API ENDPOINTS', '' );
    if ( length $base_url ) {
        push @lines, "All URIs are relative to *$base_url*", '';
    }

    if ($client) {
        push @lines,
          '| Class | Method | HTTP request | Description |',
          '|-------|--------|--------------|-------------|';
        for my $op (@$ops) {
            my $class = _tag_to_api_class( $op->{tags} );
            my $file  = "$class.md";
            my $meth  = _perl_method( $op->{operation_id} );
            my $sum   = _md_cell( $op->{operation_hash}{summary} // '' );
            ( my $path = $op->{path} ) =~ s/\|/\\\|/g;
            push @lines,
              sprintf
              '| *[%s](docs/%s)* | [**%s**](docs/%s#%s) | **%s** `%s` | %s |',
              $class, $file, $meth, $file, $meth, $op->{method}, $path, $sum;
        }
    }
    else {
        push @lines,
          '| Class | Method | HTTP request |',
          '|-------|--------|--------------|';
        for my $op (@$ops) {
            my $class = _tag_to_api_class( $op->{tags} );
            my $meth  = _perl_method( $op->{operation_id} );
            ( my $path = $op->{path} ) =~ s/\|/\\\|/g;
            push @lines,
              sprintf '| *%s* | `%s` | **%s** `%s` |',
              $class, $meth, $op->{method}, $path;
        }
    }

    if ( !@$ops ) {
        push @lines, '| — | — | — | — |' if $client;
        push @lines, '| — | — | — |' if !$client;
    }

    return join( "\n", @lines ) . "\n\n";
}

sub _documentation_for_models {
    my ( $spec, $base ) = @_;
    my $schemas = $spec->raw->{components}{schemas} // {};
    return '' unless ref $schemas eq 'HASH' && %$schemas;

    my @lines = ( '## DOCUMENTATION FOR MODELS', '' );
    for my $name ( sort keys %$schemas ) {
        my $pkg = _model_pkg( $base, $name );
        push @lines, "- [`$pkg`](docs/$name.md)";
    }
    return join "\n", @lines, '';
}

sub _tag_api_operation_md {
    my ( $spec, $base, $class, $op ) = @_;
    my $meth = _perl_method( $op->{operation_id} );
    my $oh   = $op->{operation_hash};
    my $sum  = $oh->{summary} // '';
    my $des  = $oh->{description} // '';
    ( my $path_e = $op->{path} ) =~ s/\|/\\\|/g;

    my @out;
    push @out, "<a id=\"$meth\"></a>", '', "## `$meth`", '';
    push @out, '**operationId:** `' . _md_cell( $op->{operation_id} ) . '`  ', '';
    push @out, '**HTTP:** **' . $op->{method} . '** `' . $path_e . '`', '';

    if ( length $sum ) {
        push @out, '### Summary', '', $sum, '';
    }
    if ( length $des ) {
        push @out, '### Description', '', $des, '';
    }

    my $params = _merged_parameters_list( $spec, $op );
    if ( @$params ) {
        push @out, '### Parameters', '',
          '| Name | In | Type | Required | Description |',
          '|------|----|------|----------|-------------|';
        for my $p (@$params) {
            my $sch = $p->{schema} // {};
            my $typ = _schema_type_line( ref $sch eq 'HASH' ? $sch : {}, 1 );
            push @out,
              sprintf '| `%s` | %s | %s | %s | %s |',
              _md_cell( $p->{name} // '' ),
              _md_cell( $p->{in} // '' ),
              $typ,
              ( $p->{required} ? 'yes' : 'no' ),
              _md_cell( $p->{description} // '' );
        }
        push @out, '';
    }

    if ( $op->{has_body} ) {
        push @out, '### Request body', '';
        my $rb = $oh->{requestBody};
        if ( ref $rb eq 'HASH' && $rb->{description} ) {
            push @out, $rb->{description}, '';
        }
        my $rs = _resolve_request_body_schema($op);
        if ( ref $rs eq 'HASH' ) {
            if ( my $ref = $rs->{'$ref'} ) {
                my $n = _ref_to_schema_name($ref);
                push @out,
                  'JSON body must match schema '
                  . ( length $n ? "[$n]($n.md)." : '(see OpenAPI `requestBody`).' ),
                  '';
            }
            elsif ( ( $rs->{type} // '' ) eq 'object' && ref $rs->{properties} eq 'HASH' ) {
                push @out,
                  '| Field | Type | Required | Description |',
                  '|-------|------|----------|-------------|';
                my $req = $rs->{required} // [];
                my %r = map { $_ => 1 } @$req;
                for my $k ( sort keys %{ $rs->{properties} } ) {
                    my $ps = $rs->{properties}{$k};
                    push @out,
                      sprintf '| `%s` | %s | %s | %s |',
                      _md_cell($k),
                      _schema_type_line( ref $ps eq 'HASH' ? $ps : {}, 1 ),
                      ( $r{$k} ? 'yes' : 'no' ),
                      _md_cell(
                        ref $ps eq 'HASH' ? ( $ps->{description} // '' ) : ''
                      );
                }
                push @out, '';
            }
            else {
                push @out, 'Type: `' . _schema_type_line($rs) . '`', '';
            }
        }
        else {
            push @out, '(See OpenAPI `requestBody` in `share/openapi.yaml`.)', '';
        }
    }

    push @out, '### Authorization', '', _security_summary_md( $spec, $op ), '', '### Client example', '',
      '```perl', "my \$r = \$client->$meth(", _perl_example_args( $spec, $op ), ');',
      'my \$data = \$r->data;  # response object or plain JSON',
      'my \$tx  = \$r->tx;     # Mojo::Transaction', '```', '',
      '[[Back to API list]](../README.md#documentation-for-api-endpoints)', '';

    return join "\n", @out;
}

sub _perl_example_args {
    my ( $spec, $op ) = @_;
    my @parts;
    my $params = _merged_parameters_list( $spec, $op );
    for my $p (@$params) {
        next unless $p->{required};
        my $n = $p->{name} // next;
        push @parts, "  $n => '...',";
    }
    if ( $op->{has_body} ) {
        push @parts, '  body => { ... },';
    }
    return join "\n", @parts;
}

sub _tag_api_file_md {
    my ( $spec, $base, $class, $ops ) = @_;
    my $tag    = _first_tag_label( $ops->[0]{tags} );
    my $sync   = "$base\::Client::Sync";
    my $async  = "$base\::Client::Async";
    my $core   = "$base\::Client::Core";
    my $raw    = $spec->raw;
    my $base_u = '';
    if ( ref $raw->{servers} eq 'ARRAY' && @{ $raw->{servers} } ) {
        $base_u = $raw->{servers}[0]{url} // '';
    }

    my @top;
    push @top, "# $class", '';
    push @top,
      "Operations tagged **$tag** in the OpenAPI document. "
      . "Call these methods on [`$sync`](../README.md#client-usage) "
      . "or [`$async`](../README.md#client-usage) "
      . "(see also [`$core`](../README.md#client-usage)).",
      '';
    push @top, '```perl', "use $sync;", "use Path::Tiny qw(path);",
      "my \$core = $core->new(",
      "  base_url            => 'https://api.example.com',",
      "  openapi_schema_file => path('share/openapi.yaml')->absolute->stringify,",
      ');',
      "my \$client = $sync->new( core => \$core );",
      '```', '';
    if ( length $base_u ) {
        push @top, "All URIs are relative to *$base_u*", '';
    }

    push @top,
      '| Method | HTTP request | Description |',
      '|--------|--------------|-------------|';
    for my $op (@$ops) {
        my $meth = _perl_method( $op->{operation_id} );
        ( my $p = $op->{path} ) =~ s/\|/\\\|/g;
        push @top,
          sprintf '| [**%s**](%s.md#%s) | **%s** `%s` | %s |',
          $meth, $class, $meth, $op->{method}, $p,
          _md_cell( $op->{operation_hash}{summary} // '' );
    }
    push @top, '';

    my @body;
    for my $op (@$ops) {
        push @body, _tag_api_operation_md( $spec, $base, $class, $op );
        push @body, '---', '';
    }

    return join "\n", @top, @body;
}

sub _write_tag_api_docs {
    my ( $writer, $spec, $base, $ops ) = @_;
    my %by;
    for my $op (@$ops) {
        my $c = _tag_to_api_class( $op->{tags} );
        push @{ $by{$c} }, $op;
    }
    for my $class ( sort keys %by ) {
        my $md = _tag_api_file_md( $spec, $base, $class, $by{$class} );
        $writer->write( "docs/$class.md", $md );
    }
}

sub _schema_properties_table {
    my ( $spec, $name, $sch, $depth ) = @_;
    $depth //= 0;
    return '' if $depth > 3;
    return '' unless ref $sch eq 'HASH';
    my $ref = $sch->{'$ref'};
    if ($ref) {
        my $n = _ref_to_schema_name($ref);
        return '' unless length $n;
        return _schema_properties_table( $spec, $n, $spec->raw->{components}{schemas}{$n}, $depth + 1 );
    }
    return '' unless ( $sch->{type} // '' ) eq 'object';
    my $props = $sch->{properties} // {};
    return '' unless ref $props eq 'HASH' && %$props;
    my $req = $sch->{required} // [];
    my %r = map { $_ => 1 } @$req;

    my @lines = (
        '| Name | Type | Description | Notes |',
        '|------|------|-------------|-------|'
    );
    for my $k ( sort keys %$props ) {
        my $ps = $props->{$k};
        push @lines,
          sprintf '| `%s` | %s | %s | %s |',
          _md_cell($k),
          _schema_type_line( ref $ps eq 'HASH' ? $ps : {}, 1 ),
          _md_cell( ref $ps eq 'HASH' ? ( $ps->{description} // '' ) : '' ),
          ( $r{$k} ? '[required]' : '[optional]' );
    }
    return join "\n", @lines;
}

sub _model_doc_footer {
    return join "\n",
      '[[Back to Model list]](../README.md#documentation-for-models)',
      '[[Back to API list]](../README.md#documentation-for-api-endpoints)',
      '[[Back to README]](../README.md)';
}

sub _schema_markdown {
    my ( $spec, $base, $name, $sch ) = @_;
    my $pkg = _model_pkg( $base, $name );
    my @out;
    push @out, "# $pkg", '';
    if ( ref $sch eq 'HASH' && length( $sch->{description} // '' ) ) {
        push @out, $sch->{description}, '';
    }
    push @out, '### Load the model package', '', '```perl', "use $pkg;", '```', '';
    if ( ref $sch ne 'HASH' ) {
        push @out, '', '(Non-object schema; see `share/openapi.yaml`.)', '';
        push @out, '', _model_doc_footer();
        return join "\n", @out;
    }
    my $ref = $sch->{'$ref'};
    if ($ref) {
        my $n = _ref_to_schema_name($ref);
        if ( length $n && $n ne $name ) {
            push @out, '', 'This schema is an alias of ', "[$n]($n.md).", '';
        }
        push @out, '', _model_doc_footer();
        return join "\n", @out;
    }
    my $tbl = _schema_properties_table( $spec, $name, $sch, 0 );
    if ( length $tbl ) {
        push @out, '', '### Properties', '', $tbl, '';
    }
    else {
        push @out, '',
          'See `components.schemas.'
          . $name
          . '` in [`share/openapi.yaml`](../share/openapi.yaml).',
          '';
    }
    push @out, '', _model_doc_footer();
    return join "\n", @out;
}

sub _write_schema_docs {
    my ( $spec, $writer, $base ) = @_;
    my $schemas = $spec->raw->{components}{schemas} // {};
    return unless ref $schemas eq 'HASH';
    for my $name ( sort keys %$schemas ) {
        my $md = _schema_markdown( $spec, $base, $name, $schemas->{$name} );
        $writer->write( "docs/$name.md", $md );
    }
}

sub generate {
    my ( $class, %arg ) = @_;
    my $writer   = $arg{writer}   // croak 'writer';
    my $spec     = $arg{spec}     // croak 'spec';
    my $base     = $arg{base}     // croak 'base';
    my $client   = $arg{client}   // 1;
    my $server   = $arg{server}   // 1;
    my $ui       = $arg{ui}       // 1;
    my $sync     = $arg{sync}     // 1;
    my $async    = $arg{async}    // 1;
    my $ui_only    = $arg{ui_only}    // 0;
    my $local_test = $arg{local_test} // 0;

    my $title = $spec->title;
    my $ver   = $spec->raw->{info}{version} // '';
    my $oav   = $spec->openapi_version;
    my $desc = $spec->raw->{info}{description} // '';
    $desc =~ s/\r\n/\n/g;
    $desc =~ s/\s+\z//;
    my $genver = $Modern::OpenAPI::Generator::VERSION // '0';

    my $ops = $spec->operations;

    if ($client) {
        _write_tag_api_docs( $writer, $spec, $base, $ops );
        _write_schema_docs( $spec, $writer, $base );
    }
    elsif ( $server && $local_test ) {
        _write_schema_docs( $spec, $writer, $base );
    }

    my @rows;
    for my $op (@$ops) {
        my $sum = $op->{operation_hash}{summary} // '';
        $sum =~ s/\|/\\\|/g;
        push @rows,
          sprintf '| %s | %s | %s | %s |',
          $op->{method}, $op->{path}, $op->{operation_id}, $sum;
    }
    my $table = @rows ? join( "\n", @rows ) : '| — | — | — | — |';

    my @parts;

    push @parts, <<"HEAD";
# $title

Perl modules under `$base` - HTTP client (Mojo), optional Mojolicious server, optional Swagger UI.

HEAD

    if ( length $desc ) {
        push @parts, "## Description\n\n$desc\n\n";
    }

    push @parts, <<"VERSION";
## VERSION

- OpenAPI document version: `$oav`
- API version (info.version): `$ver`
- Generator: [Modern::OpenAPI::Generator](https://metacpan.org/) `$genver` (CLI: `oapi-perl-gen`)

VERSION

    push @parts, <<'INSTALL';
## Installation

Dependencies are listed in `cpanfile`. From this directory:

```bash
cpanm --installdeps .
```

Or with Carton / your preferred tool.

INSTALL

    if ($client) {
        my $sync_pkg  = "$base\::Client::Sync";
        my $async_pkg = "$base\::Client::Async";
        my $core_pkg  = "$base\::Client::Core";
        my $meth        = @$ops ? _perl_method( $ops->[0]{operation_id} ) : 'operation';
        my $ex          = '';
        if ( $sync && $async ) {
            $ex = <<"EX";
### Synchronous client (`$sync_pkg`)

```perl
use $sync_pkg;
use Path::Tiny qw(path);

my \$core = $core_pkg->new(
  base_url            => 'https://api.example.com',
  openapi_schema_file => path('share/openapi.yaml')->absolute->stringify,
);
my \$client = $sync_pkg->new( core => \$core );

# First operation in spec as an example (method name is derived from operationId):
my \$r = \$client->$meth();
my \$data = \$r->data;  # inflated from JSON when response has a schema \$ref
```

### Asynchronous client (`$async_pkg`)

```perl
use $async_pkg;
# same \$core as above
my \$async = $async_pkg->new( core => \$core );
\$async->$meth()->then(sub ( \$r ) {
  my \$data = \$r->data;   # same ::Client::Result as sync; \$r->tx is the Mojo::Transaction
  ...
});
```

EX
        }
        elsif ($sync) {
            $ex = <<"EX";
```perl
use $sync_pkg;
use Path::Tiny qw(path);

my \$core = $core_pkg->new(
  base_url            => 'https://api.example.com',
  openapi_schema_file => path('share/openapi.yaml')->absolute->stringify,
);
my \$client = $sync_pkg->new( core => \$core );
my \$r = \$client->$meth();
my \$data = \$r->data;
```

EX
        }
        elsif ($async) {
            $ex = <<"EX";
```perl
use $async_pkg;
use Path::Tiny qw(path);

my \$core = $core_pkg->new(
  base_url            => 'https://api.example.com',
  openapi_schema_file => path('share/openapi.yaml')->absolute->stringify,
);
my \$async = $async_pkg->new( core => \$core );
\$async->$meth()->then(sub ( \$r ) {
  my \$data = \$r->data;   # same ::Client::Result as sync; \$r->tx is the Mojo::Transaction
  ...
});
```

EX
        }

        push @parts, "## Client usage\n\n$ex\n";
        push @parts, <<'CVAL';
### Request validation (client)

When `openapi_schema_file` is set on `::Client::Core`, [OpenAPI::Modern](https://metacpan.org/pod/OpenAPI::Modern) runs **`validate_request`** on the outgoing HTTP request **before** send, and **`validate_response`** on the response **before** inflating JSON into shared `::Model::*` objects. Either failure: synchronous calls **croak**, asynchronous **reject**, with a message that includes the validation result.

CVAL
    }

    if ($server) {
        if ($local_test) {
            push @parts, <<'SERVER';
## Run the HTTP server (Mojolicious + OpenAPI)

From the **generated project root** (where `share/` and `script/` live):

```bash
export MOJO_HOME="$PWD"
export PERL5LIB="$PWD/lib"
perl script/server.pl daemon -l 'http://127.0.0.1:3000'
```

- Replace host/port as needed.
- `MOJO_HOME` must point at this tree so `share/openapi.mojo.yaml` is found.
- This tree was generated with **`oapi-perl-gen --local-test`**: controller actions call **`$c->openapi->valid_input`**, then **`::StubData->for_operation`** builds a random payload from the first 2xx `application/json` response schema, inflates it with **`::Model::*->from_json`** when a model exists, and **`render(json => ...)`** serializes via **`TO_JSON`**. Replace with real logic when you are ready.
- **Swagger UI** (with `--ui`, on by default when you generate the full stack) is on the **same** app and port: **http://127.0.0.1:3000/swagger** — API paths from the spec are on the same origin.

SERVER
        }
        else {
            push @parts, <<'SERVER';
## Run the HTTP server (Mojolicious + OpenAPI)

From the **generated project root** (where `share/` and `script/` live):

```bash
export MOJO_HOME="$PWD"
export PERL5LIB="$PWD/lib"
perl script/server.pl daemon -l 'http://127.0.0.1:3000'
```

- Replace host/port as needed.
- `MOJO_HOME` must point at this tree so `share/openapi.mojo.yaml` is found.
- Default routes follow the spec; each action starts with **`$c->openapi->valid_input`** so the **incoming request** is checked against the spec (invalid requests get **400**). Controller stubs then return **501** until you implement them (or regenerate with **`oapi-perl-gen --local-test`** for **`StubData`** + **`Model::*`** responses).
- **Swagger UI** (with `--ui`, on by default when you generate the full stack) is on the **same** app and port: **http://127.0.0.1:3000/swagger** — API paths from the spec are on the same origin.

SERVER
        }

        if ($ui) {
            push @parts, <<'UI';
- OpenAPI for Swagger: **http://127.0.0.1:3000/openapi.yaml** — by default the YAML `servers` list is **unchanged** from the spec. To **prepend the current request origin** (so **Try it out** targets the daemon you opened Swagger on, any `-l` port), run the app with **`--local-test`** on **`script/server.pl`** (not the `oapi-perl-gen` flag), e.g. `perl script/server.pl daemon -l 'http://127.0.0.1:3000' --local-test`, or set **`OAPI_SWAGGER_LOCAL_ORIGIN=1`**.

UI
        }

        push @parts, <<'MORBO';
### Development server (reload on change)

If `morbo` is available (ships with Mojolicious):

```bash
export MOJO_HOME="$PWD"
export PERL5LIB="$PWD/lib"
morbo script/server.pl -l 'http://127.0.0.1:3000'
```

MORBO
    }

    if ($ui_only) {
        push @parts, <<'UIONLY';
## Spec browser only (`--no-server --ui`)

The same **`script/server.pl`** runs a minimal Mojolicious app: `share/openapi.yaml` on disk plus Swagger UI — **no** OpenAPI-driven API routes.

```bash
export MOJO_HOME="$PWD"
export PERL5LIB="$PWD/lib"
perl script/server.pl daemon -l 'http://127.0.0.1:3000'
```

- Swagger UI: **http://127.0.0.1:3000/swagger**
- `/openapi.yaml` prepends the request origin to `servers` only when **`script/server.pl` is run with `--local-test`** (or `OAPI_SWAGGER_LOCAL_ORIGIN=1`), same as the full server.

UIONLY
    }

    push @parts, <<'TESTS';
## Tests (generated smoke / load)

```bash
prove -l t
```

TESTS

    my $layout_docs = '';
    if ($client) {
        $layout_docs =
"| `docs/` | Per-tag API docs (`*Api.md`) and `components/schemas` model docs (`*.md`) |\n";
    }
    elsif ( $server && $local_test ) {
        $layout_docs =
"| `docs/` | `components/schemas` model docs (`*.md`) (with `--local-test` server, models are generated even if `--no-client`) |\n";
    }

    push @parts, <<"OPS";
## Operations

| HTTP | Path | operationId | Summary |
|------|------|-------------|---------|
$table

## Layout

| Path | Purpose |
|------|---------|
| `lib/` | `::Client::*`, `::Server::*`, shared `::Model::*` (OpenAPI schemas), optional `::StubData` (`--local-test` server) |
| `share/` | `openapi.yaml` (copy of spec); with full server also `openapi.mojo.yaml` for Mojolicious::Plugin::OpenAPI |
| `script/server.pl` | Single entrypoint: full API + Swagger UI at `/swagger`, or spec-only mode when generated with `--no-server --ui` |
${layout_docs}| `t/` | Tests for **this generated tree** |
| `cpanfile` | Runtime and test dependencies |

OPS

    push @parts, _documentation_for_api_endpoints( $spec, $ops, $client );

    push @parts, _documentation_for_models( $spec, $base )
      if $client || ( $server && $local_test );

    $writer->write( 'README.md', join '', @parts );
}

1;

__END__

=encoding utf8

=head1 NAME

Modern::OpenAPI::Generator::CodeGen::Docs - Generate F<README.md> and F<docs/*.md>

=head1 DESCRIPTION

Per-tag API Markdown, per-schema model pages, and a project README in the output
tree.

=head2 generate

Class method. Arguments include C<writer>, C<spec>, C<base>, and booleans
C<client>, C<server>, C<ui>, C<sync>, C<async>, C<ui_only>, C<local_test>.

=cut
