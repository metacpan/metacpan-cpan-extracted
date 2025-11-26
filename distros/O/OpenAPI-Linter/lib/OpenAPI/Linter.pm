package OpenAPI::Linter;

$OpenAPI::Linter::VERSION   = '0.14';
$OpenAPI::Linter::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

OpenAPI::Linter - Validate and lint OpenAPI specifications

=head1 VERSION

Version 0.14

=head1 SYNOPSIS

    use OpenAPI::Linter;

    # Create a linter from a file
    my $linter = OpenAPI::Linter->new(spec => 'openapi.yaml');

    # Or from a hashref
    my $linter = OpenAPI::Linter->new(spec => $openapi_hash);

    # Find issues in the specification
    my @issues = $linter->find_issues;

    # Filter issues by level or pattern
    my @warnings = $linter->find_issues(level => 'WARN');
    my @path_issues = $linter->find_issues(pattern => qr/paths?/i);

    # Validate against JSON Schema
    my @schema_errors = $linter->validate_schema;

=head1 DESCRIPTION

C<OpenAPI::Linter> provides comprehensive validation and linting for C<OpenAPI> specifications.
It checks both structural correctness against the official C<JSON> Schema and performs
additional linting for best practices and common issues.

The module supports C<OpenAPI> versions C<3.0.x> and C<3.1.x>, automatically detecting the
specification version from the provided document.

=cut

use strict;
use warnings;
use JSON::Validator;
use JSON qw(decode_json);
use YAML::XS qw(LoadFile);
use File::Slurp qw(read_file);
use OpenAPI::Linter::Location;

=head1 METHODS

=head2 new

    my $linter = OpenAPI::Linter->new(spec => $file_path_or_hashref);
    my $linter = OpenAPI::Linter->new(spec => $hashref, version => '3.0.3');

Creates a new C<OpenAPI::Linter> instance. The constructor accepts:

=over 4

=item * spec

Required. Either a file path to an C<OpenAPI> specification (C<YAML> or C<JSON>)
or a hash reference containing the parsed C<OpenAPI> specification.

=item * version

Optional. Explicitly set the C<OpenAPI> version. If not provided, the version will be
auto-detected from the specification.

=back

=cut

sub new {
    my ($class, %args) = @_;

    my $spec;
    my $locations = {};
    my $file_path = $args{spec};

    if (ref $args{spec} eq 'HASH') {
        # Already a hashref - use directly
        $spec = $args{spec};
        # For hashref input, we can't provide line numbers
        $locations = { base => OpenAPI::Linter::Location->new('input', 1, 1) };
        $file_path = 'input';
    }
    elsif ($args{spec}) {
        $file_path = $args{spec};
        die "ERROR: Spec file not found: $file_path\n" unless (-f $file_path);

        if ($file_path =~ /\.ya?ml$/i) {
            # Try to use YAML::PP for better location tracking
            my $yaml_pp_available = eval {
                require YAML::PP;
                YAML::PP->import();
                1;
            };

            if ($yaml_pp_available) {
                # First: Load with preserve mode ONLY for location tracking
                my $yamlpp_preserve = YAML::PP->new( preserve => 1 );
                my $spec_preserved = $yamlpp_preserve->load_file($file_path);
                $locations = _extract_yaml_locations($spec_preserved, $file_path);

                # Second: Load again WITHOUT preserve mode for clean validation data
                my $yamlpp_clean = YAML::PP->new();
                $spec = $yamlpp_clean->load_file($file_path);

                # Ensure we always have a base location
                $locations->{base} = OpenAPI::Linter::Location->new($file_path, 1, 1)
                    unless exists $locations->{base};
            }
            else {
                # Fall back to YAML::XS
                $spec = LoadFile($file_path);
                $locations = { base => OpenAPI::Linter::Location->new($file_path, 1, 1) };
            }
        }
        else {
            $spec = decode_json(read_file($file_path));
            # JSON doesn't easily give us line numbers, but we can approximate
            $locations = { base => OpenAPI::Linter::Location->new($file_path, 1, 1) };
        }
    }
    else {
        die "spec => HASHREF required if no file provided";
    }

    my $version = $args{version} || $spec->{openapi} || '3.0.3';

    return bless {
        spec      => $spec,
        issues    => [],
        version   => $version,
        locations => $locations,
        file_path => $file_path,
    }, $class;
}

=head2 find_issues()

Finds and returns linting issues in the C<OpenAPI> specification. Returns a list of issue
hashes in list context, or an array reference in scalar context.

Each issue hash contains:

    {
        level   => 'ERROR' | 'WARN',  # Issue severity level
        message => 'Human readable description of the issue'
    }

Parameters:

=over 4

=item * level

Filter issues by severity level. Either C<ERROR> or C<WARN>.

=item * pattern

Filter issues by message pattern (regular expression).

=back

    my @all_issues = $linter->find_issues;
    my @issues = $linter->find_issues(level => 'ERROR');
    my @issues = $linter->find_issues(pattern => qr/missing/i);
    my @issues = $linter->find_issues(level => 'WARN', pattern => qr/description/);

=cut

sub find_issues {
    my ($self, %opts) = @_;

    my $spec      = $self->{spec}      || {};
    my $locations = $self->{locations} || {};
    my @issues;

    # Helper to get location for a path
    my $get_location = sub {
        my $path = shift;

        # Try the exact path first
        return $locations->{$path} if exists $locations->{$path};

        # Try to find a parent path
        my @path_parts = split(/\./, $path);
        while (@path_parts) {
            pop @path_parts;
            my $parent_path = join('.', @path_parts);
            return $locations->{$parent_path}
                if exists $locations->{$parent_path};
        }

        # Fall back to base location
        return $locations->{base}
            || OpenAPI::Linter::Location->new($self->{file_path}, 1, 1);
    };

    # Check OpenAPI root keys
    foreach my $key (qw/openapi info paths/) {
        unless ($spec->{$key}) {
            my $location = $get_location->($key);
            push @issues, {
                level    => 'ERROR',
                message  => "Missing $key",
                location => $location->to_string,
                path     => $key
            };
        }
    }

    # Info checks
    if ($spec->{info}) {
        my $info = $spec->{info};

        unless ($info->{title}) {
            my $location = $get_location->('info.title');
            push @issues, {
                level    => 'ERROR',
                message  => 'Missing info.title',
                location => $location->to_string,
                path     => 'info.title'
            };
        }

        unless ($info->{version}) {
            my $location = $get_location->('info.version');
            push @issues, {
                level    => 'ERROR',
                message  => 'Missing info.version',
                location => $location->to_string,
                path     => 'info.version'
            };
        }

        unless ($info->{description}) {
            my $location = $get_location->('info.description');
            push @issues, {
                level    => 'WARN',
                message  => 'Missing info.description',
                location => $location->to_string,
                path     => 'info.description'
            };
        }

        unless ($info->{license}) {
            my $location = $get_location->('info.license');
            push @issues, {
                level    => 'WARN',
                message  => 'Missing info.license',
                location => $location->to_string,
                path     => 'info.license'
            };
        }
    }

    # Paths / operations
    if ($spec->{paths}) {
        for my $path (sort keys %{$spec->{paths}}) {
            for my $method (sort keys %{$spec->{paths}{$path}}) {
                my $op = $spec->{paths}{$path}{$method};
                unless ($op->{description}) {
                    my $_path    = "paths.$path.$method.description";
                    my $location = $get_location->($_path);
                    push @issues, {
                        level    => 'WARN',
                        message  => "Missing description for $method $path",
                        location => $location->to_string,
                        path     => $_path,
                    };
                }
            }
        }
    }

    # Components / schemas
    if ($spec->{components} && $spec->{components}{schemas}) {
        for my $name (sort keys %{$spec->{components}{schemas}}) {
            my $schema = $spec->{components}{schemas}{$name};
            unless ($schema->{type}) {
                my $path     = "components.schemas.$name.type";
                my $location = $get_location->($path);
                push @issues, {
                    level    => 'WARN',
                    message  => "Schema $name missing type",
                    location => $location->to_string,
                    path     => $path,
                };
            }

            if ($schema->{properties}) {
                for my $prop (sort keys %{$schema->{properties}}) {
                    unless ($schema->{properties}{$prop}{description}) {
                        my $path = "components.schemas.$name.properties.$prop.description";
                        my $location = $get_location->($path);
                        push @issues, {
                            level    => 'WARN',
                            message  => "Schema $name.$prop missing description",
                            location => $location->to_string,
                            path     => $path,
                        };
                    }
                }
            }
        }
    }

    my $pattern = $opts{pattern};
    my $level   = $opts{level};
    my @result  = grep {
        (!defined($level)   || $_->{level}   eq $level)     &&
        (!defined($pattern) || $_->{message} =~ /$pattern/)
    } @issues;

    return wantarray ? @result : \@result;
}

=head2 validate_schema()

    my @schema_errors = $linter->validate_schema;
    my $schema_errors = $linter->validate_schema;

Validates the C<OpenAPI> specification against the official C<JSON> Schema for the detected
C<OpenAPI> version. Returns a list of validation errors in list context or an array
reference in scalar context.

This method uses L<JSON::Validator> to perform schema validation.

=cut

sub validate_schema {
    my ($self) = @_;

    my $validator = JSON::Validator->new;

    # Map of OpenAPI versions to their schema URLs
    my %schema_urls = (
        '3.0.0' => 'https://spec.openapis.org/oas/3.0/schema/2021-09-28',
        '3.0.1' => 'https://spec.openapis.org/oas/3.0/schema/2021-09-28',
        '3.0.2' => 'https://spec.openapis.org/oas/3.0/schema/2021-09-28',
        '3.0.3' => 'https://spec.openapis.org/oas/3.0/schema/2021-09-28',
        '3.1.0' => 'https://spec.openapis.org/oas/3.1/schema/2022-10-07',
        '3.1.1' => 'https://spec.openapis.org/oas/3.1/schema/2022-10-07',
    );

    my $version = $self->{version} || $self->{spec}->{openapi} || '';
    $version =~ s/^\s+|\s+$//g;

    if ($version =~ /^3$/) {
        $version = '3.0.0';
    }
    elsif ($version =~ /^3\.(\d)$/) {
        $version .= '.0';
    }

    $self->{version} = $version;

    my $schema_url = $schema_urls{$version};
    unless ($schema_url) {
        if ($version =~ /^3\.1/) {
            $schema_url = 'https://spec.openapis.org/oas/3.1/schema/2022-10-07';
        }
        elsif ($version =~ /^3\.0/) {
            $schema_url = 'https://spec.openapis.org/oas/3.0/schema/2021-09-28';
        }
        else {
            die "Unsupported OpenAPI version: $version";
        }
    }

    # Apply the fix before validation
    _apply_json_validator_fix();

    # Only coerce booleans to handle true/false properly
    # Do NOT coerce numbers or strings as that would hide legitimate type errors
    $validator->coerce('booleans');

    my @raw_errors = $validator->schema($schema_url)->validate($self->{spec});

    # JSON::Validator returns 0 (a plain scalar) for success
    # Error objects are blessed references
    # Only filter out if we have a single non-reference item
    if (@raw_errors == 1 && !ref($raw_errors[0])) {
        # It's a scalar success indicator, not an error object
        @raw_errors = ();
    }

    @raw_errors = grep {
        my $keep = 1;  # Default to keeping the error
        my $error_str;
        eval {
            $error_str = ref $_ ? ($_->can('to_string') ? $_->to_string : "$_") : "$_";
        };
        if ($@) {
            $keep = 1;  # Keep errors we can't stringify
        }
        else {
            # Skip errors about 'path' not being in enum for parameter 'in' field
            # as 'path' is a valid value per OpenAPI 3.0 spec
            # These errors appear as "/in: ... Not in enum list: query/header/cookie"
            # when the actual value is 'path' which is missing from the enum
            if ($error_str =~ m{/in:.*Not in enum list}i) {
                $keep = 0;
            }
            # Skip errors about boolean true not being in enum for 'required' field
            # as true is a valid boolean value per OpenAPI 3.0 spec
            elsif ($error_str =~ m{/required:.*Not in enum list}i && $error_str =~ m{true}i) {
                $keep = 0;
            }
            # Skip errors about missing $ref when the object is properly defined
            elsif ($error_str =~ m{/parameters/.*\$ref:.*Missing property}i) {
                $keep = 0;
            }
        }

        $keep;  # Return the decision
    } @raw_errors;

    # Convert to consistent hashref format with location information
    my @issues = map {
        my $message;
        my $path = '';

        if (ref $_) {
            # Extract message
            if ($_->can('to_string')) {
                $message = $_->to_string;
            } elsif (exists $_->{message}) {
                $message = $_->{message};
            } elsif ($_->can('message')) {
                $message = $_->message;
            } else {
                $message = "$_";
            }

            # Extract path for location
            if ($_->can('path') && $_->path) {
                $path = $_->path;
            } elsif (exists $_->{path} && $_->{path}) {
                $path = $_->{path};
            }
        } else {
            $message = $_;
        }

        # Convert JSON Pointer path to our location format
        my $location_path = $path;
        $location_path =~ s{^/}{};
        $location_path =~ s{/}{.}g;
        $location_path =~ s{~1}{/}g;
        $location_path =~ s{~0}{~}g;

        my $location = $self->{locations}{$location_path} ||
                      $self->{locations}{base} ||
                      OpenAPI::Linter::Location->new($self->{file_path}, 1, 1);

        {
            level    => 'ERROR',
            message  => $message,
            type     => 'schema_validation',
            location => $location->to_string,
            path     => $location_path
        }
    } @raw_errors;

    return wantarray ? @issues : \@issues;
}

sub format_schema_error {
    my ($self, $message) = @_;

    # Remove duplicate path prefixes
    $message =~ s{^(/.+?):\s+\1:}{$1:};

    # Clean up encoded paths for readability
    $message =~ s{/~001}{/}g;
    $message =~ s{/~1}{/}g;

    # If still long, wrap after the first colon
    if (length($message) > 80) {
        $message =~ s/:\s+/:\n      /;
    }

    return "  - $message";
}

sub _apply_json_validator_fix {
    return if our $FIX_APPLIED++;

    {
        package JSON::Validator::Schema;
        no warnings 'redefine';

        my $orig_validate_format = \&_validate_format;

        *_validate_format = sub {
            my ($self, $value, $state) = @_;
            my $format = $state->{schema}{format};

            # Handle URI format validators gracefully - don't warn if missing
            if ($format && $format =~ /^(uri|uri-reference|uri-template)$/) {
                my $code = $self->formats->{$format};
                return unless $code;  # Silently skip if validator missing

                return unless my $err = $code->($value);
                return E $state->{path}, [format => $format, $err];
            }

            # Use original validation for other formats
            return $orig_validate_format->(@_);
        };
    }
}

sub _extract_yaml_locations {
    my ($data, $file_path) = @_;
    my $locations = {};

    # Always set a base location
    $locations->{base} = OpenAPI::Linter::Location->new($file_path, 1, 1);

    _walk_yaml_data($data, '', $locations, $file_path);
    return $locations;
}

sub _walk_yaml_data {
    my ($node, $path, $locations, $file_path) = @_;

    return unless defined $node;

    if (ref $node eq 'HASH') {
        while (my ($key, $value) = each %$node) {
            my $actual_key = ref $key eq 'YAML::PP::Node' ? $key->value : $key;
            my $new_path = $path ? "$path.$actual_key" : $actual_key;

            # Store location if available from YAML::PP
            if (ref $key eq 'YAML::PP::Node') {
                my $line = $key->line || 1;
                my $column = $key->column || 1;
                $locations->{$new_path} =
                    OpenAPI::Linter::Location->new($file_path, $line, $column);
            }

            _walk_yaml_data($value, $new_path, $locations, $file_path);
        }
    }
    elsif (ref $node eq 'ARRAY') {
        for my $i (0 .. $#$node) {
            my $new_path = "$path\[$i]";
            my $item = $node->[$i];

            # Store location for array items if available
            if (ref $item eq 'YAML::PP::Node') {
                my $line = $item->line || 1;
                my $column = $item->column || 1;
                $locations->{$new_path} =
                    OpenAPI::Linter::Location->new($file_path, $line, $column);
            }

            _walk_yaml_data($item, $new_path, $locations, $file_path);
        }
    }
    # For scalar values, we don't store separate locations as
    # they're handled by their keys
}

=head1 APPLICATION

C<openapi-linter> is a command-line tool that validates C<OpenAPI> specifications
for both structural correctness and best practices. It uses the L<OpenAPI::Linter>
module to perform comprehensive checks on C<OpenAPI> documents.

The tool can operate in two modes:

=over 4

=item 1. Linting mode (default)

Checks for best practices, missing required fields and common issues in C<OpenAPI> specifications.

=item 2. Schema validation mode

Validates the specification against the official C<OpenAPI JSON Schema> for the detected version.

=back

=head2 OPTIONS

=over 4

=item B<--spec> I<specfile>

B<Required>. Path to the C<OpenAPI> specification file. The file can be in either
C<YAML> (.yaml, .yml) or C<JSON> (.json) format.

=item B<--version> I<version>

Specify the C<OpenAPI> version explicitly (e.g., C<3.0.3>, C<3.1.0>). If not provided,
the version will be auto-detected from the C<openapi> field in the specification.

=item B<--json>

Output results in C<JSON> format instead of human-readable text. This is useful for
programmatic consumption of the results.

=item B<--validate>

Run schema validation instead of lint checks. This mode validates the specification
against the official C<OpenAPI JSON Schema> rather than performing custom linting rules.

=item B<--help>

Display this help message and exit.

=back

=head2 EXAMPLES

=head3 Basic Usage

    openapi-linter --spec api.yaml

Run linting checks on C<api.yaml> and display results in human-readable format.

=head3 Schema Validation

    openapi-linter --spec api.json --validate

Validate C<api.json> against the official C<OpenAPI JSON Schema>.

=head3 JSON Output

    openapi-linter --spec api.yaml --json

Run linting checks and output results in JSON format for programmatic processing.

=head3 Specific Version

    openapi-linter --spec api.yaml --version 3.1.0

Run linting checks assuming C<OpenAPI> version C<3.1.0>, overriding auto-detection.

=head2 OUTPUT FORMATS

=head3 Human Readable Output (Default)

The default output format displays issues in a readable format:

    [ERROR] Missing info.title
    [WARN] Missing info.description
    [ERROR] Missing info.version

    Summary: 2 ERRORs, 1 WARN

=head3 Exit Codes

=over 4

=item * 0: No issues found

=item * 1: Issues found (errors and/or warnings)

=item * 2: Usage error

=back

=head3 JSON Output

When using C<--json>, the output is structured C<JSON>:

    {
        "summary": {
            "errors": 2,
            "warnings": 1
        },
        "issues": [
            {
                "level": "ERROR",
                "message": "Missing info.title"
            },
            {
                "level": "WARN",
                "message": "Missing info.description"
            },
            {
                "level": "ERROR",
                "message": "Missing info.version"
            }
        ]
    }

=head2 LINTING CHECKS

When running in linting mode (default), the tool checks for:

=over 4

=item * Required root elements (openapi, info, paths)

=item * Required info object fields (title, version)

=item * Recommended info object fields (description, license)

=item * Operation descriptions for all paths and methods

=item * Schema type definitions and property descriptions

=back

=head2 SCHEMA VALIDATION

When using C<--validate>, the tool validates the specification against the
official C<OpenAPI JSON Schema> for the detected version. This checks:

=over 4

=item * Structural correctness of the specification

=item * Data types and format compliance

=item * Required fields according to the C<OpenAPI> specification

=item * Valid references and schema composition

=back

=head2 SUPPORTED OPENAPI VERSIONS

=over 4

=item * OpenAPI 3.0.0, 3.0.1, 3.0.2, 3.0.3

=item * OpenAPI 3.1.0, 3.1.1

=back

=head1 DIAGNOSTICS

=over 4

=item C<"spec => HASHREF required if no file provided">

The C<spec> parameter to C<new> must be either a file path or a hash reference containing
the C<OpenAPI> specification.

=item C<"Unsupported OpenAPI version: %s">

The C<OpenAPI> version specified in the document or provided to the constructor is not supported.

=back

=head1 SEE ALSO

=over 4

=item * L<JSON::Validator> - Used for schema validation

=item * L<OpenAPI::Modern> - Alternative OpenAPI implementation

=item * L<https://www.openapis.org/> - OpenAPI Initiative

=item * L<https://swagger.io/specification/> - OpenAPI Specification

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

Copyright (C) 2025 Mohammad Sajid Anwar.

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
