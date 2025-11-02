package OpenAPI::Linter;

$OpenAPI::Linter::VERSION   = '0.10';
$OpenAPI::Linter::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

OpenAPI::Linter - Validate and lint OpenAPI specifications

=head1 VERSION

Version 0.10

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

=head1 METHODS

=head2 new

    my $linter = OpenAPI::Linter->new(spec => $file_path_or_hashref);
    my $linter = OpenAPI::Linter->new(spec => $hashref, version => '3.0.3');

Creates a new OpenAPI::Linter instance. The constructor accepts:

=over 4

=item * spec

Required. Either a file path to an OpenAPI specification (YAML or JSON) or a hash reference
containing the parsed OpenAPI specification.

=item * version

Optional. Explicitly set the OpenAPI version. If not provided, the version will be
auto-detected from the specification.

=back

=cut

sub new {
    my ($class, %args) = @_;

    my $spec;

    if (ref $args{spec} eq 'HASH') {
        # Already a hashref — use directly
        $spec = $args{spec};
    }
    elsif ($args{spec}) {
        my $path = $args{spec};
        die "ERROR: Spec file not found: $path\n" unless (-f $path);

        if ($path =~ /\.ya?ml$/i) {
            $spec = LoadFile($path);
        } else {
            $spec = decode_json(read_file($path));
        }
    }
    else {
        die "spec => HASHREF required if no file provided";
    }

    my $version = $args{version} || $spec->{openapi} || '3.0.3';

    return bless {
        spec    => $spec,
        issues  => [],
        version => $version,
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

    my $spec = $self->{spec} || {};
    my @issues;

    # Check OpenAPI root keys
    foreach my $key (qw/openapi info paths/) {
        push @issues, {
            level   => 'ERROR',
            message => "Missing $key"
        } unless $spec->{$key};
    }

    # Info checks
    if ($spec->{info}) {
        my $info = $spec->{info};
        push @issues, {
            level   => 'ERROR',
            message => 'Missing info.title'
        } unless $info->{title};
        push @issues, {
            level   => 'ERROR',
            message =>'Missing info.version'
        } unless $info->{version};
        push @issues, {
            level   => 'WARN',
            message => 'Missing info.description'
        } unless $info->{description};
        push @issues, {
            level   => 'WARN',
            message => 'Missing info.license'
        } unless $info->{license};
    }

    # Paths / operations
    if ($spec->{paths}) {
        for my $path (sort keys %{$spec->{paths}}) {
            for my $method (sort keys %{$spec->{paths}{$path}}) {
                my $op = $spec->{paths}{$path}{$method};
                push @issues, {
                    level   => 'WARN',
                    message => "Missing description for $method $path"
                } unless $op->{description};
            }
        }
    }

    # Components / schemas
    if ($spec->{components} && $spec->{components}{schemas}) {
        for my $name (sort keys %{$spec->{components}{schemas}}) {
            my $schema = $spec->{components}{schemas}{$name};
            push @issues, {
                level   => 'WARN',
                message => "Schema $name missing type"
            } unless $schema->{type};

            if ($schema->{properties}) {
                for my $prop (sort keys %{$schema->{properties}}) {
                    push @issues, {
                        level   => 'WARN',
                        message => "Schema $name.$prop missing description"
                    } unless $schema->{properties}{$prop}{description};
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

This method uses L<JSON::Validator> to perform schema validation and returns errors
in the format provided by that module.

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

    my @raw_errors = $validator->schema($schema_url)->validate($self->{spec});

    # Convert to consistent hashref format matching find_issues
    my @issues = map {
        my $message;

        if (ref $_) {
            # Try different methods to extract the error message
            if ($_->can('to_string')) {
                $message = $_->to_string;
            } elsif (exists $_->{message}) {
                $message = $_->{message};
            } elsif ($_->can('message')) {
                $message = $_->message;
            } else {
                $message = "$_";
            }

            # Include path if available
            if ($_->can('path') && $_->path) {
                $message = $_->path . ": $message";
            } elsif (exists $_->{path} && $_->{path}) {
                $message = $_->{path} . ": $message";
            }
        } else {
            $message = $_;
        }

        {
            level   => 'ERROR',
            message => $message,
            type    => 'schema_validation'
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

=head1 APPLICATION

C<openapi-linter> is a command-line tool that validates C<OpenAPI> specifications
for both structural correctness and best practices. It uses the L<OpenAPI::Linter>
module to perform comprehensive checks on C<OpenAPI> documents.

The tool can operate in two modes:

=over 4

=item 1. Linting mode (default)

Checks for best practices, missing required fields and common issues in OpenAPI specifications.

=item 2. Schema validation mode

Validates the specification against the official OpenAPI JSON Schema for the detected version.

=back

=head2 OPTIONS

=over 4

=item B<--spec> I<specfile>

B<Required>. Path to the OpenAPI specification file. The file can be in either
YAML (.yaml, .yml) or JSON (.json) format.

=item B<--version> I<version>

Specify the OpenAPI version explicitly (e.g., C<3.0.3>, C<3.1.0>). If not provided,
the version will be auto-detected from the C<openapi> field in the specification.

=item B<--json>

Output results in JSON format instead of human-readable text. This is useful for
programmatic consumption of the results.

=item B<--validate>

Run schema validation instead of lint checks. This mode validates the specification
against the official OpenAPI JSON Schema rather than performing custom linting rules.

=item B<--help>

Display this help message and exit.

=back

=head2 EXAMPLES

=head3 Basic Usage

    openapi-linter --spec api.yaml

Run linting checks on C<api.yaml> and display results in human-readable format.

=head3 Schema Validation

    openapi-linter --spec api.json --validate

Validate C<api.json> against the official OpenAPI JSON Schema.

=head3 JSON Output

    openapi-linter --spec api.yaml --json

Run linting checks and output results in JSON format for programmatic processing.

=head3 Specific Version

    openapi-linter --spec api.yaml --version 3.1.0

Run linting checks assuming OpenAPI version 3.1.0, overriding auto-detection.

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
official OpenAPI JSON Schema for the detected version. This checks:

=over 4

=item * Structural correctness of the specification

=item * Data types and format compliance

=item * Required fields according to the OpenAPI specification

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
the OpenAPI specification.

=item C<"Unsupported OpenAPI version: %s">

The OpenAPI version specified in the document or provided to the constructor is not supported.

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
