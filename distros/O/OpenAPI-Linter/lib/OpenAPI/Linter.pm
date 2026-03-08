package OpenAPI::Linter;

$OpenAPI::Linter::VERSION          = '0.19';
$OpenAPI::Linter::Async::AUTHORITY = 'cpan:MANWAR';

use strict;
use warnings;

use File::Spec;
use Carp qw(croak);
use JSON::Validator;
use JSON qw(decode_json);
use YAML::XS qw(LoadFile);
use File::Slurp qw(read_file);
use File::ShareDir qw(dist_file);

use OpenAPI::Linter::Location;

=head1 NAME

OpenAPI::Linter - Validate and lint OpenAPI 3.x specification files

=head1 VERSION

Version 0.19

=head1 SYNOPSIS

    use OpenAPI::Linter;

    # Load from a YAML or JSON file
    my $linter = OpenAPI::Linter->new(spec => 'openapi.yaml');

    # Or pass a pre-parsed spec as a hashref
    my $linter = OpenAPI::Linter->new(spec => \%spec_data);

    # Run all checks (schema + semantic)
    my @issues = $linter->find_issues;

    # Run structural/schema checks only
    my @errors = $linter->validate_schema;

    # Filter by severity level
    my @errors_only = $linter->find_issues(level => 'ERROR');

    # Filter by message pattern
    my @security = $linter->find_issues(pattern => qr/security/i);

    # Inspect results
    for my $issue (@issues) {
        my $loc = $issue->{location};

        # Location stringifies to the dot-separated spec path
        printf "[%s] %s (at %s)\n",
            $issue->{level},
            $issue->{message},
            $loc;

        # For file-based specs, precise line/column is also available
        if ($loc->line) {
            printf "    => %s\n", $loc->position;  # e.g. openapi.yaml:42:5
        }
    }

=head1 DESCRIPTION

C<OpenAPI::Linter> validates OpenAPI 3.0.x and 3.1.x specification files
against both the official OpenAPI JSON Schema and a curated set of semantic
and documentation rules.

Checks are organised into two phases:

=over 4

=item 1. B<Structural validation> - the spec is validated against the official
OpenAPI schema published at L<https://spec.openapis.org>. If structural errors
are found, further checks are skipped.

=item 2. B<Semantic checks> - a suite of opinionated rules is applied covering
documentation completeness, naming conventions, security, HTTP method
semantics, unused components, and more.

=back

Results are returned as a list of issue hashrefs; see L</ISSUE STRUCTURE>
for the full field reference.

=head1 CONSTRUCTOR

=head2 new

    my $linter = OpenAPI::Linter->new(%args);

Creates and returns a new linter instance.

=head3 Arguments

=over 4

=item C<spec> (required)

Either a filesystem path to a YAML or JSON OpenAPI file, or a hashref
containing a pre-parsed specification. A path that does not exist causes
a fatal error via C<croak>.

=item C<schema_url> (optional)

Override the OpenAPI meta-schema URL used for structural validation.
By default the correct URL is chosen automatically based on the C<openapi>
version field in the spec:

=over 4

=item * 3.0.x - C<https://spec.openapis.org/oas/3.0/schema/2021-09-28>

=item * 3.1.x - C<https://spec.openapis.org/oas/3.1/schema/2022-10-07>

=back

Overriding this is primarily useful in tests or air-gapped environments.

=back

=head3 Exceptions

C<new> will C<croak> if:

=over 4

=item * The C<spec> argument is not provided.

=item * C<spec> is a string that does not refer to an existing file.

=back

Parse errors (malformed YAML/JSON) and schema-download failures are captured
and reported as C<ERROR>-level issues on the first call to C<find_issues> or
C<validate_schema>, rather than causing a fatal exception.

=cut

sub new {
    my ($class, %args) = @_;

    my $spec_path = $args{spec} or croak "A 'spec' file path or data is required";
    my $spec_data;
    my $file_path_for_display = 'internal_data';
    my $parse_error;

    if (ref($spec_path) eq 'HASH') {
        $spec_data = $spec_path;
    }
    elsif (-e $spec_path) {
        $file_path_for_display = $spec_path;
        eval {
            $spec_data = YAML::XS::LoadFile($spec_path);
        };
        # CATCH PARSE ERRORS HERE
        $parse_error = $@ if $@;
    }
    else {
        croak "Spec path '$spec_path' does not exist";
    }

    # Build a line/column index from the raw file text so we can
    # attach precise locations to every issue we produce.
    my $line_index = {};
    if (!$parse_error && $file_path_for_display ne 'internal_data') {
        $line_index = _build_line_index($spec_path);
    }

    # Create validator
    my $validator = JSON::Validator->new;

    # Add custom format for uri-reference to avoid warnings
    # uri-reference is like uri but allows relative references
    $validator->formats->{'uri-reference'} = sub {
        my $value = shift;
        return undef if !defined $value || $value eq '';

        # Use URI module for proper validation if available
        if (eval { require URI; 1 }) {
            eval {
                my $uri = URI->new($value);
                return undef;  # Valid
            };
            return $@ if $@;  # Invalid, return error
        }

        # Fallback: accept any non-empty string
        return undef;
    };

    my $openapi_version = ($spec_data && $spec_data->{openapi}) || '3.1.0';

    # schema_url arg retained for backwards compatibility / forced network use
    if ( $args{schema_url} ) {
        eval {
            # Set timeouts to avoid hanging on network issues
            # JSON::Validator caches schemas, so this only affects first download
            local $ENV{MOJO_CONNECT_TIMEOUT}    = 10;
            local $ENV{MOJO_INACTIVITY_TIMEOUT} = 10;
            $validator->schema( $args{schema_url} );
        };
        $parse_error = $@ if $@ && !$parse_error;
    }
    else {
        # Load from bundled share/ files — no network required
        my $schema_file =
            $openapi_version =~ /^3\.0\./
                ? 'openapi-3.0.json'
                : 'openapi-3.1.json';

        eval {
            $validator->schema( _load_bundled_schema($schema_file) );
        };
        $parse_error = $@ if $@ && !$parse_error;
    }

    my $self = bless {
        spec_data   => $spec_data,
        validator   => $validator,
        issues      => [],
        file_path   => $file_path_for_display,
        version     => $openapi_version,
        parse_error => $parse_error,
        line_index  => $line_index,
    }, $class;

    return $self;
}

=head1 METHODS

=head2 validate_schema

    my @issues = $linter->validate_schema;
    my $issues = $linter->validate_schema;   # scalar context -> arrayref

Validates the spec against the official OpenAPI JSON Schema and checks the
C<openapi> version field. Returns a (possibly empty) list of issue hashrefs.

In scalar context returns an arrayref.

If a parse error was encountered during construction it is reported here and
no further schema validation is attempted.

=cut

sub validate_schema {
    my ($self) = @_;
    my @issues;

    # Validate OpenAPI version format
    my $openapi_version = $self->{spec_data}{openapi} // '';
    if ($openapi_version && $openapi_version !~ /^\d+\.\d+\.\d+$/) {
        push @issues, {
            level    => 'ERROR',
            message  => "Invalid OpenAPI version format: '$openapi_version'. Expected format: X.Y.Z",
            type     => 'validation',
            location => $self->_make_location('/openapi'),
        };
    }
    elsif ($openapi_version && $openapi_version !~ /^3\.(0|1)\.\d+$/) {
        push @issues, {
            level    => 'ERROR',
            message  => "Unsupported OpenAPI version: '$openapi_version'. Only 3.0.x and 3.1.x are supported",
            type     => 'validation',
            location => $self->_make_location('/openapi'),
        };
    }

    if ($self->{parse_error}) {
        push @issues, {
            level    => 'ERROR',
            message  => "Parsing error: " . $self->{parse_error},
            type     => 'syntax',
            location => $self->_make_location(''),
        };
        return @issues;
    }

    # Validate the spec against OpenAPI schema
    # Suppress "Format rule for 'uri-reference' is missing" warning
    my @errors;
    {
        local $SIG{__WARN__} = sub {
            my $warning = shift;
            # Suppress the uri-reference format warning
            warn $warning unless $warning =~ /Format rule for 'uri-reference' is missing/;
        };
        @errors = $self->{validator}->validate($self->{spec_data});
    }

    foreach my $error (@errors) {
        # Errors are JSON::Validator::Error objects
        my $msg  = $error->message || '';
        my $path = $error->path || 'unknown';

        # Skip empty messages
        next if !$msg || $msg eq '';

        # Build a descriptive message
        my $descriptive_msg = $msg;
        if ($msg eq 'Missing property.') {
            # Extract the property name from the path
            my $property     = $path;
            $property        =~ s{^/}{};
            $property        =~ s{/}{.}g;
            $descriptive_msg = "Missing required property: '$property'";
        }

        push @issues, {
            level    => 'ERROR',
            message  => $descriptive_msg,
            type     => 'schema',
            location => $self->_make_location($path),
        };
    }

    # Sort issues by path to ensure deterministic output
    my @sorted_issues = sort { "$a->{location}" cmp "$b->{location}" } @issues;

    return wantarray ? @sorted_issues : \@sorted_issues;
}

=head2 find_issues

    my @issues = $linter->find_issues(%args);
    my $issues = $linter->find_issues(%args);   # scalar context -> arrayref

Runs the full linting pipeline: structural validation first, then all
semantic checks. If structural errors are found the semantic checks are
skipped and only those errors are returned (after any filtering).

In scalar context returns an arrayref.

B<Optional arguments>

=over 4

=item C<level>

Return only issues whose C<level> field exactly matches the given string.
Valid values are C<ERROR>, C<WARN>, and C<INFO>.

=item C<pattern>

A compiled or uncompiled regular expression. Only issues whose C<message>
field matches the pattern are returned.

=back

Both filters may be combined; an issue must satisfy both to be included.

=cut

sub find_issues {
    my ($self, %args) = @_;
    my @issues;

    my $filter_level   = $args{level};
    my $filter_pattern = $args{pattern};

    if ($ENV{DEBUG}) {
        warn ">>> FIND_ISSUES IS RUNNING (UPDATED " . localtime()   . ")\n";
        warn ">>>   Filter level: " . ($filter_level // 'none')     . "\n";
        warn ">>>   Filter pattern: " . ($filter_pattern // 'none') . "\n";
    }

    # 1. ALWAYS run structural validation first (syntax + schema)
    push @issues, $self->validate_schema;

    if (@issues) {
        warn ">>> Stopping due to structural validation errors\n"
            if $ENV{DEBUG};
        return $self->_apply_filters(\@issues, $filter_level, $filter_pattern);
    }

    # 2. Custom semantic checks
    my $spec = $self->{spec_data};

    # Run all semantic checks
    push @issues, $self->_check_info_section($spec);
    push @issues, $self->_check_operations($spec);
    push @issues, $self->_check_security($spec);
    push @issues, $self->_check_server_variables($spec);
    push @issues, $self->_check_components_schemas($spec);
    push @issues, $self->_check_components_parameters($spec);
    push @issues, $self->_check_components_responses($spec);
    push @issues, $self->_check_components_request_bodies($spec);
    push @issues, $self->_check_unused_components($spec);
    push @issues, $self->_check_path_naming($spec);
    push @issues, $self->_check_duplicate_descriptions($spec);

    warn ">>> find_issues complete. Total issues: " . scalar(@issues) . "\n"
        if $ENV{DEBUG};

    return $self->_apply_filters(\@issues, $filter_level, $filter_pattern);
}

=head1 ISSUE STRUCTURE

Each issue is a plain hashref with the following keys:

=over 4

=item C<level>

Severity of the issue. One of:

=over 4

=item * C<ERROR> - the spec is invalid or will cause interoperability failures.

=item * C<WARN> - a best-practice violation; the spec may still be functional.

=item * C<INFO> - informational; e.g. duplicate descriptions.

=back

=item C<message>

A human-readable description of the problem.

=item C<path>

A dot-separated or C<#/>-prefixed location within the spec indicating where
the issue was found. May be absent for top-level parse errors.

=item C<type>

A machine-readable category string. Common values:

    documentation   Missing description, summary, example, or licence.
    semantic        HTTP method misuse, missing operationId, etc.
    schema          Violation of the OpenAPI JSON Schema.
    syntax          YAML/JSON parse failure.
    security        Missing or incomplete security definitions.
    naming          Path segment or property naming convention violations.
    validation      Server variable, version format, or other validation.
    maintainability Unused components, duplicate descriptions, etc.

=item C<rule> (optional)

A short rule identifier, present on selected checks (e.g.
C<info-description>, C<security-defined>, C<no-undefined-server-variable>).

=back

=head1 CHECKS PERFORMED

=head2 Structural

=over 4

=item * C<openapi> version field format must be C<X.Y.Z>.

=item * C<openapi> version must be C<3.0.x> or C<3.1.x>.

=item * Full validation against the official OpenAPI JSON Schema.

=back

=head2 Info section

=over 4

=item * C<info.description> is present.

=item * C<info.license> is present.

=back

=head2 Operations (paths)

=over 4

=item * Every operation has a C<description>, C<summary>, and C<operationId>.

=item * C<GET> and C<DELETE> operations do not include a C<requestBody>.

=item * C<requestBody> has a C<description>.

=item * Non-path parameters have a C<description>.

=item * Path parameters declare C<required: true>.

=item * Every operation has at least one 2xx response.

=item * Every response object has a C<description>.

=item * Response schemas that include content have a C<type> or C<$ref>.

=item * C<POST> operations should return C<201 Created>.

=item * C<204 No Content> responses must not include a body.

=item * C<GET> operations should not return C<201>.

=back

=head2 Security

Checked only when the spec defines C<components.securitySchemes>.

=over 4

=item * A root-level C<security> field is present.

=item * Each operation either has its own C<security> field or inherits one
from the root.

=back

=head2 Servers

=over 4

=item * Every C<{variable}> placeholder in a server URL is declared in
C<servers[n].variables>.

=item * A server URL that consists entirely of a single bare placeholder
(e.g. C<"{siteUrl}">), with no variables block, is downgraded to C<WARN>
rather than C<ERROR>. This pattern is common in published specs to indicate
that the consumer must supply the base URL. It is still reported so the
spec author is aware, but it is not treated as a hard error. Any other URL
that mixes literal text with an undefined variable (e.g.
C<"https://{host}/api">) remains an C<ERROR>.

=back

=head2 Components

=over 4

=item * Every schema in C<components.schemas> has a C<description>, C<type>,
and (for object schemas) an C<example> or C<examples>.

=item * Every schema property has a C<description> and uses camelCase naming.

=item * Every entry in C<components.parameters> has a C<description>.

=item * Every entry in C<components.responses> has a C<description>.

=item * Every entry in C<components.requestBodies> has a C<description>.

=item * Schemas, responses, and request bodies defined in C<components> but
never referenced via C<$ref> are reported as unused.

=back

=head2 Path naming

=over 4

=item * Static path segments must be kebab-case
(C<[a-z][a-z0-9]*(-[a-z][a-z0-9]*)*>).

=back

=head2 Duplicate descriptions

=over 4

=item * Identical descriptions across multiple component schemas are flagged
at C<INFO> level.

=back

=head1 ENVIRONMENT

=over 4

=item C<DEBUG>

Set to a true value to emit verbose diagnostic output to C<STDERR> tracing
the linter's internal execution.

    DEBUG=1 perl myscript.pl

=item C<MOJO_CONNECT_TIMEOUT> / C<MOJO_INACTIVITY_TIMEOUT>

Temporarily set to C<10> seconds during schema download to prevent indefinite
hangs on network failures.

=back

=head1 DEPENDENCIES

=over 4

=item L<JSON::Validator>

=item L<JSON>

=item L<YAML::XS>

=item L<File::Slurp>

=item L<URI> (optional - used for stricter C<uri-reference> format validation
when available)

=back

=head1 DIAGNOSTICS

=over 4

=item C<A 'spec' file path or data is required>

You called C<new> without supplying the C<spec> argument.

=item C<Spec path '%s' does not exist>

The string passed as C<spec> is not a path to an existing file.

=item C<Parsing error: ...>

The file could not be parsed as YAML or JSON. The underlying error from
L<YAML::XS> is included in the message.

=back

=head1 BUGS AND LIMITATIONS

=over 4

=item * C<$ref> resolution is shallow: only direct C<$ref> usage in operation
C<requestBody>, C<responses>, C<parameters>, and response C<content> schemas
is tracked for the unused-components check. Nested or recursive C<$ref>
usage is not followed.

=item * The unused-components check for C<components.parameters> only reports
a parameter named C<fragment> (for Redocly toolchain compatibility). All
other unused parameters are silently ignored.

=item * Examples, headers, links, and callbacks inside C<components> are not
checked.

=item * The schema is downloaded from C<spec.openapis.org> on first use and
cached by L<JSON::Validator>. Subsequent instantiations reuse the cache.
In environments without internet access, pass a local C<schema_url>.

=back

=cut

#
#
# Filtering Helper

sub _apply_filters {
    my ($self, $issues_ref, $filter_level, $filter_pattern) = @_;
    my @issues = @$issues_ref;

    if ($filter_level || $filter_pattern) {
        my @filtered;
        foreach my $issue (@issues) {
            next if $filter_level   && $issue->{level} ne $filter_level;
            next if $filter_pattern && $issue->{message} !~ $filter_pattern;
            push @filtered, $issue;
        }
        @issues = @filtered;
    }

    return wantarray ? @issues : \@issues;
}

#
#
# Info Section Checks

sub _check_info_section {
    my ($self, $spec) = @_;
    my @issues;

    warn ">>> CHECKING INFO SECTION\n" if $ENV{DEBUG};

    if ($spec->{info}) {
        # Check for info.description
        unless ($spec->{info}{description}) {
            push @issues, {
                level    => 'WARN',
                rule     => 'info-description',
                message  => "API info is missing description",
                location => $self->_make_location("info.description"),
                type     => 'documentation',
            };
            warn ">>>   ⚠ Added WARN: missing info.description\n"
                if $ENV{DEBUG};
        }

        # Check for info.license
        unless ($spec->{info}{license}) {
            push @issues, {
                level    => 'WARN',
                rule     => 'info-license',
                message  => "API info is missing license",
                location => $self->_make_location("info.license"),
                type     => 'documentation',
            };
            warn ">>>   ⚠ Added WARN: missing info.license\n"
                if $ENV{DEBUG};
        }
    }

    return @issues;
}

#
#
# Operations Checks

sub _check_operations {
    my ($self, $spec) = @_;
    my @issues;

    return @issues unless $spec->{paths};

    warn ">>> Found paths section\n" if $ENV{DEBUG};

    foreach my $path (sort keys %{$spec->{paths}}) {
        foreach my $method (sort keys %{$spec->{paths}{$path}}) {
            next if $method =~ /^x-/;
            next if $method eq 'parameters';

            my $op = $spec->{paths}{$path}{$method};
            next unless ref($op) eq 'HASH';

            if ($ENV{DEBUG}) {
                warn ">>> PROCESSING OPERATION: $method $path\n";
                warn ">>>   Operation keys: " . join(', ', keys %$op) . "\n";
            }

            push @issues, $self->_check_operation_description($path, $method, $op);
            push @issues, $self->_check_operation_summary($path, $method, $op);
            push @issues, $self->_check_operation_id($path, $method, $op);
            push @issues, $self->_check_request_body_method($path, $method, $op);
            push @issues, $self->_check_operation_parameters($path, $method, $op);
            push @issues, $self->_check_request_body_description($path, $method, $op);
            push @issues, $self->_check_success_responses($path, $method, $op);
            push @issues, $self->_check_response_descriptions($path, $method, $op);
            push @issues, $self->_check_post_201_rule($path, $method, $op);
            push @issues, $self->_check_204_content_rule($path, $method, $op);
            push @issues, $self->_check_get_201_rule($path, $method, $op);

            if ($ENV{DEBUG}) {
                warn ">>>   Finished processing $method $path\n";
                warn ">>>   ---\n";
            }
        }
    }

    return @issues;
}

sub _check_operation_description {
    my ($self, $path, $method, $op) = @_;
    my @issues;

    unless ($op->{description}) {
        push @issues, {
            level    => 'WARN',
            message  => "Operation $method $path is missing a description",
            location => $self->_make_location("paths.$path.$method"),
            type     => 'semantic',
        };
        warn ">>>   ⚠ Added WARN: missing description\n"
            if $ENV{DEBUG};
    }

    return @issues;
}

sub _check_operation_summary {
    my ($self, $path, $method, $op) = @_;
    my @issues;

    if (exists $op->{summary}) {
        if (defined $op->{summary} && $op->{summary} =~ /^\s*$/) {
            push @issues, {
                level    => 'WARN',
                message  => "Operation $method $path has empty summary",
                location => $self->_make_location("paths.$path.$method.summary"),
                type     => 'documentation',
            };
            warn ">>>   ⚠ Added WARN: empty summary\n"
                if $ENV{DEBUG};
        }
    } else {
        push @issues, {
            level    => 'WARN',
            message  => "Operation $method $path is missing a summary",
            location => $self->_make_location("paths.$path.$method"),
            type     => 'documentation',
        };
        warn ">>>   ⚠ Added WARN: missing summary\n"
            if $ENV{DEBUG};
    }

    return @issues;
}

sub _check_operation_id {
    my ($self, $path, $method, $op) = @_;
    my @issues;

    unless ($op->{operationId}) {
        push @issues, {
            level    => 'WARN',
            message  => "Operation $method $path is missing operationId",
            location => $self->_make_location("paths.$path.$method"),
            type     => 'semantic',
        };
        warn ">>>   ⚠ Added WARN: missing operationId\n"
            if $ENV{DEBUG};
    }

    return @issues;
}

sub _check_request_body_method {
    my ($self, $path, $method, $op) = @_;
    my @issues;

    if ($method =~ /^(get|delete)$/ && $op->{requestBody}) {
        push @issues, {
            level    => 'WARN',
            message  => "Operation $method $path should not have requestBody",
            location => $self->_make_location("paths.$path.$method.requestBody"),
            type     => 'semantic',
        };
        warn ">>>   ⚠ Added WARN: should not have requestBody\n"
            if $ENV{DEBUG};
    }

    return @issues;
}

sub _check_operation_parameters {
    my ($self, $path, $method, $op) = @_;
    my @issues;

    return @issues unless $op->{parameters};

    warn ">>>   Has " . scalar(@{$op->{parameters}}) . " parameters\n"
        if $ENV{DEBUG};

    for my $i (0 .. $#{$op->{parameters}}) {
        my $param = $op->{parameters}[$i];
        next if $param->{'$ref'};

        # Path parameter must be required
        if ($param->{in} && $param->{in} eq 'path') {
            if (exists $param->{required} && !$param->{required}) {
                push @issues, {
                    level    => 'ERROR',
                    message  => "Path parameter " . $param->{name}
                                . " must be required",
                    location => $self->_make_location("paths.$path.$method.parameters[$i]"),
                    type     => 'semantic',
                };
                warn ">>>   ❌ Added ERROR: path parameter must be required\n"
                    if $ENV{DEBUG};
            }
        }

        # Check parameter description for non-path parameters
        if ($param->{in} && $param->{in} ne 'path' && !$param->{description}) {
            push @issues, {
                level    => 'WARN',
                message  => "Parameter '" . $param->{name}
                            . "' is missing description",
                location => $self->_make_location("paths.$path.$method.parameters[$i]"),
                type     => 'documentation',
            };
            warn ">>>   ⚠ Added WARN: parameter missing description\n"
                if $ENV{DEBUG};
        }
    }

    return @issues;
}

sub _check_request_body_description {
    my ($self, $path, $method, $op) = @_;
    my @issues;

    if ($op->{requestBody} && ref($op->{requestBody}) eq 'HASH') {
        unless ($op->{requestBody}{description}) {
            push @issues, {
                level    => 'WARN',
                message  => "Request body in $method $path is missing description",
                location => $self->_make_location("paths.$path.$method.requestBody"),
                type     => 'documentation',
            };
            warn ">>>   ⚠ Added WARN: request body missing description\n"
                if $ENV{DEBUG};
        }
    }

    return @issues;
}

sub _check_success_responses {
    my ($self, $path, $method, $op) = @_;
    my @issues;

    warn ">>>   CHECKING success response for $method $path\n"
        if $ENV{DEBUG};

    my ($has_success, $has_200, $has_201, $has_204) = $self->_analyze_responses($op);

    unless ($has_success) {
        push @issues, {
            level    => 'ERROR',
            message  => "Operation $method $path missing success response (2xx)",
            location => $self->_make_location("paths.$path.$method"),
            type     => 'semantic',
        };
        warn ">>>   ❌ ADDED ERROR for missing success response\n"
            if $ENV{DEBUG};
    }

    # Store response analysis in operation for other checks
    $op->{_response_analysis} = {
        has_success => $has_success,
        has_200     => $has_200,
        has_201     => $has_201,
        has_204     => $has_204,
    };

    return @issues;
}

sub _analyze_responses {
    my ($self, $op) = @_;

    my $has_success = 0;
    my $has_200     = 0;
    my $has_201     = 0;
    my $has_204     = 0;

    if (exists $op->{responses}) {
        warn ">>>   ✓ Has 'responses' key\n" if $ENV{DEBUG};

        if (ref($op->{responses}) eq 'HASH') {
            my @status_codes = keys %{$op->{responses}};
            warn ">>>   Status codes: " . (join ', ', @status_codes) . "\n"
                if $ENV{DEBUG};

            foreach my $status (@status_codes) {
                if ($status =~ /^2\d\d$|^2xx$|^success$|^default$/i) {
                    $has_success = 1;
                    $has_200     = 1 if $status eq '200';
                    $has_201     = 1 if $status eq '201';
                    $has_204     = 1 if $status eq '204';
                    warn ">>>   ✓ Found success response: $status\n"
                        if $ENV{DEBUG};
                }
            }
        } else {
            warn ">>>   ⚠ WARNING: responses is not a HASH, it's a "
                 . ref($op->{responses}) . "\n"
                if $ENV{DEBUG};
        }
    } else {
        warn ">>>   ❌ NO 'responses' key at all!\n" if $ENV{DEBUG};
    }

    return ($has_success, $has_200, $has_201, $has_204);
}

sub _check_response_descriptions {
    my ($self, $path, $method, $op) = @_;
    my @issues;

    return @issues unless ($op->{responses}
                           && ref($op->{responses}) eq 'HASH');

    foreach my $status (keys %{$op->{responses}}) {
        my $response = $op->{responses}{$status};
        next unless ref($response) eq 'HASH';

        unless ($response->{description}) {
            push @issues, {
                level    => 'WARN',
                message  => "Response $status in $method $path is missing description",
                location => $self->_make_location("paths.$path.$method.responses.$status"),
                type     => 'documentation',
            };
            warn ">>>   ⚠ Added WARN: response $status missing description\n"
                if $ENV{DEBUG};
        }

        push @issues, $self->_check_response_schema($path, $method, $status, $response);
    }

    return @issues;
}

sub _check_response_schema {
    my ($self, $path, $method, $status, $response) = @_;
    my @issues;

    return @issues unless $response->{content};

    foreach my $content_type (keys %{$response->{content}}) {
        my $media = $response->{content}{$content_type};
        next unless $media->{schema};

        if (!exists $media->{schema}{type} && !$media->{schema}{'$ref'}) {
            push @issues, {
                level    => 'WARN',
                message  => "Response $status in $method $path has content type $content_type but schema missing type",
                location => $self->_make_location("paths.$path.$method.responses.$status.content.$content_type.schema"),
                type     => 'semantic',
            };
            warn ">>>   ⚠ Added WARN: response schema missing type\n"
                if $ENV{DEBUG};
        }
    }

    return @issues;
}

sub _check_post_201_rule {
    my ($self, $path, $method, $op) = @_;
    my @issues;

    my $analysis    = $op->{_response_analysis} || {};
    my $has_success = $analysis->{has_success};
    my $has_201     = $analysis->{has_201};

    if ($method eq 'post' && $has_success && !$has_201) {
        push @issues, {
            level    => 'WARN',
            message  => "POST operation $method $path should return 201 Created (got 200)",
            location => $self->_make_location("paths.$path.$method.responses"),
            type     => 'semantic',
        };
        warn ">>>   ⚠ Added WARN: POST should return 201 Created\n"
            if $ENV{DEBUG};
    }

    return @issues;
}

sub _check_204_content_rule {
    my ($self, $path, $method, $op) = @_;
    my @issues;

    my $analysis = $op->{_response_analysis} || {};
    my $has_204  = $analysis->{has_204};

    if ($has_204 && $op->{responses}{204}{content}) {
        push @issues, {
            level    => 'WARN',
            message  => "204 No Content response should not have content body",
            location => $self->_make_location("paths.$path.$method.responses.204.content"),
            type     => 'semantic',
        };
        warn ">>>   ⚠ Added WARN: 204 response has content\n"
            if $ENV{DEBUG};
    }

    return @issues;
}

sub _check_get_201_rule {
    my ($self, $path, $method, $op) = @_;
    my @issues;

    my $analysis = $op->{_response_analysis} || {};
    my $has_201  = $analysis->{has_201};

    if ($method eq 'get' && $has_201) {
        push @issues, {
            level    => 'WARN',
            message  => "GET operation $method $path should return 200 OK (not 201)",
            location => $self->_make_location("paths.$path.$method.responses.201"),
            type     => 'semantic',
        };
        warn ">>>   ⚠ Added WARN: GET should not return 201\n"
            if $ENV{DEBUG};
    }

    return @issues;
}

#
#
# Security Checks

sub _check_security {
    my ($self, $spec) = @_;
    my @issues;

    # Only check security if spec has security schemes defined
    return @issues unless $spec->{components}
                          && $spec->{components}{securitySchemes};

    warn ">>> CHECKING SECURITY RULES\n"
        if $ENV{DEBUG};

    # Check root level security
    unless ($spec->{security}) {
        warn ">>>   Root security missing - adding ERROR\n" if $ENV{DEBUG};
        push @issues, {
            level    => 'ERROR',
            rule     => 'security-defined',
            message  => "API root level missing security definition",
            location => $self->_make_location("#/security"),
            type     => 'security',
        };
    }

    # Check each operation for security
    push @issues, $self->_check_operation_security($spec);

    return @issues;
}

sub _check_operation_security {
    my ($self, $spec) = @_;
    my @issues;

    return @issues unless $spec->{paths};
    return @issues unless $spec->{components}
                          && $spec->{components}{securitySchemes};

    warn ">>>   Checking operation security\n"
        if $ENV{DEBUG};

    foreach my $path (keys %{$spec->{paths}}) {
        foreach my $method (keys %{$spec->{paths}{$path}}) {
            next if $method =~ /^x-|^parameters$/;
            my $op = $spec->{paths}{$path}{$method};
            next unless ref($op) eq 'HASH';

            unless ($op->{security} || $spec->{security}) {
                warn ">>>   ❌ Operation $method $path missing security\n" if $ENV{DEBUG};
                push @issues, {
                    level    => 'ERROR',
                    rule     => 'security-defined',
                    message  => "Operation $method $path missing security definition",
                    location => $self->_make_location("paths.$path.$method.security"),
                    type     => 'security',
                };
            }
        }
    }

    return @issues;
}

sub _check_server_variables {
    my ($self, $spec) = @_;
    my @issues;

    return @issues unless $spec->{servers};

    warn ">>>   Checking server variables\n"
        if $ENV{DEBUG};

    foreach my $server_idx (0 .. $#{$spec->{servers}}) {
        my $server = $spec->{servers}[$server_idx];
        next unless $server->{url};

        while ($server->{url} =~ /\{([^}]+)\}/g) {
            my $var = $1;

            unless ($server->{variables} && exists $server->{variables}{$var}) {

                # A URL that is entirely a single variable placeholder (e.g.
                # "{siteUrl}") is a common real-world pattern used to indicate
                # that the base URL must be supplied by the consumer. It is
                # technically invalid OpenAPI but widely accepted in published
                # specs. We downgrade this specific case to WARN rather than
                # ERROR, and still report it so the spec author is aware.

                my $is_bare_placeholder =
                    $server->{url} =~ /^\{[^}]+\}$/ ? 1 : 0;

                my ($level, $message, $hint) =
                    !$server->{variables}
                    ? (
                        $is_bare_placeholder ? 'WARN' : 'ERROR',
                        $is_bare_placeholder
                            ? "Server URL is a bare placeholder '{$var}' with no variables block — consumer must supply the base URL"
                            : "Server URL contains variable '{$var}' but no variables block is defined",
                        "Add a 'variables' block, e.g.: variables:\n    $var:\n      default: 'your-value'",
                    )
                    : (
                        'ERROR',
                        "Server variable '{$var}' is used in the URL but not defined in the variables block",
                        undef,
                    );

                warn ">>>   $level: $message\n" if $ENV{DEBUG};
                push @issues, {
                    level    => $level,
                    rule     => 'no-undefined-server-variable',
                    message  => $message,
                    hint     => $hint,
                    type     => 'validation',
                    location => $self->_make_location("servers.$server_idx.url"),
                };
            }
        }
    }

    return @issues;
}

#
#
# Components Checks

sub _check_components_schemas {
    my ($self, $spec) = @_;
    my @issues;

    return @issues unless ($spec->{components}
                           && $spec->{components}{schemas});

    warn ">>> Found components.schemas section\n"
        if $ENV{DEBUG};

    foreach my $schema_name (sort keys %{$spec->{components}{schemas}}) {
        my $schema = $spec->{components}{schemas}{$schema_name};

        push @issues, $self->_check_schema_description($schema_name, $schema);
        push @issues, $self->_check_schema_type($schema_name, $schema);
        push @issues, $self->_check_schema_example($schema_name, $schema);
        push @issues, $self->_check_schema_properties($schema_name, $schema);
        push @issues, $self->_check_schema_array_items($schema_name, $schema, '');
    }

    return @issues;
}

sub _check_schema_description {
    my ($self, $schema_name, $schema) = @_;
    my @issues;

    unless ($schema->{description}) {
        push @issues, {
            level    => 'WARN',
            message  => "Schema '$schema_name' is missing description",
            location => $self->_make_location("components.schemas.$schema_name"),
            type     => 'documentation',
        };
    }

    return @issues;
}

sub _check_schema_type {
    my ($self, $schema_name, $schema) = @_;
    my @issues;

    unless ($schema->{type}) {
        push @issues, {
            level    => 'WARN',
            message  => "Schema '$schema_name' is missing type",
            location => $self->_make_location("components.schemas.$schema_name.type"),
            type     => 'semantic',
        };
        warn ">>>   ⚠ Added WARN: schema missing type\n"
            if $ENV{DEBUG};
    }

    return @issues;
}

sub _check_schema_example {
    my ($self, $schema_name, $schema) = @_;
    my @issues;

    if ($schema->{type} && $schema->{type} eq 'object') {
        unless ($schema->{example} || $schema->{examples}) {
            push @issues, {
                level    => 'WARN',
                message  => "Schema '$schema_name' is missing example",
                location => $self->_make_location("components.schemas.$schema_name"),
                type     => 'documentation',
            };
        }
    }

    return @issues;
}

sub _check_schema_properties {
    my ($self, $schema_name, $schema) = @_;
    my @issues;

    return @issues unless $schema->{properties};

    foreach my $prop (sort keys %{$schema->{properties}}) {
        my $prop_schema = $schema->{properties}{$prop};
        push @issues, $self->_check_property_naming($schema_name, $prop);
        push @issues, $self->_check_property_description($schema_name, $prop, $prop_schema);
    }

    return @issues;
}

sub _check_property_naming {
    my ($self, $schema_name, $prop) = @_;
    my @issues;

    if ($prop !~ /^[a-z][a-zA-Z0-9]+$/) {
        push @issues, {
            level    => 'WARN',
            message  => "Property '$prop' should be camelCase",
            location => $self->_make_location("components.schemas.$schema_name.properties.$prop"),
            type     => 'naming',
        };
    }

    return @issues;
}

sub _check_property_description {
    my ($self, $schema_name, $prop, $prop_schema) = @_;
    my @issues;

    unless ($prop_schema->{description}) {
        push @issues, {
            level    => 'WARN',
            message  => "Property '$prop' is missing description",
            location => $self->_make_location("components.schemas.$schema_name.properties.$prop"),
            type     => 'documentation',
        };
        warn ">>>   ⚠ Added WARN: property $prop missing description\n"
            if $ENV{DEBUG};
    }

    return @issues;
}

# Recursively walk a schema and report any sub-schema that declares
# type:array without a corresponding items keyword.
#
# OpenAPI 3.0.x requires items when type is array (inherited from
# JSON Schema draft-07).  OpenAPI 3.1.x technically allows omitting
# items but it is almost always a mistake in practice.
#
# $path is the dot-separated path suffix built up during recursion,
# e.g. "properties.metadata.properties.fields".

sub _check_schema_array_items {
    my ($self, $schema_name, $schema, $path) = @_;
    my @issues;

    return @issues unless ref($schema) eq 'HASH';

    # Check this node
    if (($schema->{type} // '') eq 'array' && !exists $schema->{items}) {
        my $full_path = "components.schemas.$schema_name"
                      . ($path ? ".$path" : '');
        push @issues, {
            level    => 'ERROR',
            rule     => 'array-items-required',
            message  => "Schema '$schema_name'"
                      . ($path ? " property '$path'" : '')
                      . " has type 'array' but is missing required 'items' keyword",
            type     => 'schema',
            location => $self->_make_location($full_path),
        };
        warn ">>>   ERROR: array schema missing items at $full_path\n"
            if $ENV{DEBUG};
    }

    # Recurse into properties
    if (ref($schema->{properties}) eq 'HASH') {
        foreach my $prop (sort keys %{$schema->{properties}}) {
            my $sub_path = $path ? "$path.properties.$prop" : "properties.$prop";
            push @issues, $self->_check_schema_array_items(
                $schema_name, $schema->{properties}{$prop}, $sub_path
            );
        }
    }

    # Recurse into items itself (arrays of arrays)
    if (ref($schema->{items}) eq 'HASH') {
        my $sub_path = $path ? "$path.items" : 'items';
        push @issues, $self->_check_schema_array_items(
            $schema_name, $schema->{items}, $sub_path
        );
    }

    # Recurse into allOf / anyOf / oneOf
    for my $keyword (qw(allOf anyOf oneOf)) {
        next unless ref($schema->{$keyword}) eq 'ARRAY';
        for my $i (0 .. $#{$schema->{$keyword}}) {
            my $sub_path = $path ? "$path.$keyword.$i" : "$keyword.$i";
            push @issues, $self->_check_schema_array_items(
                $schema_name, $schema->{$keyword}[$i], $sub_path
            );
        }
    }

    return @issues;
}

sub _check_components_parameters {
    my ($self, $spec) = @_;
    my @issues;

    return @issues unless ($spec->{components}
                           && $spec->{components}{parameters});

    warn ">>> Found components.parameters section\n"
        if $ENV{DEBUG};

    foreach my $param_name (sort keys %{$spec->{components}{parameters}}) {
        my $param = $spec->{components}{parameters}{$param_name};
        unless ($param->{description}) {
            push @issues, {
                level    => 'WARN',
                message  => "Parameter '$param_name' is missing description",
                location => $self->_make_location("components.parameters.$param_name"),
                type     => 'documentation',
            };
        }
    }

    return @issues;
}

sub _check_components_responses {
    my ($self, $spec) = @_;
    my @issues;

    return @issues unless ($spec->{components}
                           && $spec->{components}{responses});

    warn ">>> Found components.responses section\n"
        if $ENV{DEBUG};

    foreach my $resp_name (sort keys %{$spec->{components}{responses}}) {
        my $response = $spec->{components}{responses}{$resp_name};
        unless ($response->{description}) {
            push @issues, {
                level    => 'WARN',
                message  => "Response '$resp_name' is missing description",
                location => $self->_make_location("components.responses.$resp_name"),
                type     => 'documentation',
            };
        }
    }

    return @issues;
}

sub _check_components_request_bodies {
    my ($self, $spec) = @_;
    my @issues;

    return @issues unless ($spec->{components}
                           && $spec->{components}{requestBodies});

    warn ">>> Found components.requestBodies section\n"
        if $ENV{DEBUG};

    foreach my $req_name (sort keys %{$spec->{components}{requestBodies}}) {
        my $request = $spec->{components}{requestBodies}{$req_name};
        unless ($request->{description}) {
            push @issues, {
                level    => 'WARN',
                message  => "Request body '$req_name' is missing description",
                location => $self->_make_location("components.requestBodies.$req_name"),
                type     => 'documentation',
            };
        }
    }

    return @issues;
}

#
#
# Unused Components Check

sub _check_unused_components {
    my ($self, $spec) = @_;
    my @issues;

    warn ">>> Checking for unused components\n"
        if $ENV{DEBUG};

    my %used_components = $self->_find_used_components($spec);

    return @issues unless $spec->{components};

    # Schemas - always report
    if ($spec->{components}{schemas}) {
        foreach my $name (sort keys %{$spec->{components}{schemas}}) {
            my $ref = "#/components/schemas/$name";
            unless ($used_components{$ref}) {
                push @issues, {
                    level    => 'WARN',
                    message  => "Component '$name' is defined but never used",
                    location => $self->_make_location("components.schemas.$name"),
                    type     => 'maintainability',
                };
            }
        }
    }

    # Responses - always report
    if ($spec->{components}{responses}) {
        foreach my $name (sort keys %{$spec->{components}{responses}}) {
            my $ref = "#/components/responses/$name";
            unless ($used_components{$ref}) {
                push @issues, {
                    level    => 'WARN',
                    message  => "Component '$name' is defined but never used",
                    location => $self->_make_location("components.responses.$name"),
                    type     => 'maintainability',
                };
            }
        }
    }

    # RequestBodies - always report
    if ($spec->{components}{requestBodies}) {
        foreach my $name (sort keys %{$spec->{components}{requestBodies}}) {
            my $ref = "#/components/requestBodies/$name";
            unless ($used_components{$ref}) {
                push @issues, {
                    level    => 'WARN',
                    message  => "Component '$name' is defined but never used",
                    location => $self->_make_location("components.requestBodies.$name"),
                    type     => 'maintainability',
                };
            }
        }
    }

    # Parameters - only report 'fragment' (Redocly compatibility)
    if ($spec->{components}{parameters}) {
        foreach my $name (sort keys %{$spec->{components}{parameters}}) {
            if ($name eq 'fragment') {
                my $ref = "#/components/parameters/$name";
                unless ($used_components{$ref}) {
                    push @issues, {
                        level    => 'WARN',
                        message  => "Component '$name' is defined but never used",
                        location => $self->_make_location("components.parameters.$name"),
                        type     => 'maintainability',
                    };
                }
            }
        }
    }

    # EXAMPLES, HEADERS, LINKS, CALLBACKS - IGNORED

    return @issues;
}

sub _find_used_components {
    my ($self, $spec) = @_;
    my %used_components;

    return %used_components unless $spec->{paths};

    foreach my $path (keys %{$spec->{paths}}) {
        foreach my $method (sort keys %{$spec->{paths}{$path}}) {
            next if $method =~ /^x-/;
            next if $method eq 'parameters';

            my $op = $spec->{paths}{$path}{$method};
            next unless ref($op) eq 'HASH';
            next unless $method =~ /^(get|put|post|delete|options|head|patch|trace)$/i;

            # Check requestBody refs
            if ($op->{requestBody} && $op->{requestBody}{'$ref'}) {
                $used_components{$op->{requestBody}{'$ref'}} = 1;
            }

            # Check response refs
            if ($op->{responses} && ref($op->{responses}) eq 'HASH') {
                foreach my $status (keys %{$op->{responses}}) {
                    my $response = $op->{responses}{$status};
                    if ($response->{'$ref'}) {
                        $used_components{$response->{'$ref'}} = 1;
                    }
                    if ($response->{content}) {
                        foreach my $ct (keys %{$response->{content}}) {
                            my $media = $response->{content}{$ct};
                            if ($media->{schema} && $media->{schema}{'$ref'}) {
                                $used_components{$media->{schema}{'$ref'}} = 1;
                            }
                        }
                    }
                }
            }

            # Check parameter refs
            if ($op->{parameters}) {
                foreach my $param (@{$op->{parameters}}) {
                    if ($param->{'$ref'}) {
                        $used_components{$param->{'$ref'}} = 1;
                    }
                }
            }
        }
    }

    return %used_components;
}

#
#
# Path Naming Convention Checks

sub _check_path_naming {
    my ($self, $spec) = @_;
    my @issues;

    return @issues unless $spec->{paths};

    warn ">>> Checking path naming conventions\n"
        if $ENV{DEBUG};

    foreach my $path (sort keys %{$spec->{paths}}) {
        my @segments = split '/', $path;
        foreach my $segment (@segments) {
            next if $segment =~ /^\{.*\}$/;
            next if $segment eq '';
            if ($segment !~ /^[a-z][a-z0-9]*(?:-[a-z][a-z0-9]*)*$/) {
                push @issues, {
                    level    => 'WARN',
                    message  => "Path segment '$segment' should be kebab-case",
                    location => $self->_make_location("paths.$path"),
                    type     => 'naming',
                };
            }
        }
    }

    return @issues;
}

#
#
# Duplicate Descriptions Check

sub _check_duplicate_descriptions {
    my ($self, $spec) = @_;
    my @issues;

    warn ">>> Checking for duplicate descriptions\n"
        if $ENV{DEBUG};

    my %descriptions;
    if ($spec->{components} && $spec->{components}{schemas}) {
        foreach my $schema_name (sort keys %{$spec->{components}{schemas}}) {
            my $schema = $spec->{components}{schemas}{$schema_name};
            if ($schema->{description}) {
                my $desc = $schema->{description};
                $desc    =~ s/\s+/ /g;
                $desc    =~ s/^\s+|\s+$//g;
                push @{$descriptions{$desc}},
                    "components.schemas.$schema_name";
            }
        }
    }

    foreach my $desc (sort keys %descriptions) {
        my @locations = @{$descriptions{$desc}};
        if (@locations > 1) {
            push @issues, {
                level    => 'INFO',
                message  => "Duplicate description found in "
                            . join(', ', @locations),
                location => $self->_make_location($locations[0]),
                type     => 'maintainability',
            };
            warn ">>> Added INFO: duplicate description ("
                 . scalar(@locations) . " occurrences)\n"
                 if $ENV{DEBUG};
        }
    }

    return @issues;
}

# Locate a bundled schema file.
# Resolution order:
#   1. $ENV{OPENAPI_LINTER_SCHEMA_DIR}  — CI / offline override
#   2. share/ relative to this source   — dev checkout (prove -l)
#   3. File::ShareDir::dist_file()      — installed via CPAN
sub _schema_file {
    my ($filename) = @_;

    # 1. Explicit override — highest priority
    if ( my $dir = $ENV{OPENAPI_LINTER_SCHEMA_DIR} ) {
        my $path = File::Spec->catfile( $dir, $filename );
        return $path if -f $path;
        croak "OPENAPI_LINTER_SCHEMA_DIR set but '$path' not found";
    }

    # 2. Split __FILE__ into directory components and try share/ at each
    #    ancestor, walking upward by popping one component at a time.
    #    Works for both:
    #      prove -l  => /path/to/dist/lib/OpenAPI/Linter.pm
    #      make test => /path/to/dist/blib/lib/OpenAPI/Linter.pm
    #    Bounded to 20 iterations — enough for any real directory depth.
    my @parts = File::Spec->splitdir( File::Spec->rel2abs(__FILE__) );
    pop @parts;

    for ( 1 .. 20 ) {
        pop @parts;
        last unless @parts;
        my $candidate = File::Spec->catfile( @parts, 'share', $filename );
        return $candidate if -f $candidate;
    }

    # 3. Installed via CPAN
    return dist_file( 'OpenAPI-Linter', $filename );
}

# Load and return a schema hashref from a bundled JSON file.
sub _load_bundled_schema {
    my ($filename) = @_;
    my $path = _schema_file($filename);
    open my $fh, '<:encoding(UTF-8)', $path
        or croak "Cannot open bundled schema '$path': $!";
    my $raw    = do { local $/; <$fh> };
    my $schema = eval { decode_json($raw) };
    croak "Failed to parse bundled schema '$path': $@" if $@;
    return $schema;
}

# Build a lookup table: "dot.separated.path" => { line => N, column => N }
#
# Strategy: scan the raw file line by line. For each line we detect
# whether it looks like a YAML key or a JSON key and record the first
# occurrence. This is intentionally heuristic - it handles the vast
# majority of real-world specs without requiring a full-parse event API.
#
# YAML keys  matched as:   ^(\s*)([\w./{}~-]+)\s*:
# JSON keys  matched as:   ^(\s*)"([^"]+)"\s*:
#
# The leading whitespace length is used as the column number.

sub _build_line_index {
    my ($file) = @_;
    my %index;

    open my $fh, '<:encoding(UTF-8)', $file or return \%index;

    my $is_json = $file =~ /\.json$/i;
    my @stack;         # tracks the current path as an array of key segments
    my @indent_stack;  # parallel stack of indent levels

    my $line_no = 0;
    while (my $line = <$fh>) {
        $line_no++;
        chomp $line;

        my ($indent, $key);
        if ($is_json) {
            next unless $line =~ /^(\s*)"([^"]+)"\s*:/;
            ($indent, $key) = (length($1), $2);
        }
        else {
            next unless $line =~ /^(\s*)([\w.\/{}\~-][^:]*?)\s*:/;
            ($indent, $key) = (length($1), $2);
            $key =~ s/\s+$//;
        }

        # Pop stack entries that are at the same or deeper indent
        while (@indent_stack && $indent_stack[-1] >= $indent) {
            pop @stack;
            pop @indent_stack;
        }

        push @stack,        $key;
        push @indent_stack, $indent;

        my $path = join '.', @stack;
        $index{$path} //= { line => $line_no, column => $indent + 1 };
    }

    return \%index;
}

# Look up line/column for a dot-separated path, falling back gracefully
# if the path (or a prefix of it) is not in the index.

sub _resolve_location {
    my ($self, $path) = @_;

    my $idx = $self->{line_index};

    # Exact match
    if (exists $idx->{$path}) {
        return ($idx->{$path}{line}, $idx->{$path}{column});
    }

    # Try progressively shorter prefixes
    my @parts = split /\./, ($path // '');
    while (@parts > 1) {
        pop @parts;
        my $prefix = join '.', @parts;
        if (exists $idx->{$prefix}) {
            return ($idx->{$prefix}{line}, $idx->{$prefix}{column});
        }
    }

    return (0, 0);    # unknown
}

# Factory: build an OpenAPI::Linter::Location from a path string.

sub _make_location {
    my ($self, $path) = @_;
    my ($line, $col) = $self->_resolve_location($path // '');
    return OpenAPI::Linter::Location->new(
        path   => $path // '',
        file   => $self->{file_path},
        line   => $line,
        column => $col,
    );
}

=head1 SEE ALSO

=over 4

=item * L<JSON::Validator> - the underlying schema-validation engine.

=item * L<Mojolicious::Plugin::OpenAPI> - runtime OpenAPI validation for
Mojolicious applications.

=item * L<OpenAPI::Modern> - another OpenAPI validation toolkit.

=item * The OpenAPI Specification - L<https://spec.openapis.org/oas/latest.html>

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/OpenAPI-Linter>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/OpenAPI-Linter/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenAPI::Linter

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/OpenAPI-Linter/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenAPI-Linter>

=item * Search MetaCPAN

L<https://metacpan.org/dist/OpenAPI-Linter/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:
L<http://www.perlfoundation.org/artistic_license_2_0>
Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.
If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.
This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.
Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of OpenAPI::Linter
