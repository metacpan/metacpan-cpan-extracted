# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NBI-Slurm is a Perl-based package that provides a user-friendly interface for SLURM (Simple Linux Utility for Resource Management) clusters. It includes both a Perl module library and command-line utilities for job management on HPC systems.

## Architecture

### Core Perl Modules (lib/NBI/)
- **NBI::Slurm** - Main module with utilities and format strings for SLURM interaction
- **NBI::Job** - Represents a job to be submitted to SLURM with methods like `run()` and `view()`
- **NBI::Opts** - Manages SLURM options (queue, threads, memory, dependencies)
- **NBI::Queue** - Represents the current SLURM queue state
- **NBI::QueuedJob** - Represents individual jobs in the queue

### Command Line Tools (bin/)
The package provides these binaries for cluster interaction:
- `runjob` - Submit jobs with resource specifications
- `lsjobs` - List/delete user jobs in queue
- `waitjobs` - Wait for jobs matching a pattern to finish
- `whojobs` - Show cluster usage by user
- `shelf` - List installed packages on the cluster
- `session` - Start interactive SLURM sessions
- `make_image_from_bioconda` - Generate Singularity images from bioconda
- `make_package` - Install packages from Singularity images
- `rm_package` - Remove legacy packages

## Development Commands

### Testing
```bash
# Run all tests
prove -rv t/

# Run specific test categories
prove t/01-*.t          # Basic/unit tests
prove t/10-hpc.t        # HPC-specific tests (requires SLURM)
prove t/20-intensive.t  # Intensive tests
prove xt/               # Author/release tests
```

### Building and Distribution
This project uses Dist::Zilla for packaging:
```bash
# Build the distribution
dzil build

# Test the distribution
dzil test

# Release (requires proper credentials)
dzil release
```

### Code Quality
```bash
# Run POD tests
prove xt/release/00-pod.t

# Check POD coverage
prove xt/release/01-pod-coverage.t

# Verify minimum standards
prove xt/release/03-minimum-standards.t
```

## Configuration

The system looks for configuration at `~/.nbislurm.config` for default settings including:
- Email addresses
- Default queues
- Interactive session parameters
- Other user preferences

## Key Dependencies

Runtime requirements (from dist.ini):
- Perl 5.016+
- Data::Dumper, FindBin, Carp (core modules)
- Capture::Tiny 0.40+
- JSON::PP, Text::ASCIITable 0.22+
- Storable

## Testing Structure

- `t/01-*.t` - Basic functionality and unit tests
- `t/10-hpc.t` - Tests requiring actual SLURM environment
- `t/20-intensive.t` - Resource-intensive tests
- `xt/` - Author and release tests (POD, coverage, standards)

Tests in `10-hpc.t` and higher require an actual SLURM environment and may be skipped on non-Linux systems.