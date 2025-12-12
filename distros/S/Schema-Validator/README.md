# NAME

Schema::Validator - Tools for validating and loading Schema.org vocabulary definitions

# VERSION

Version 0.01

# SYNOPSIS

## FROM THE COMMAND LINE

    bin/validate-schema --file index.html

## FROM PERL

    use Schema::Validator qw(is_valid_datetime load_dynamic_vocabulary);
    
    # Validate datetime strings
    if (is_valid_datetime('2024-11-14')) {
        print "Valid date\n";
    }
    
    if (is_valid_datetime('2024-11-14T15:30:00')) {
        print "Valid datetime\n";
    }
    
    # Load Schema.org vocabulary
    my %schema = load_dynamic_vocabulary();
    
    # Access loaded schema definitions
    print 'Classes: ', scalar(keys %Schema::Validator::dynamic_schema), "\n";
    print 'Properties: ', scalar(keys %Schema::Validator::dynamic_properties), "\n";

# DESCRIPTION

Schema::Validator provides utilities for working with Schema.org structured data vocabularies.
It includes functions for validating datetime formats and dynamically loading Schema.org class
and property definitions from the official Schema.org JSON-LD vocabulary file.

## Command Line Schema.org Validator

This repository contains a Schema.org validator that scans HTML files for embedded JSON-LD (\`application/ld+json\` blocks) and validates them against a local schema definition.
It can optionally output diagnostics in SARIF format for GitHub Code Scanning integration.

The Validator is a versatile tool designed to help you validate structured data embedded in your HTML files.
At its core, the script parses HTML to extract

    <script type="application/ld+json">

blocks and validates the included JSON-LD against a set of built-in schema rules-verifying properties such as required fields,
proper date formats (e.g., for startdate), enumerated values, and cross-field consistency
(like ensuring a MusicEvent's performer is either a Person or a PerformingGroup).
For basic usage, simply run

    bin/validate-schema --file sample/sample.html

to receive interactive console feedback about any missing or invalid properties.
The file can be a URL.

### Integration with GitHub Actions

To integrate with GitHub Code Scanning and CI/CD pipelines, you can activate SARIF output by adding the `--github` flag,
which aggregates diagnostics into a schema\_validation.sarif file.

### Dynamic Mode

If you want your validations to be driven by the most current standards, the `--dynamic` flag instructs the tool to download and cache the latest Schema.org vocabulary (currently loading over 900 classes) so that dynamic validations can be performed against live schema definitions.
 may combine these flags as needed-using `--file` with either or both of `--github` and `--dynamic` to tailor the tool for local testing,
automated code analysis,
or an in-depth schema audit.
The module caches the downloaded vocabulary to minimize network requests and improve performance.

# PACKAGE VARIABLES

## %dynamic\_schema

    %Schema::Validator::dynamic_schema

Global hash containing Schema.org class definitions, keyed by class label (e.g., 'Person',
'Organization', 'Event'). Each value is a complete class definition from the Schema.org
vocabulary.

This variable is populated by calling `load_dynamic_vocabulary()`.

## %dynamic\_properties

    %Schema::Validator::dynamic_properties

Global hash containing Schema.org property definitions, keyed by property label (e.g., 'name',
'email', 'address'). Each value is a complete property definition from the Schema.org vocabulary.

This variable is populated by calling `load_dynamic_vocabulary()`.

# DEPENDENCIES

This module requires the following Perl modules:

- [JSON::MaybeXS](https://metacpan.org/pod/JSON%3A%3AMaybeXS) - JSON encoding/decoding
- [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) - HTTP client for downloading vocabulary
- [Encode](https://metacpan.org/pod/Encode) - Character encoding utilities

# FILES

## schemaorg\_dynamic\_vocabulary.jsonld

Cache file created in the current working directory. Contains the downloaded Schema.org
vocabulary in JSON-LD format. Automatically refreshed when older than 24 hours.

# ERROR HANDLING

The module uses warnings rather than fatal errors for most failure conditions:

- Failed HTTP requests emit a warning and return empty results
- JSON parse errors emit a warning and return empty results
- File I/O errors emit warnings but attempt to continue operation

This allows the calling code to continue execution even if vocabulary loading fails.

# EXAMPLES

## Basic Usage

    use Schema::Validator qw(is_valid_datetime load_dynamic_vocabulary);
    
    # Validate user input
    my $date_input = '2024-11-14';
    unless (is_valid_datetime($date_input)) {
        die "Invalid date format\n";
    }
    
    # Load Schema.org vocabulary
    load_dynamic_vocabulary();
    
    # Check if a specific class exists
    if (exists $Schema::Validator::dynamic_schema{'Product'}) {
        print "Product class is defined in Schema.org\n";
    }

## Working with Loaded Vocabulary

    use Schema::Validator qw(load_dynamic_vocabulary);
    use Data::Dumper;
    
    # Load vocabulary
    my %classes = load_dynamic_vocabulary();
    
    # Examine a specific class
    if (my $person = $Schema::Validator::dynamic_schema{'Person'}) {
        print "Person class definition:\n";
        print Dumper($person);
    }
    
    # List all available properties
    my @props = keys %Schema::Validator::dynamic_properties;
    print "Available properties: ", join(', ', sort @props), "\n";

## is\_valid\_datetime

    my $is_valid = is_valid_datetime($string);

Validates whether a string matches valid datetime formats.

**Parameters:**

- `$string` - The string to validate

**Returns:** Boolean (1 for valid, 0 for invalid)

**Accepted formats:**

- `YYYY-MM-DD` - Date only (e.g., "2024-11-14")
- `YYYY-MM-DDTHH:MM` - Date with time (e.g., "2024-11-14T15:30")
- `YYYY-MM-DD HH:MM` - Date with time, space separator (e.g., "2024-11-14 15:30")
- `YYYY-MM-DDTHH:MM:SS` - Date with time including seconds (e.g., "2024-11-14T15:30:45")
- `YYYY-MM-DD HH:MM:SS` - Date with time including seconds, space separator

**Example:**

    if (is_valid_datetime('2024-11-14T15:30:00')) {
        print "Valid ISO 8601 datetime\n";
    }

## load\_dynamic\_vocabulary

    my %classes = load_dynamic_vocabulary();

Downloads and parses the Schema.org vocabulary from the official source, extracting class
and property definitions. The vocabulary is cached locally for 24 hours to reduce network
overhead.

**Parameters:** None

**Returns:** Hash mapping class labels to their complete Schema.org definitions

**Side effects:**

- Populates `%Schema::Validator::dynamic_schema` with class definitions
- Populates `%Schema::Validator::dynamic_properties` with property definitions
- Creates/updates cache file `schemaorg_dynamic_vocabulary.jsonld` in the current directory
- Emits warnings on download, parse, or file I/O errors

**Cache behavior:**

The function maintains a local cache file (`schemaorg_dynamic_vocabulary.jsonld`) that
expires after 24 hours. If the cache is valid, the vocabulary is loaded from the cache
rather than downloading from Schema.org.

**Example:**

    my %schema_classes = load_dynamic_vocabulary();
    
    # Access specific class definition
    if (exists $Schema::Validator::dynamic_schema{'Person'}) {
        my $person_def = $Schema::Validator::dynamic_schema{'Person'};
        print "Person class loaded\n";
    }
    
    # Access property definitions
    if (exists $Schema::Validator::dynamic_properties{'name'}) {
        my $name_prop = $Schema::Validator::dynamic_properties{'name'};
        print "Name property loaded\n";
    }

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

- Cache file is stored in the current working directory, which may cause issues with
file permissions or multiple concurrent processes
- No timezone support in datetime validation
- Cache invalidation is time-based only; no checksums or version checking
- Network failures during vocabulary download return empty results rather than using
stale cache

# SEE ALSO

- [https://schema.org/](https://schema.org/) - Schema.org structured data vocabulary
- [JSON::MaybeXS](https://metacpan.org/pod/JSON%3A%3AMaybeXS) - JSON encoding/decoding
- [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) - HTTP client library

# REPOSITORY

[https://github.com/nigelhorne/schema-validator](https://github.com/nigelhorne/schema-validator)

# SUPPORT

This module is provided as-is without any warranty.

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
