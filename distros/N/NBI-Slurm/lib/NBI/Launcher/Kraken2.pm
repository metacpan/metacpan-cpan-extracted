package NBI::Launcher::Kraken2;

# =============================================================================
# NBI::Launcher::Kraken2  -  Taxonomic classification using Kraken2
#
# Reference implementation of the NBI::Launcher subclass pattern.
# Only make_command() is overridden - the base class handles everything else.
#
# Tool:   Kraken2  https://ccb.jhu.edu/software/kraken2/
# Mode:   single-end or paired-end (auto-detected from --r2 presence)
# Notes:  --threads is auto-synced from --cpus (slurm_sync).
#         Database path defaults to $KRAKEN2_DB env var, then the hardcoded path.
# =============================================================================

use strict;
use warnings;
use parent 'NBI::Launcher';
use POSIX qw(ceil);

sub new {
    my ($class) = @_;
    return $class->SUPER::new(

        name        => 'kraken2',
        description => 'Taxonomic classification of sequencing reads',
        version     => '2.0.8',

        # ── Activation ───────────────────────────────────────────────────────
        # Using HPC module here.  To switch to singularity, replace with:
        #   activate => { singularity => '/path/to/kraken2.sif' },
        activate => { module => 'kraken2/2.0.8' },

        # ── Slurm defaults ───────────────────────────────────────────────────
        # Memory is auto-calculated from the database folder size at submit time
        # (ceil(db_size_gb * 1.4) + 100 GB overhead).  The value here is used only when the
        # db path is unavailable at submission (e.g. dry-run without a real db).
        slurm_defaults => {
            queue   => 'qib-short',
            threads => 8,
            memory  => 64,        # GB fallback - overridden by db-size calc
            runtime => '24:00:00',
        },

        # ── Inputs ───────────────────────────────────────────────────────────
        inputs => [
            {   name     => 'r1',
                flag     => '-1',
                type     => 'file',
                required => 1,
                help     => 'Forward reads (or single-end FASTQ)',
            },
            {   name     => 'r2',
                flag     => '-2',
                type     => 'file',
                required => 0,
                help     => 'Reverse reads - omit for single-end mode',
            },
        ],

        # ── Parameters ───────────────────────────────────────────────────────
        params => [
            {   name        => 'db',
                flag        => '--db',
                type        => 'dir',
                required    => 1,
                default     => '/qib/databases/kraken2/standard',
                default_env => 'KRAKEN2_DB',
                help        => 'Kraken2 database directory',
            },
            {   name    => 'confidence',
                flag    => '--confidence',
                type    => 'float',
                default => 0.0,
                help    => 'Confidence score threshold (0.0–1.0)',
            },
            # slurm_sync: not shown in --help; value comes from --cpus
            {   name       => 'threads',
                flag       => '--threads',
                type       => 'int',
                slurm_sync => 'threads',
            },
        ],

        # ── Outputs ──────────────────────────────────────────────────────────
        outputs => [
            {   name     => 'report',
                flag     => '--report',
                pattern  => '{sample}.k2report',
                required => 1,
                help     => 'Per-taxon classification report',
            },
            {   name     => 'output',
                flag     => '--output',
                pattern  => '{sample}.k2out',
                required => 0,
                help     => 'Per-read classification output',
            },
        ],

        outdir  => { flag => '--outdir', short => '-o', required => 1 },
        scratch => { use_tmpdir => 1, cleanup_on_failure => 1 },
    );
}

# ── make_command(%args) ───────────────────────────────────────────────────────
# Builds the kraken2 invocation.  Handles single-end and paired-end modes.
#
# %args keys used here:
#   r1, r2        - input FASTQ paths (r2 undef for single-end)
#   db            - database directory
#   confidence    - confidence threshold
#   threads       - from slurm_sync
#   sample        - derived sample name
#
# Output paths reference $SCRATCH (shell variable, not a Perl variable).
sub make_command {
    my ($self, %args) = @_;

    my $pe = defined $args{r2}
        ? "--paired -1 \"$args{r1}\" -2 \"$args{r2}\""
        : "\"$args{r1}\"";

    return join(" \\\n    ",
        'kraken2',
        "--threads $args{threads}",
        "--db \"$args{db}\"",
        "--confidence $args{confidence}",
        '--report "$SCRATCH/' . "$args{sample}.k2report\"",
        '--output "$SCRATCH/' . "$args{sample}.k2out\"",
        $pe,
    );
}

# ── build(%args) ─────────────────────────────────────────────────────────────
# Override to auto-calculate memory from the Kraken2 database folder size
# before handing off to the base class.  Only applies when --mem is not
# explicitly set on the command line (slurm_memory not in %args).
sub build {
    my ($self, %args) = @_;

    unless (defined $args{slurm_memory}) {
        # Resolve the db path the same way validate() does: arg → env → default
        my $db = $args{db}
              // $ENV{KRAKEN2_DB}
              // $self->{slurm_defaults}{db}
              // '/qib/databases/kraken2/standard';

        if (-d $db) {
            my $size_gb = _folder_size_gb($db);
            if ($size_gb > 0) {
                # 40% contingency + 100 GB fixed overhead, rounded up
                $args{slurm_memory} = ceil($size_gb * 1.4) + 100;
                warn "[nbilaunch] kraken2: db is ${size_gb}GB, "
                   . "requesting $args{slurm_memory}GB RAM\n";
            }
        }
    }

    return $self->SUPER::build(%args);
}

# ── _folder_size_gb($dir) ─────────────────────────────────────────────────────
# Returns the total disk usage of $dir in GB using 'du -sk'.
# Returns 0 if du fails or the path is inaccessible.
sub _folder_size_gb {
    my ($dir) = @_;
    # du -sk: POSIX-portable, output in kilobytes
    # Use single-quoted shell string to avoid backslash issues; escape only ' in path
    (my $safe = $dir) =~ s/'/'"'"'/g;
    my $out = `du -sk '$safe' 2>/dev/null`;
    return 0 unless defined $out && $out =~ /^(\d+)/;
    return $1 / (1024 * 1024);   # KB → GB
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NBI::Launcher::Kraken2

=head1 VERSION

version 0.20.0

=head1 SYNOPSIS

  # Dry-run (default): print generated script
  nbilaunch kraken2 --r1 sample_R1.fq.gz --r2 sample_R2.fq.gz \
      --outdir results/kraken2

  # Submit to Slurm
  nbilaunch kraken2 --r1 sample_R1.fq.gz --outdir results/kraken2 --run

=head1 DESCRIPTION

Reference implementation of the L<NBI::Launcher> subclass pattern.
Wraps Kraken2 for paired-end or single-end taxonomic classification.
Paired-end mode is selected automatically when C<--r2> is provided.

The database path defaults to C<$KRAKEN2_DB> (environment variable) then
C</qib/databases/kraken2/standard>.  Thread count is synced from C<--cpus>.

=head1 NAME

NBI::Launcher::Kraken2 - Taxonomic classification launcher using Kraken2

=head1 METHODS

=head2 new()

Construct the Kraken2 launcher spec.  No arguments - all configuration is
embedded in the constructor body.  Returns a blessed C<NBI::Launcher::Kraken2>
object ready for C<build()>.

=head2 make_command(%args)

Returns the Kraken2 shell invocation string for embedding in the job script.

Key C<%args> consumed here:

=over 4

=item * B<r1>, B<r2> - input FASTQ paths (C<r2> omitted for single-end)

=item * B<db> - database directory

=item * B<confidence> - confidence score threshold

=item * B<threads> - injected from C<--cpus> via C<slurm_sync>

=item * B<sample> - derived sample name (used for output filenames)

=back

Output files reference C<$SCRATCH> (a shell variable set by the generated
script) rather than an absolute path.

=head2 build(%args)

Override of L<NBI::Launcher/build> that auto-calculates the Slurm memory
request from the Kraken2 database folder size before delegating to the base
class.  The calculation is C<ceil(db_size_gb * 1.4) + 100> GB (40% headroom
plus a 100 GB fixed overhead).  The auto-calculated value is used only when
C<--mem> is not explicitly supplied on the command line.

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
