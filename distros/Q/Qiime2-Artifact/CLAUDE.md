# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Perl module for parsing and extracting information from QIIME 2 artifact files (.qza and .qzv). The core module is `Qiime2::Artifact`, which provides object-oriented access to QIIME 2 artifacts stored as ZIP files with specific internal structure.

## Build & Test Commands

- Run all tests: `prove -l t/`
- Run single test: `prove -l t/10_basic_test.t`
- Run with verbose output: `prove -lv t/`
- Build distribution: `dzil build`
- Test distribution: `dzil test`
- Install dependencies: `dzil listdeps | cpanm`

## Architecture

### Core Module: lib/Qiime2/Artifact.pm

The main `Qiime2::Artifact` module uses `unzip` to extract and parse QIIME 2 artifact files without fully extracting them. Key architecture points:

- **Artifact Structure**: QIIME 2 artifacts are ZIP files with structure: `{uuid}/data/`, `{uuid}/provenance/`, `{uuid}/VERSION`
- **Lazy Loading**: Artifacts are parsed on initialization via `_read_artifact()`, which uses `unzip -t` to list contents
- **Provenance Chain**: The module recursively parses provenance by reading `action/action.yaml` files for each parent artifact
- **YAML Parsing**: Uses YAML::PP (version 0.38) for parsing metadata and action files
- **Ancestry Tracking**: `_getAncestry()` builds a multi-level array of parent artifact UUIDs

### Main Script: bin/qzoom

Command-line tool built on top of the module, providing:
- Artifact inspection (`--info`)
- Bibliography extraction (`--cite`, `--bibtex`)
- Data file extraction (`--extract`, `--data`)
- Automatic BIOM to TSV conversion if `biom` tool available

### Key Methods

- `new({filename => $path})`: Constructor, loads and parses artifact
- `get($key)`: Accessor for artifact attributes (id, version, data, parents, ancestry, etc.)
- `extract_file($data_file, $target_path)`: Extract specific file from artifact's data directory
- `get_bib()`: Extract bibliography from provenance/citations.bib
- `_getArtifactText($internal_path)`: Extract and return text content using `unzip -p`

## Code Style Guidelines

- Use strict and warnings
- Minimum Perl version: 5.014
- Error handling: Use `Carp::confess` for critical errors
- Package variables use `$Package::Name::VARIABLE` convention
- Use `autodie` for automatic die on failures
- Private methods prefixed with underscore (`_method_name`)
- Method parameters received via array unpacking: `my ($self, $args) = @_;`
- Parameters passed to constructors as hashref
- Use `Term::ANSIColor` for error/debug output formatting
- Comprehensive POD documentation at end of modules
- Always return true (1) at end of module
- Indent with spaces (not tabs)

## Testing

Tests are in `t/` directory and use `Test::More`. Test data artifacts are in `data/` directory. Tests verify:
- Basic loading (t/11_load.t)
- Artifact validation (t/11_not_a_valid_artifact.t, etc.)
- Attribute parsing (t/12_basic_attributes.t)
- Provenance tracking (t/13_provenance.t)
- Visualization detection (t/15_viz.t)
- Bibliography extraction (t/16_bib.t)

## Dependencies

Critical dependency: YAML::PP must be version 0.38 (specified in dist.ini). Later versions may break compatibility.

External binary dependency: `unzip` (version 6.00+ recommended) must be available in PATH or specified via constructor.
