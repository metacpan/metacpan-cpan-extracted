# Qiime2::Artifact

A Perl module for parsing and extracting information from QIIME 2 artifact files (`.qza` and `.qzv`).

[![Perl](https://img.shields.io/badge/perl-5.14+-brightgreen.svg)](https://dev.perl.org/)
[![CPAN version](https://img.shields.io/cpan/v/Qiime2-Artifact)](https://metacpan.org/pod/Qiime2::Artifact)

## Overview

Qiime2::Artifact provides a simple interface to work with QIIME 2 artifacts, 
allowing you to extract metadata, provenance information, and file contents from both `.qza`
(data artifacts) and `.qzv` (visualization artifacts) files.

## Installation

You can install this module via CPAN:

```bash
cpan Qiime2::Artifact
```

Or manually:

```bash
perl Makefile.PL
make
make test
make install
```

### Requirements

- Perl 5.14 or later
- UnZip 6.00 or compatible
- The following Perl modules:
  - Carp
  - Cwd
  - Term::ANSIColor
  - YAML::PP (<0.38.1 :warning:)
  - Capture::Tiny
  - File::Basename

## Usage

### Basic Usage

```perl
use Qiime2::Artifact;

# Load a QIIME 2 artifact
my $artifact = Qiime2::Artifact->new({
    filename => 'data/feature-table.qza'
});

# Get the artifact ID
my $id = $artifact->get('id');

# Check if it's a visualization
my $is_viz = $artifact->get('visualization');

# Get the QIIME 2 version used to create the artifact
my $version = $artifact->get('version');
```

### Advanced Usage

```perl
# Initialize with custom unzip path and debug mode
my $artifact = Qiime2::Artifact->new({
    filename => 'data/taxonomy.qzv',
    unzip    => '/usr/bin/unzip',  # Specify custom unzip path
    debug    => 1,                 # Enable debug output
    verbose  => 1                  # Enable verbose mode
});

# Access artifact information
my $data_files = $artifact->get('data');        # List of data files in artifact
my $parents = $artifact->get('parents');        # Parent artifacts information
my $ancestry = $artifact->get('ancestry');      # Complete artifact ancestry
my $parent_count = $artifact->get('parents_number');  # Number of parent artifacts
```

## Available Methods

### Constructor

- **new(hash_ref)**: Creates a new Qiime2::Artifact object
  - Parameters (in hash reference):
    - `filename`: Path to the artifact file (required)
    - `unzip`: Path to unzip program (optional)
    - `debug`: Enable debug mode (optional)
    - `verbose`: Enable verbose mode (optional)

### Instance Methods

- **get(key)**: Retrieves artifact attributes
  - Available keys:
    - `id`: Artifact UUID
    - `data`: Array reference of data files
    - `visualization`: Boolean indicating if artifact is visualization
    - `version`: QIIME 2 version
    - `archive`: Archive version
    - `parents`: Hash reference of parent artifacts
    - `ancestry`: Array reference of artifact lineage
    - `parents_number`: Number of parent artifacts
    - `imported`: Boolean indicating if artifact was imported

## Error Handling

The module uses Carp for error handling and will die with detailed error messages if:
- The artifact file is not found
- The unzip program is not available
- The artifact format is invalid
- Requested attributes don't exist

```perl
# Using eval for error handling
my $artifact;
eval {
    $artifact = Qiime2::Artifact->new({
        filename => 'nonexistent.qza'
    });
};
if ($@) {
    warn "Error loading artifact: $@";
}
```

## Examples

### Reading a Feature Table

```perl
use Qiime2::Artifact;
use Data::Dumper;

# Load feature table artifact
my $table = Qiime2::Artifact->new({
    filename => 'feature-table.qza'
});

# Print basic information
printf "Artifact ID: %s\n", $table->get('id');
printf "QIIME 2 version: %s\n", $table->get('version');
printf "Data files: %s\n", join(", ", @{$table->get('data')});
```

### Analyzing Visualization Artifacts

```perl
# Load taxonomy visualization
my $viz = Qiime2::Artifact->new({
    filename => 'taxonomy.qzv'
});

if ($viz->get('visualization')) {
    print "This is a visualization artifact\n";
    
    # Check for index.html
    my @files = @{$viz->get('data')};
    if (grep { $_ eq 'index.html' } @files) {
        print "Contains web visualization\n";
    }
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 

## License

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## Author

Andrea Telatin

## See Also

- [QIIME 2 Documentation](https://docs.qiime2.org/)
- [Module Wiki](https://github.com/telatin/qiime2tools/wiki/)
- [CPAN](https://metacpan.org/pod/Qiime2::Artifact)
- [qzoom documentation](https://github.com/telatin/qiime2tools/blob/master/notes/qzoom_readme.md).

It works independently from Qiime2, its meant to automate common tasks 
(e.g. extract .*biom* file and automatically converts it to .*tsv* if the `biom` tool is available).  
