package Schema::Validator;

use strict;
use warnings;

use JSON::MaybeXS qw(decode_json encode_json);
use LWP::UserAgent;
use Encode qw(decode);

use base 'Exporter';				# Use Exporter as the base class
our @EXPORT_OK = qw(is_valid_datetime load_dynamic_vocabulary);

our $VERSION = '0.01';

our %dynamic_properties;	# Global variable to store property definitions
our %dynamic_schema;	# Global variable to store class definitions

=head1 NAME

Schema::Validator - Tools for validating and loading Schema.org vocabulary definitions

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

=head2 FROM THE COMMAND LINE

    bin/validate-schema --file index.html

=head2 FROM PERL

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

=head1 DESCRIPTION

Schema::Validator provides utilities for working with Schema.org structured data vocabularies.
It includes functions for validating datetime formats and dynamically loading Schema.org class
and property definitions from the official Schema.org JSON-LD vocabulary file.

=head2 Command Line Schema.org Validator

This repository contains a Schema.org validator that scans HTML files for embedded JSON-LD (`application/ld+json` blocks) and validates them against a local schema definition.
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

=head3 Integration with GitHub Actions

To integrate with GitHub Code Scanning and CI/CD pipelines, you can activate SARIF output by adding the C<--github> flag,
which aggregates diagnostics into a schema_validation.sarif file.

=head3 Dynamic Mode

If you want your validations to be driven by the most current standards, the C<--dynamic> flag instructs the tool to download and cache the latest Schema.org vocabulary (currently loading over 900 classes) so that dynamic validations can be performed against live schema definitions.
 may combine these flags as needed-using C<--file> with either or both of C<--github> and C<--dynamic> to tailor the tool for local testing,
automated code analysis,
or an in-depth schema audit.
The module caches the downloaded vocabulary to minimize network requests and improve performance.

=head1 PACKAGE VARIABLES

=head2 %dynamic_schema

    %Schema::Validator::dynamic_schema

Global hash containing Schema.org class definitions, keyed by class label (e.g., 'Person',
'Organization', 'Event'). Each value is a complete class definition from the Schema.org
vocabulary.

This variable is populated by calling C<load_dynamic_vocabulary()>.

=head2 %dynamic_properties

    %Schema::Validator::dynamic_properties

Global hash containing Schema.org property definitions, keyed by property label (e.g., 'name',
'email', 'address'). Each value is a complete property definition from the Schema.org vocabulary.

This variable is populated by calling C<load_dynamic_vocabulary()>.

=head1 DEPENDENCIES

This module requires the following Perl modules:

=over 4

=item * L<JSON::MaybeXS> - JSON encoding/decoding

=item * L<LWP::UserAgent> - HTTP client for downloading vocabulary

=item * L<Encode> - Character encoding utilities

=back

=head1 FILES

=head2 schemaorg_dynamic_vocabulary.jsonld

Cache file created in the current working directory. Contains the downloaded Schema.org
vocabulary in JSON-LD format. Automatically refreshed when older than 24 hours.

=head1 ERROR HANDLING

The module uses warnings rather than fatal errors for most failure conditions:

=over 4

=item * Failed HTTP requests emit a warning and return empty results

=item * JSON parse errors emit a warning and return empty results

=item * File I/O errors emit warnings but attempt to continue operation

=back

This allows the calling code to continue execution even if vocabulary loading fails.

=head1 EXAMPLES

=head2 Basic Usage

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

=head2 Working with Loaded Vocabulary

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

=head2 is_valid_datetime

    my $is_valid = is_valid_datetime($string);

Validates whether a string matches valid datetime formats.

B<Parameters:>

=over 4

=item * C<$string> - The string to validate

=back

B<Returns:> Boolean (1 for valid, 0 for invalid)

B<Accepted formats:>

=over 4

=item * C<YYYY-MM-DD> - Date only (e.g., "2024-11-14")

=item * C<YYYY-MM-DDTHH:MM> - Date with time (e.g., "2024-11-14T15:30")

=item * C<YYYY-MM-DD HH:MM> - Date with time, space separator (e.g., "2024-11-14 15:30")

=item * C<YYYY-MM-DDTHH:MM:SS> - Date with time including seconds (e.g., "2024-11-14T15:30:45")

=item * C<YYYY-MM-DD HH:MM:SS> - Date with time including seconds, space separator

=back

B<Example:>

    if (is_valid_datetime('2024-11-14T15:30:00')) {
        print "Valid ISO 8601 datetime\n";
    }

=cut

# Validates that a string is in YYYY-MM-DD or YYYY-MM-DDTHH:MM(:SS)? format.
sub is_valid_datetime {
	my $val = shift;
	return $val =~ /^\d{4}-\d{2}-\d{2}(?:[T ]\d{2}:\d{2}(?::\d{2})?)?$/;
}

=head2 load_dynamic_vocabulary

    my %classes = load_dynamic_vocabulary();

Downloads and parses the Schema.org vocabulary from the official source, extracting class
and property definitions. The vocabulary is cached locally for 24 hours to reduce network
overhead.

B<Parameters:> None

B<Returns:> Hash mapping class labels to their complete Schema.org definitions

B<Side effects:>

=over 4

=item * Populates C<%Schema::Validator::dynamic_schema> with class definitions

=item * Populates C<%Schema::Validator::dynamic_properties> with property definitions

=item * Creates/updates cache file C<schemaorg_dynamic_vocabulary.jsonld> in the current directory

=item * Emits warnings on download, parse, or file I/O errors

=back

B<Cache behavior:>

The function maintains a local cache file (C<schemaorg_dynamic_vocabulary.jsonld>) that
expires after 24 hours. If the cache is valid, the vocabulary is loaded from the cache
rather than downloading from Schema.org.

B<Example:>

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

=cut

# Loads the dynamic Schema.org vocabulary from Schema.org and returns a hash mapping class labels to their definitions.
sub load_dynamic_vocabulary {
	my $cache_file	 = 'schemaorg_dynamic_vocabulary.jsonld';
	my $cache_duration = 86400;	# Cache expires in 1 day (86400 seconds)
	my $content;
	my $use_cache = 0;

	if (-e $cache_file) {
		my $mtime = (stat($cache_file))[9];
		if ( time - $mtime < $cache_duration ) {
			$use_cache = 1;
		}
	}

	if ($use_cache) {
		# Read from the cache file
		open my $cfh, '<', $cache_file or warn "Could not open cache file $cache_file: $!";
		{
			local $/;	# Slurp mode
			$content = <$cfh>;
		}
		close $cfh;
	} else {
		# Download the vocabulary from Schema.org
		my $url = 'https://schema.org/version/latest/schemaorg-current-https.jsonld';
		my $ua = LWP::UserAgent->new( timeout => 30 );
		my $res = $ua->get($url);
		unless ($res->is_success) {
			warn "Failed to fetch dynamic vocabulary from $url: " . $res->status_line;
			return ();
		}
		$content = $res->decoded_content;
		# Write the downloaded content to the cache file.
		open my $cfh, '>', $cache_file or warn "Could not write to cache file $cache_file: $!";
		print $cfh $content;
		close $cfh;
	}

	my $data = eval { decode_json($content) };
	if ($@) {
		warn "Failed to parse dynamic vocabulary JSON: $@";
		return ();
	}

	my %class_vocab;
	my %prop_vocab;

	if (exists $data->{'@graph'} && ref($data->{'@graph'}) eq 'ARRAY') {
		for my $item (@{ $data->{'@graph'} }) {
			next unless exists $item->{'@type'};
			my $item_type = $item->{'@type'};

			# Check for class definitions
			my $is_class = 0;
			if (ref($item_type) eq 'ARRAY') {
				$is_class = grep { $_ eq 'rdfs:Class' } @$item_type;
			} else {
				$is_class = ($item_type eq 'rdfs:Class');
			}
			if ($is_class) {
				my $label = $item->{'rdfs:label'} // $item->{'http://www.w3.org/2000/01/rdf-schema#label'};
				next unless $label;
				$label = (ref($label) eq 'ARRAY') ? $label->[0] : $label;
				$class_vocab{$label} = $item;
			}

			# Check for property definitions (e.g. items with @type 'rdf:Property')
			my $is_prop = 0;
			if (ref($item_type) eq 'ARRAY') {
				$is_prop = grep { $_ eq 'rdf:Property' } @$item_type;
			} else {
				$is_prop = ($item_type eq 'rdf:Property');
			}
			if ($is_prop) {
				my $label = $item->{'rdfs:label'} // $item->{'http://www.w3.org/2000/01/rdf-schema#label'};
				next unless $label;
				$label = (ref($label) eq 'ARRAY') ? $label->[0] : $label;
				$prop_vocab{$label} = $item;
			}
		}
	} else {
		warn "No '\@graph' key found in the vocabulary JSON.";
	}

	# Assign the populated hashes to the global variables.
	%dynamic_schema	 = %class_vocab;
	%dynamic_properties = %prop_vocab;

	warn 'Dynamic vocabulary loaded: ', scalar(keys %dynamic_schema),
		 ' classes and ', scalar(keys %dynamic_properties), ' properties found.';

	return %dynamic_schema;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=over 4

=item * Cache file is stored in the current working directory, which may cause issues with
file permissions or multiple concurrent processes

=item * No timezone support in datetime validation

=item * Cache invalidation is time-based only; no checksums or version checking

=item * Network failures during vocabulary download return empty results rather than using
stale cache

=back

=head1 SEE ALSO

=over 4

=item * L<https://schema.org/> - Schema.org structured data vocabulary

=item * L<JSON::MaybeXS> - JSON encoding/decoding

=item * L<LWP::UserAgent> - HTTP client library

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/schema-validator>

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
