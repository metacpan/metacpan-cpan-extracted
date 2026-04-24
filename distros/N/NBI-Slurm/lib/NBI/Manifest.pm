package NBI::Manifest;
#ABSTRACT: Provenance record for a single nbilaunch job run
#
# NBI::Manifest - Reads and writes JSON provenance records for nbilaunch.
#
# DESCRIPTION:
#   Serialises every input, parameter, output, and Slurm resource used by a
#   single launcher invocation to a JSON file that lives alongside the results.
#   Written in two phases:
#     1. At submission (by nbilaunch):  status "submitted", no job ID yet.
#     2. At job end (by injected shell): status "success" or "failure",
#        exit code, completion time, and checksums are patched in.
#
#   The on-disk format uses JSON::PP with canonical key ordering so that
#   diffs between runs are clean.
#
# RELATIONSHIPS:
#   - Created by NBI::Launcher->build() and written by bin/nbilaunch.
#   - The injected shell function _nbi_manifest_update patches the file
#     in-place using a perl one-liner (no jq dependency).
#   - Complex launchers can chain jobs via NBI::Manifest->load() to read
#     a previous run's output paths.
#

use 5.012;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP;
use POSIX qw(strftime);

$NBI::Manifest::VERSION = $NBI::Slurm::VERSION;

# Fields serialised to JSON (in this order, for readability).
# The internal _path field is excluded.
my @JSON_FIELDS = qw(
    tool tool_version launcher_version nbi_slurm_version
    submitted_at completed_at
    slurm_job_id slurm_queue slurm_cpus slurm_mem_gb
    host user status exit_code sample
    inputs params outputs
    outdir scratch checksums script
);

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    # Required fields
    for my $f (qw(tool sample outdir)) {
        confess "ERROR NBI::Manifest: missing required field '$f'\n"
            unless defined $args{$f};
    }

    # Populate all known fields with defaults where sensible
    $self->{tool}               = $args{tool};
    $self->{tool_version}       = $args{tool_version}       // 'unknown';
    $self->{launcher_version}   = $args{launcher_version}   // '0.1.0';
    $self->{nbi_slurm_version}  = $args{nbi_slurm_version}  // ($NBI::Slurm::VERSION // 'unknown');
    $self->{submitted_at}       = $args{submitted_at}
                                  // strftime("%Y-%m-%dT%H:%M:%SZ", gmtime());
    $self->{completed_at}       = $args{completed_at};      # undef until job ends
    $self->{slurm_job_id}       = $args{slurm_job_id};      # undef until submitted
    $self->{slurm_queue}        = $args{slurm_queue}        // 'unknown';
    $self->{slurm_cpus}         = $args{slurm_cpus}         // 1;
    $self->{slurm_mem_gb}       = $args{slurm_mem_gb}       // 0;
    $self->{host}               = $args{host}
                                  // $ENV{HOSTNAME}
                                  // do { chomp(my $h = `hostname 2>/dev/null`); $h } // 'unknown';
    $self->{user}               = $args{user}               // $ENV{USER} // 'unknown';
    $self->{status}             = $args{status}             // 'submitted';
    $self->{exit_code}          = $args{exit_code};         # undef until job ends
    $self->{sample}             = $args{sample};
    $self->{inputs}             = $args{inputs}             // {};
    $self->{params}             = $args{params}             // {};
    $self->{outputs}            = $args{outputs}            // {};
    $self->{outdir}             = $args{outdir};
    $self->{scratch}            = $args{scratch}            // '';
    $self->{checksums}          = $args{checksums}          // {};
    $self->{script}             = $args{script}             // '';

    # Internal: path where this manifest lives on disk (not serialised)
    $self->{_path}              = $args{_path};

    return $self;
}

# ── write($path) ──────────────────────────────────────────────────────────────
# Serialise to JSON and write to $path. Records _path for future update() calls.
sub write {
    my ($self, $path) = @_;
    confess "ERROR NBI::Manifest::write: path required\n" unless defined $path;

    # Build the hash to serialise (JSON_FIELDS order, excluding _path)
    my %data;
    for my $f (@JSON_FIELDS) {
        $data{$f} = $self->{$f};
    }

    my $json = JSON::PP->new->utf8->pretty->canonical->encode(\%data);

    open(my $fh, '>', $path)
        or confess "ERROR NBI::Manifest::write: cannot open '$path': $!\n";
    print $fh $json;
    close $fh;

    $self->{_path} = $path;
    return $self;
}

# ── load($path) ───────────────────────────────────────────────────────────────
# Parse an existing manifest JSON file and return a blessed object.
sub load {
    my ($class, $path) = @_;
    confess "ERROR NBI::Manifest::load: path required\n" unless defined $path;
    confess "ERROR NBI::Manifest::load: '$path' not found\n" unless -f $path;

    open(my $fh, '<', $path)
        or confess "ERROR NBI::Manifest::load: cannot open '$path': $!\n";
    my $raw = do { local $/; <$fh> };
    close $fh;

    my $data = JSON::PP->new->utf8->decode($raw);
    my $self  = bless $data, $class;
    $self->{_path} = $path;
    return $self;
}

# ── output($name) ─────────────────────────────────────────────────────────────
# Returns the absolute path of a named output file.
# Useful for chaining launchers: read a previous manifest to get output paths.
sub output {
    my ($self, $name) = @_;
    confess "ERROR NBI::Manifest::output: name required\n" unless defined $name;
    my $filename = $self->{outputs}{$name}
        or confess "ERROR NBI::Manifest::output: no output named '$name'\n";
    return "$self->{outdir}/$filename";
}

# ── update(%changes) ──────────────────────────────────────────────────────────
# Merge %changes into the object and rewrite to the stored _path.
# Used by nbilaunch after submission to record the Slurm job ID.
sub update {
    my ($self, %changes) = @_;
    confess "ERROR NBI::Manifest::update: no path known - call write() first\n"
        unless defined $self->{_path};

    for my $k (keys %changes) {
        $self->{$k} = $changes{$k};
    }
    $self->write($self->{_path});
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NBI::Manifest - Provenance record for a single nbilaunch job run

=head1 VERSION

version 0.20.1

=head1 SYNOPSIS

  use NBI::Manifest;

  # Create at submission time
  my $m = NBI::Manifest->new(
      tool        => 'kraken2',
      tool_version => '2.1.0',
      sample      => 'sample1',
      outdir      => '/results/kraken2',
      inputs      => { r1 => '/data/s_R1.fq.gz', r2 => '/data/s_R2.fq.gz' },
      params      => { db => '/db/kraken2', threads => 8 },
      outputs     => { report => 'sample1.k2report' },
      slurm_queue => 'short',
      slurm_cpus  => 8,
      slurm_mem_gb => 32,
  );
  $m->write('/results/kraken2/.nbilaunch/sample1.manifest.json');

  # After submission: record job ID
  $m->update(slurm_job_id => 4821934);

  # In a downstream launcher: chain from a previous result
  my $prev = NBI::Manifest->load('/results/kraken2/.nbilaunch/sample1.manifest.json');
  my $report = $prev->output('report');   # => '/results/kraken2/sample1.k2report'

=head1 NAME

NBI::Manifest - Provenance record for a single nbilaunch job run

=head1 METHODS

=head2 new(%fields)

Create a manifest in memory. Required: C<tool>, C<sample>, C<outdir>.

=head2 write($path)

Serialise to JSON at C<$path>. Records the path for future C<update()> calls.

=head2 load($path)

Parse an existing manifest JSON file.

=head2 output($name)

Return the absolute path of a named output: C<outdir/outputs{name}>.

=head2 update(%changes)

Merge changes into the object and rewrite to disk.

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
