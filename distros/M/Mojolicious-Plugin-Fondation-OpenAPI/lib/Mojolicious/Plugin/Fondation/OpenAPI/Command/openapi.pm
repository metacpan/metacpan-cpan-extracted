package Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi;
$Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi::VERSION = '0.02';
# ABSTRACT: Generate OpenAPI specification from DBIx::Class sources

use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::File 'path';
use Mojo::JSON qw(decode_json encode_json true false);


has description => 'OpenAPI specification generator and permission synchronizer';
has usage       => sub ($self) {
    <<"USAGE";
Usage: APPLICATION openapi COMMAND [OPTIONS]

Commands:
  generate           Generate share/openapi.json
  sync-permissions   Create missing permissions in the database from x-auth
                     annotations in share/openapi.json, and assign them all
                     to the admin group.
  sync-permissions -q  Quiet mode (no output)

Options (generate):
  -y                 Force overwrite without prompt
  --output FILE      Custom output path

USAGE
};

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

sub run ($self, @args) {
    my $app = $self->app;

    my $config = $app->defaults->{'openapi.config'}
        or die "OpenAPI not configured. Add Fondation::OpenAPI to your config.\n";

    my $subcommand = shift @args || '';

    if ($subcommand eq 'sync-permissions') {
        return $self->_sync_permissions($app, $config, @args);
    }

    die $self->usage unless $subcommand eq 'generate';

    # Parse options
    my $force  = 0;
    my $output = 'share/openapi.json';

    while (@args) {
        my $arg = shift @args;
        if ($arg eq '-y') {
            $force = 1;
        }
        elsif ($arg eq '--output' && @args) {
            $output = shift @args;
        }
        else {
            die "Unknown option: $arg\n" . $self->usage;
        }
    }

    # Check overwrite
    my $output_path = $app->home->child($output);
    if (!$force && -f $output_path) {
        print "File '$output' already exists. Overwrite? [y/N] ";
        my $answer = <STDIN>;
        chomp $answer;
        exit(0) unless $answer =~ /^y(es)?$/i;
    }

    # Resolve schema class
    my $schema_class = $self->_get_schema_class($app, $config)
        or return;

    # Generate spec
    my $spec = $self->_build_spec($schema_class, $app, $config);

    # Write OpenAPI spec
    $output_path->dirname->make_path;
    $output_path->spurt(encode_json($spec));

    my $source_count = scalar keys %{$spec->{components}{schemas}};
    say "OpenAPI spec written to $output ($source_count source(s))";

    # Generate and write client-side validators.js
    my $validators_js = $self->_build_validators_js($spec);
    my $validators_path = $app->home->child('public', 'js', 'validators.js');
    $validators_path->dirname->make_path;
    $validators_path->spurt($validators_js);
    say "Client validators written to public/js/validators.js";
}

# ---------------------------------------------------------------------------
# Sync permissions from share/openapi.json to the database
# ---------------------------------------------------------------------------

sub _sync_permissions ($self, $app, $config, @args) {
    my $quiet = 0;
    for (@args) {
        if ($_ eq '-q') { $quiet = 1 }
        else { die "Unknown option: $_\n" . $self->usage }
    }

    # 1. Read share/openapi.json
    my $spec_file = $app->home->child('share', 'openapi.json');
    unless (-f $spec_file) {
        say "No spec found at share/openapi.json. Run 'openapi generate' first."
            unless $quiet;
        return;
    }

    my $spec = eval { decode_json($spec_file->slurp) };
    die "Failed to parse share/openapi.json: $@\n" if $@;

    # 2. Extract all unique permissions from x-auth
    my %perms;
    for my $path_data (values %{$spec->{paths} // {}}) {
        for my $method (values %$path_data) {
            next unless ref $method eq 'HASH';
            my $x_auth = $method->{'x-auth'} or next;
            for my $p (@{$x_auth->{permissions} // []}) {
                $perms{$p} = 1;
            }
        }
    }

    unless (%perms) {
        say "No permissions found in spec." unless $quiet;
        return;
    }

    # 3. Get schema from Model::DBIx::Async (lazy, cached, worker pool)
    my $c = $app->build_controller;
    my $schema = eval { $c->schema };
    unless ($schema) {
        say "No backend configured. Cannot sync permissions." unless $quiet;
        return;
    }

    # 4. Check if Perm source is registered
    my $rs_perm = eval { $schema->resultset('Perm') };
    unless ($rs_perm) {
        warn "[sync-permissions] No 'Perm' source registered."
            . " Is Fondation::Perm loaded?\n";
        return;
    }

    # 5. Create missing permissions
    my (@created, @skipped);
    for my $name (sort keys %perms) {
        if ($schema->await($rs_perm->find({ name => $name }))) {
            push @skipped, $name;
        } else {
            eval { $schema->await($rs_perm->create({ name => $name })) };
            if ($@) {
                say "Failed to create permission '$name': $@" unless $quiet;
            } else {
                push @created, $name;
            }
        }
    }

    warn "[sync-permissions] Permissions: created " . scalar(@created)
        . ", skipped " . scalar(@skipped) . " (already exist).\n";

    # 6. Ensure admin group exists
    my $rs_group = eval { $schema->resultset('Group') };
    unless ($rs_group) {
        warn "[sync-permissions] No 'Group' source registered."
            . " Is Fondation::Group loaded?\n";
        return;
    }
    my $admin = $schema->await($rs_group->find({ name => 'admin' }));
    unless ($admin) {
        eval { $admin = $schema->await($rs_group->create({ name => 'admin', active => 1 })) };
        if ($@) {
            warn "[sync-permissions] Failed to create 'admin' group: $@\n";
            return;
        }
        warn "[sync-permissions] Created 'admin' group.\n";
    }

    # 7. Assign all permissions to admin group
    my $rs_gp = eval { $schema->resultset('GroupPerm') };
    unless ($rs_gp) {
        warn "[sync-permissions] No 'GroupPerm' source registered."
            . " Is Fondation::Perm loaded?\n";
        return;
    }
    my $assigned = 0;
    for my $name (sort keys %perms) {
        my $perm = $schema->await($rs_perm->find({ name => $name })) or next;
        unless ($schema->await($rs_gp->find({ group_id => $admin->id, perm_id => $perm->id }))) {
            eval { $schema->await($rs_gp->create({ group_id => $admin->id, perm_id => $perm->id })) };
            if ($@) {
                warn "[sync-permissions] Failed to assign '$name' to admin: $@\n";
            } else {
                $assigned++;
            }
        }
    }
    warn "[sync-permissions] Assigned $assigned permission(s) to 'admin' group.\n";
}

# ---------------------------------------------------------------------------
# Build client-side validators.js from the OpenAPI spec
# ---------------------------------------------------------------------------

sub _build_validators_js ($self, $spec) {
    my $schemas = $spec->{components}{schemas};
    my $schemas_js = '';

    for my $name (sort keys %$schemas) {
        my $schema = $schemas->{$name};
        my $props  = $schema->{properties} // {};

        $schemas_js .= "FondationSchemas['$name'] = {\n";
        $schemas_js .= "  properties: {\n";

        for my $prop (sort keys %$props) {
            my $def = $props->{$prop};
            my @rules;

            push @rules, "required: true"
                if grep { $_ eq $prop } @{ $schema->{required} // [] };
            push @rules, "type: '" . $def->{type} . "'"
                if $def->{type};
            push @rules, "minLength: " . $def->{minLength}
                if $def->{minLength};
            push @rules, "maxLength: " . $def->{maxLength}
                if $def->{maxLength};
            push @rules, "format: '" . $def->{format} . "'"
                if $def->{format};
            push @rules, "nullable: true"
                if $def->{nullable};
            push @rules, "readOnly: true"
                if $def->{readOnly};
            push @rules, "writeOnly: true"
                if $def->{writeOnly};

            $schemas_js .= "    '$prop': { " . join(', ', @rules) . " },\n";
        }

        $schemas_js .= "  }\n";
        $schemas_js .= "};\n\n";
    }

    my $validators = <<'VALIDATORS';
var FondationSchemas = {};
SCHEMAS_PLACEHOLDER

window.FondationValidators = {
    validate: function(schemaName, data) {
        var schema = FondationSchemas[schemaName];
        if (!schema) return { valid: false, errors: ['Schema not found: ' + schemaName] };

        var errors = [];

        for (var prop in schema.properties) {
            var rules = schema.properties[prop];
            var val   = data[prop];

            // Skip readOnly fields (server-managed, not in forms)
            if (rules.readOnly) continue;

            // Required check (skip readOnly -- server-managed)
            if (rules.required && !rules.readOnly) {
                if (val === undefined || val === null || val === '') {
                    errors.push(prop + ' is required');
                    continue;
                }
            }

            // Skip further checks if value is empty and not required
            if (val === undefined || val === null || val === '') {
                if (rules.nullable) continue;
                continue;
            }

            // Type check
            if (rules.type === 'integer') {
                var n = Number(val);
                if (isNaN(n) || !Number.isInteger(n)) {
                    errors.push(prop + ' must be an integer');
                    continue;
                }
            }

            // Format check
            if (rules.format === 'email') {
                if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val)) {
                    errors.push(prop + ' must be a valid email');
                }
            }

            // Min length
            if (rules.minLength && typeof val === 'string' && val.length < rules.minLength) {
                errors.push(prop + ' must be at least ' + rules.minLength + ' characters');
            }

            // Max length
            if (rules.maxLength && typeof val === 'string' && val.length > rules.maxLength) {
                errors.push(prop + ' must be at most ' + rules.maxLength + ' characters');
            }

            // Enum check
            if (rules.enum) {
                var match = false;
                for (var i = 0; i < rules.enum.length; i++) {
                    if (rules.type === 'integer') {
                        if (Number(val) === rules.enum[i]) { match = true; break; }
                    } else {
                        if (val === String(rules.enum[i])) { match = true; break; }
                    }
                }
                if (!match) {
                    errors.push(prop + ' must be one of: ' + rules.enum.join(', '));
                }
            }

            // Password format
            if (rules.format === 'password') {
                if (typeof val === 'string' && val.length > 0 && val.length < (rules.minLength || 8)) {
                    errors.push(prop + ' must be at least ' + (rules.minLength || 8) + ' characters');
                }
            }
        }

        return {
            valid: errors.length === 0,
            errors: errors
        };
    }
};
VALIDATORS

    $validators =~ s/SCHEMAS_PLACEHOLDER/$schemas_js/;
    return $validators;
}

# ---------------------------------------------------------------------------
# Build complete OpenAPI spec from DBIx::Class sources
# ---------------------------------------------------------------------------

sub _build_spec ($self, $schema_class, $app, $config) {
    my $spec = {
        openapi => '3.0.3',
        info    => {
            title       => 'Fondation API',
            version     => '1.0',
            description => 'AUTO-GENERATED -- Do not modify manually',
        },
        servers    => [{url => '/api'}],
        paths      => {},
        components => {schemas => {}},
    };

    # Config overrides: schemas => { Source => { columns => { Col => {...} } } }
    my $schemas_config = $config->{schemas} // {};

    # Build lookup: table_name → Result class from all plugins' registry
    my %result_classes;
    for my $entry (values %{$app->fondation->registry}) {
        next unless $entry->{dbic} && $entry->{dbic}{result_classes};
        %result_classes = (%result_classes, %{$entry->{dbic}{result_classes}});
    }

    # Collect openapi_exclude from all plugins' config
    my %openapi_exclude;
    for my $entry (values %{$app->fondation->registry}) {
        my $excl = $entry->{config}{openapi_exclude} // [];
        $openapi_exclude{$_} = 1 for @$excl;
    }

    for my $table_name ($schema_class->sources) {

        my $source     = $schema_class->source($table_name);
        my $columns_info = $source->columns_info;
        my $resultname   = $self->_extract_name($result_classes{$table_name});
        my $src_config   = $schemas_config->{$table_name}
                        // $schemas_config->{$resultname} // {};
        my $col_configs  = $src_config->{columns} // {};

        # Skip sources excluded by plugins
        next if $openapi_exclude{$table_name};

        # ------------------------------------------------------------------
        # STEP A -- Build the API Base (canonical schema)
        #
        # Three-layer cascade, highest priority wins:
        #   1. DBIx structure    (implicit: data_type, size, is_nullable, ...)
        #   2. extra->{openapi}  (flat keys declared in Result class)
        #   3. Config override   (flat keys in myapp.conf)
        #
        # After the cascade, writeOnly columns are stripped from the
        # API Base — they only appear in create/update/patch contexts.
        # ------------------------------------------------------------------
        my %api_props;
        my @api_required;

        for my $col (sort keys %$columns_info) {
            my $info    = $columns_info->{$col};
            my $openapi = $info->{extra}{openapi} // {};
            my $cfg     = $col_configs->{$col} // {};
            my %prop;

            # --- Level 1: DBIx structure (implicit) ---
            $prop{type}      = $self->_resolve_type($info);
            $prop{maxLength} = int($info->{size})
                if $prop{type} eq 'string' && defined $info->{size};
            $prop{nullable}  = true if $info->{is_nullable};
            $prop{default}   = $info->{default_value}
                if defined $info->{default_value};

            # Implicit rules from DBIx structure
            $prop{readOnly} = true if $info->{is_auto_increment};
            $prop{readOnly} = true if $col eq 'created_at' || $col eq 'updated_at';
            $prop{format}   = 'date'       if $info->{data_type} =~ /^date$/i;
            $prop{format}   = 'date-time'  if $info->{data_type} =~ /datetime|timestamp/i;
            $prop{format}   = 'float'      if $info->{data_type} =~ /^float$/i;
            $prop{format}   = 'double'     if $info->{data_type} =~ /^double$/i;

            # --- Level 2: extra->{openapi} flat keys ---
            $self->_apply_openapi_flat(\%prop, $openapi);

            # --- Level 3: Config override flat keys ---
            $self->_apply_openapi_flat(\%prop, $cfg);

            # Description fallback
            $prop{description} //= ucfirst join(' ', split /[_-]/, $col);

            $api_props{$col} = \%prop;

            # Required: is_nullable explicitly set to 0, no default_value, AND NOT writeOnly/readOnly
            if ((exists $info->{is_nullable} && !$info->{is_nullable})
                && !defined $info->{default_value}
                && !$prop{writeOnly} && !$prop{readOnly}) {
                push @api_required, $col;
            }
        }

        # API Base: exclude writeOnly properties
        my %api_base_props;
        for my $col (sort keys %api_props) {
            next if $api_props{$col}{writeOnly};
            $api_base_props{$col} = $api_props{$col};
        }

        my $api_base = {
            type        => 'object',
            title       => $resultname,
            description => "Schema for $resultname",
            properties  => \%api_base_props,
            required    => \@api_required,
        };

        # Store writeOnly columns for create/update contexts
        my @write_only_cols = grep { $api_props{$_}{writeOnly} } sort keys %api_props;

        # ------------------------------------------------------------------
        # STEP B -- Build contextual projections
        #
        # For each CRUD context (create, update, read, list, patch),
        # start from the API Base and apply context-specific rules:
        #   - create/update/patch: re-inject writeOnly columns (e.g. password)
        #   - PATCH: nothing required by default (partial update)
        #   - extra->{openapi}->{context}->{required} overrides
        #   - Config contextual overrides
        #
        # A contextual schema is only emitted when it differs from the
        # API Base (different properties or different required array).
        # ------------------------------------------------------------------
        my %contexts;
        my @context_names = qw(create update read list patch);

        for my $ctx_name (@context_names) {
            # PATCH: nothing required by default (partial update)
            # All field-level constraints (minLength, pattern, ...) still apply
            my $ctx_required = $ctx_name eq 'patch' ? [] : [@api_required];

            # Start with API Base properties
            my %ctx_props = %api_base_props;

            # create/update/patch: add writeOnly properties
            if ($ctx_name eq 'create' || $ctx_name eq 'update' || $ctx_name eq 'patch') {
                for my $wcol (@write_only_cols) {
                    $ctx_props{$wcol} = $api_props{$wcol};
                }
            }

            for my $col (sort keys %$columns_info) {
                my $openapi = $columns_info->{$col}{extra}{openapi} // {};
                my $cfg     = $col_configs->{$col} // {};

                # Contextual required: extra->{openapi}->{contexte}->{required}
                if (exists $openapi->{$ctx_name}{required}) {
                    if ($openapi->{$ctx_name}{required}) {
                        push @$ctx_required, $col
                            unless grep { $_ eq $col } @$ctx_required;
                    }
                    else {
                        @$ctx_required = grep { $_ ne $col } @$ctx_required;
                    }
                }

                # Contextual required: config override
                if (exists $cfg->{$ctx_name}{required}) {
                    if ($cfg->{$ctx_name}{required}) {
                        push @$ctx_required, $col
                            unless grep { $_ eq $col } @$ctx_required;
                    }
                    else {
                        @$ctx_required = grep { $_ ne $col } @$ctx_required;
                    }
                }
            }

            # Compare properties + required (order-independent)
            unless ($self->_schema_equal(
                \%ctx_props, $ctx_required,
                \%api_base_props, \@api_required
            )) {
                my %schema = (
                    type        => 'object',
                    title       => "$resultname ($ctx_name)",
                    description => "Schema for $ctx_name on $resultname",
                    properties  => \%ctx_props,
                );
                $schema{required} = $ctx_required if @$ctx_required;
                $contexts{$ctx_name} = \%schema;
            }
        }

        # ------------------------------------------------------------------
        # STEP C -- Register schemas in the OpenAPI spec
        #
        # Store the API Base under its moniker (e.g. "User"), plus any
        # contextual schemas that differ from it (e.g. "UserCreate",
        # "UserUpdate"). Contextual schema keys use the PascalCase
        # notation: "${resultname}${Context}".
        # ------------------------------------------------------------------
        $spec->{components}{schemas}{$resultname} = $api_base;

        for my $ctx_name (@context_names) {
            next unless $contexts{$ctx_name};
            $spec->{components}{schemas}{"${resultname}\u$ctx_name"} = $contexts{$ctx_name};
        }

        # ------------------------------------------------------------------
        # STEP D -- Generate CRUD paths
        #
        # Five REST endpoints per source with automatic x-mojo-to
        # routing and x-auth permission annotations:
        #   GET    /{moniker}       → list    (x-auth: {moniker}_list)
        #   POST   /{moniker}       → create  (x-auth: {moniker}_create)
        #   GET    /{moniker}/{id}  → read    (x-auth: {moniker}_read)
        #   PUT    /{moniker}/{id}  → update  (x-auth: {moniker}_update)
        #   PATCH  /{moniker}/{id}  → update  (same x-auth as PUT)
        #   DELETE /{moniker}/{id}  → delete  (x-auth: {moniker}_delete)
        #
        # Each operation references the appropriate contextual schema
        # when available, falling back to the API Base otherwise.
        # ------------------------------------------------------------------
        my $path_name = lc $resultname;

        # Helper: resolve schema ref for a context
        my $schema_ref = sub ($ctx) {
            my $key = "${resultname}\u$ctx";
            return $contexts{$ctx}
                ? "#/components/schemas/$key"
                : "#/components/schemas/$resultname";
        };

        # Build x-auth for each CRUD operation
        my $x_auth = {
            list   => $self->_build_x_auth($src_config, $resultname, 'list'),
            create => $self->_build_x_auth($src_config, $resultname, 'create'),
            read   => $self->_build_x_auth($src_config, $resultname, 'read'),
            update => $self->_build_x_auth($src_config, $resultname, 'update'),
            delete => $self->_build_x_auth($src_config, $resultname, 'delete'),
        };

        # Helper: return x-auth wrapped in hashref only if non-empty
        my $maybe_x_auth = sub ($op) {
            my $xa = $x_auth->{$op};
            return unless $xa && %$xa;
            return {'x-auth' => $xa};
        };

        # Collection paths
        $spec->{paths}{"/$path_name"} = {
            get => {
                summary     => "List all $path_name",
                operationId => "list_$path_name",
                %{ $maybe_x_auth->('list') // {} },
                responses   => {
                    '200' => {
                        description => 'Success',
                        content     => {
                            'application/json' => {
                                schema => {
                                    type  => 'array',
                                    items => {'$ref' => $schema_ref->('list')},
                                },
                            },
                        },
                    },
                },
                'x-mojo-to' => "$resultname#list",
            },
            post => {
                summary     => "Create a new $path_name",
                operationId => "create_$path_name",
                %{ $maybe_x_auth->('create') // {} },
                requestBody => {
                    required => true,
                    content  => {
                        'application/json' => {
                            schema => {'$ref' => $schema_ref->('create')},
                        },
                    },
                },
                responses  => {'201' => {description => 'Created'}},
                'x-mojo-to' => "$resultname#create",
            },
        };

        # Item paths
        $spec->{paths}{"/$path_name/{id}"} = {
            parameters => [
                {in => 'path', name => 'id', required => true, schema => {type => 'integer'}},
            ],
            get => {
                summary     => "Get a $path_name by ID",
                operationId => "read_$path_name",
                %{ $maybe_x_auth->('read') // {} },
                responses   => {
                    '200' => {
                        description => 'Success',
                        content     => {
                            'application/json' => {
                                schema => {'$ref' => $schema_ref->('read')},
                            },
                        },
                    },
                },
                'x-mojo-to' => "$resultname#read",
            },
            put => {
                summary     => "Update a $path_name by ID",
                operationId => "update_$path_name",
                %{ $maybe_x_auth->('update') // {} },
                requestBody => {
                    required => true,
                    content  => {
                        'application/json' => {
                            schema => {'$ref' => $schema_ref->('update')},
                        },
                    },
                },
                responses   => {'200' => {description => 'Success'}},
                'x-mojo-to' => "$resultname#update",
            },
            patch => {
                summary     => "Partially update a $path_name by ID",
                operationId => "patch_$path_name",
                %{ $maybe_x_auth->('update') // {} },
                requestBody => {
                    required => true,
                    content  => {
                        'application/json' => {
                            schema => {'$ref' => $schema_ref->('patch')},
                        },
                    },
                },
                responses   => {'200' => {description => 'Success'}},
                'x-mojo-to' => "$resultname#update",
            },
            delete => {
                summary     => "Delete a $path_name by ID",
                operationId => "delete_$path_name",
                %{ $maybe_x_auth->('delete') // {} },
                responses   => {'204' => {description => 'Deleted'}},
                'x-mojo-to' => "$resultname#delete",
            },
        };
    }

    return $spec;
}

# ---------------------------------------------------------------------------
# Resolve OpenAPI type from DBIx data_type
# ---------------------------------------------------------------------------

sub _resolve_type ($self, $info) {
    my $dt = $info->{data_type} // '';
    return 'integer' if $dt =~ /int|integer|serial|bigint|smallint|tinyint|mediumint/i;
    return 'number'  if $dt =~ /float|decimal|numeric|real|double/i && $dt !~ /double precision/i;
    return 'number'  if $dt =~ /double precision/i;
    return 'boolean' if $dt =~ /boolean/i;
    return 'string';
}

# ---------------------------------------------------------------------------
# Apply openapi flat keys (non-contextual) to a property hashref
# ---------------------------------------------------------------------------

sub _apply_openapi_flat ($self, $prop, $openapi) {
    my %flat_keys = map { $_ => 1 } qw(
        format minLength maxLength minimum maximum
        enum writeOnly readOnly description
        type nullable default
    );

    my %bool_keys = map { $_ => 1 } qw(writeOnly readOnly nullable);

    for my $k (keys %$openapi) {
        next unless $flat_keys{$k};
        if ($bool_keys{$k}) {
            $prop->{$k} = $openapi->{$k} ? true : false;
        } else {
            $prop->{$k} = $openapi->{$k};
        }
    }
}

# ---------------------------------------------------------------------------
# Compare two schemas: property names + required arrays (order-independent)
# ---------------------------------------------------------------------------

sub _schema_equal ($self, $props_a, $req_a, $props_b, $req_b) {
    # Compare property names
    my @keys_a = sort keys %$props_a;
    my @keys_b = sort keys %$props_b;
    return 0 if @keys_a != @keys_b;
    for my $i (0 .. $#keys_a) {
        return 0 unless $keys_a[$i] eq $keys_b[$i];
    }

    # Compare required (order-independent)
    return 0 if @$req_a != @$req_b;
    my %seen = map { $_ => 1 } @$req_a;
    for my $item (@$req_b) {
        return 0 unless $seen{$item};
    }

    return 1;
}

# ---------------------------------------------------------------------------
# Build x-auth from convention + config override
# ---------------------------------------------------------------------------

sub _build_x_auth ($self, $src_config, $resultname, $operation) {
    # Config override: schemas.{Source}.x_auth.{operation}
    my $override = $src_config->{x_auth}{$operation};

    if (defined $override) {
        # Normalize: empty permissions + no other constraints → no x-auth
        my $perms = $override->{permissions};
        return {}
            unless ($perms && @$perms)
                || grep { $_ ne 'permissions' } keys %$override;
        return $override;
    }

    # Default convention: {moniker_lc}_{operation}
    return {
        permissions => [lc($resultname) . "_$operation"],
    };
}

# ---------------------------------------------------------------------------
# Resolve schema class name from backend config (no DB connection needed)
# ---------------------------------------------------------------------------

sub _get_schema_class ($self, $app, $config) {
    # Resolve backend: explicit config -> DBIx::Async default -> first backend -> undef
    my $c = $app->build_controller;
    my $backend_name;
    if ($c->has_helper('default_backend_name')) {
        $backend_name = $c->default_backend_name($config->{backend});
    } else {
        $backend_name = $config->{backend};
    }

    unless ($backend_name) {
        say "No backend configured. Set 'backend' in OpenAPI config"
            . " or 'default_backend' in Fondation::Model::DBIx::Async.";
        return undef;
    }

    unless ($c->has_helper('backend_config')) {
        say "Fondation::Model::DBIx::Async is not loaded. No backend_config helper.";
        return undef;
    }

    my $bdef = eval { $c->backend_config($backend_name) };
    unless ($bdef) {
        say "Backend '$backend_name' not found.";
        return undef;
    }

    my $schema_class = $bdef->{schema_class}
        or die "No schema_class configured for backend '$backend_name'\n";

    eval "require $schema_class; 1"
        or die "Cannot load schema class $schema_class: $@\n";

    return $schema_class;
}

# ---------------------------------------------------------------------------
# Extract CamelCase name from Result class
#   Mojolicious::...::Result::Foo → Foo
#   Mojolicious::...::Result::UserGroup → UserGroup
# ---------------------------------------------------------------------------

sub _extract_name ($self, $result_class) {
    return undef unless $result_class;
    my ($name) = $result_class =~ /::Result::([^:]+)$/;
    return $name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi - Generate OpenAPI specification from DBIx::Class sources

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  $ myapp.pl openapi generate
  $ myapp.pl openapi generate -y
  $ myapp.pl openapi generate --output custom.json

=head1 DESCRIPTION

Command-line interface for generating an OpenAPI 3.0.3 specification
from DBIx::Class sources discovered via L<Fondation::Model::DBIx::Async>.

No database connection is required -- sources are read from the schema
class metadata via C<< $schema_class->sources >>.

=head1 NAME

Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi - Generate OpenAPI specification from DBIx::Class sources

This module is more than experimental !

=head1 DESIGN

=head2 Two layers

The generator works with two conceptual layers:

=over

=item DBIx source

The raw database structure: column types, constraints, defaults.

=item API Base

The canonical OpenAPI representation of the resource. Built from the
DBIx source with implicit rules applied, then overridden by
C<extra-E<gt>{openapi}> annotations and plugin configuration.

=back

=head2 Implicit rules

The following rules are derived automatically from DBIx structure and
require no C<extra-E<gt>{openapi}> annotations:

  DBIx                          -> OpenAPI
  ─────────────────────────────   ───────
  is_auto_increment = 1          readOnly: true
  column named created_at        readOnly: true
  column named updated_at        readOnly: true
  data_type =~ /^date$/i         format: "date"
  data_type =~ /datetime/i       format: "date-time"
  data_type =~ /timestamp/i      format: "date-time"
  data_type =~ /^float$/i        format: "float"
  data_type =~ /^double$/i       format: "double"
  is_nullable = 0                required (unless writeOnly/readOnly)
  size = N (string type)         maxLength: N
  data_type =~ /int|serial/i     type: "integer"
  data_type =~ /float|decimal/i  type: "number"
  data_type =~ /boolean/i        type: "boolean"
  default_value                  default
  is_nullable = 1                nullable: true

=head2 extra->{openapi} annotations

Semantic choices that cannot be derived from DBIx are declared in the
Result class via C<extra-E<gt>{openapi}>:

  username => {
      data_type => 'varchar', size => 100, is_nullable => 0,
      extra => {
          openapi => {
              minLength => 4,
          },
      },
  },

=head3 Flat keys (apply to all contexts)

  format      -- "email", "password", "uri", etc.
  minLength   -- minimum string length
  maxLength   -- maximum string length (overrides DBIx size)
  minimum     -- minimum numeric value
  maximum     -- maximum numeric value
  enum        -- arrayref of allowed values
  writeOnly   -- boolean, field only sent in requests
  readOnly    -- boolean, field only sent in responses (overrides implicit)
  description -- human-readable description
  type        -- override the inferred OpenAPI type
  nullable    -- override the inferred nullability
  default     -- override the inferred default value

=head3 Contextual keys (per-operation overrides)

  create => { required => 1 }   # force required on POST
  create => { required => 0 }   # force optional on POST
  update => { required => 1 }   # force required on PUT
  update => { required => 0 }   # force optional on PUT
  read   => { required => 1 }   # force required on GET item
  read   => { required => 0 }   # force optional on GET item
  list   => { required => 1 }   # force required on GET collection
  list   => { required => 0 }   # force optional on GET collection

=head2 Conditional schema generation

Contextual schemas (C<UserCreate>, C<UserUpdate>, C<UserRead>,
C<UserList>) are generated I<only> when they differ from the API Base.
Comparison considers both property names and the C<required> array.

A simple source like C<Group> with no contextual rules produces a
single canonical schema used everywhere. A complex source like C<User>
with C<password> having C<create.required =E<gt> 1> and
C<update.required =E<gt> 0> produces C<User>, C<UserCreate>, and
C<UserUpdate>.

=head2 writeOnly handling

Fields marked C<writeOnly> are:

=over

=item * Excluded from the API Base C<required> array

=item * Excluded from the API Base C<properties> hash

=item * Added back into C<create> and C<update> projection properties

=back

This means GET responses never contain writeOnly fields and the
OpenAPI validator does not expect them.

=head2 Config override

Any column property can be overridden via the plugin configuration
without modifying DBIx classes:

  'Fondation::OpenAPI' => {
      backend => 'main',
      schemas => {
          User => {
              columns => {
                  name => {
                      maxLength => 100,       # override DBIx size
                  },
                  password => {
                      writeOnly => 1,
                      create    => { required => 1 },
                      update    => { required => 0 },
                  },
              },
          },
      },
  },

Config keys follow the same flat + contextual structure as
C<extra-E<gt>{openapi}> and take the highest priority in the cascade:

  1. Structure DBIx (implicit)
  2. extra->{openapi} flat keys (Result class)
  3. Config flat keys (myapp.conf)
  4. extra->{openapi} contextual (Result class)
  5. Config contextual (myapp.conf)

=head1 SUBCOMMANDS

=head2 generate

  myapp.pl openapi generate
  myapp.pl openapi generate -y
  myapp.pl openapi generate --output custom.json

Iterates all DBIx sources (monikers), builds the API Base for each,
applies contextual projections, and writes two files:

=over

=item C<share/openapi.json>

OpenAPI 3.0.3 specification with schemas and CRUD paths. Loaded at
runtime by L<Mojolicious::Plugin::OpenAPI> for request validation.

=item C<public/js/validators.js>

Client-side validation (C<FondationValidators.validate()>) consumed
by L<Fondation::Asset> bundles.

=back

Options:

  --output FILE   Output path relative to $app->home (default: share/openapi.json)
  -y              Overwrite without confirmation prompt

=head1 CRUD PATHS

Each source generates five endpoints with C<x-mojo-to> routing and
automatic C<x-auth> permission annotations:

  GET    /{moniker}       -> {Moniker}#list    x-auth: {moniker_lc}_list
  POST   /{moniker}       -> {Moniker}#create  x-auth: {moniker_lc}_create
  GET    /{moniker}/{id}  -> {Moniker}#read    x-auth: {moniker_lc}_read
  PUT    /{moniker}/{id}  -> {Moniker}#update  x-auth: {moniker_lc}_update
  DELETE /{moniker}/{id}  -> {Moniker}#delete  x-auth: {moniker_lc}_delete

The C<x-auth> default can be overridden via the plugin config
(C<schemas.{Source}.x_auth.{operation}>). See L<Mojolicious::Plugin::Fondation::OpenAPI>
for details. Enforcement is handled at runtime by
L<Mojolicious::Plugin::Fondation::OpenAPI::Security>.

=head1 SEE ALSO

L<Mojolicious::Plugin::Fondation::OpenAPI>,
L<Fondation::Model::DBIx::Async>,
L<Mojolicious::Plugin::OpenAPI>

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
