package NBI::Launcher::RemovePrimers;

# =============================================================================
# NBI::Launcher::RemovePrimers  -  Primer removal using cutadapt (paired-end)
#
# PACKAGED DEMO launcher. To customise for your project, copy to:
#   ./launchers/remove-primers.pm          (project-local, highest priority)
#   ~/.nbi/launchers/remove-primers.pm     (user-level)
#
# The package declaration must remain NBI::Launcher::RemovePrimers regardless
# of where the file lives (nbilaunch uses the package name internally).
#
# Tool:   cutadapt  https://cutadapt.readthedocs.io
# Mode:   paired-end only
# Notes:  --discard-untrimmed is hardcoded (drop pairs with no primer found)
#         Primer reverse complements are computed in Perl - no seqfu needed.
#         IUPAC degenerate bases are fully supported in primer sequences.
# =============================================================================

use strict;
use warnings;
use parent 'NBI::Launcher';

# ── IUPAC reverse complement ──────────────────────────────────────────────────
# Complement table covering all standard IUPAC ambiguity codes.
# Add any custom codes here if your primers use non-standard notation.
my %IUPAC_COMP = (
    A => 'T', T => 'A', C => 'G', G => 'C',   # unambiguous bases
    R => 'Y', Y => 'R',   # R = A|G    Y = C|T
    S => 'S',              # S = C|G    self-complementary
    W => 'W',              # W = A|T    self-complementary
    K => 'M', M => 'K',   # K = G|T    M = A|C
    B => 'V', V => 'B',   # B = C|G|T  V = A|C|G
    D => 'H', H => 'D',   # D = A|G|T  H = A|C|T
    N => 'N',              # N = any
);

sub _rc {
    my ($seq) = @_;
    $seq = uc $seq;
    $seq = reverse $seq;
    $seq =~ s/([ACGTRYWSKMBVDHN])/$IUPAC_COMP{$1} \/\/ $1/ge;
    return $seq;
}
# ─────────────────────────────────────────────────────────────────────────────

sub new {
    my ($class) = @_;
    return $class->SUPER::new(

        name        => 'remove-primers',
        description => 'Remove primers from paired-end reads using cutadapt',
        version     => '3.3',

        # ── Activation ───────────────────────────────────────────────────────
        # Option A (used here): Singularity image.
        #   The path can be overridden at submission time via $CUTADAPT_IMG.
        #
        # Option B: HPC module - swap the activate block for:
        #   activate => { module => 'cutadapt/3.3' },
        #
        # Option C: conda - swap for:
        #   activate => { conda => 'cutadapt-env' },
        activate => {
            singularity => $ENV{CUTADAPT_IMG}
                        // '/nbi/software/testing/GMH-Tools/images/cutadapt~3.3',
        },

        # ── Slurm defaults ───────────────────────────────────────────────────
        # All of these can be overridden on the command line:
        #   --queue / --mem / --cpus / --runtime
        slurm_defaults => {
            queue   => 'qib-short',
            threads => 8,
            memory  => 12,        # GB; cutadapt is mostly I/O-bound
            runtime => '04:00:00',
        },

        # ── Inputs ───────────────────────────────────────────────────────────
        inputs => [
            {   name     => 'r1',
                flag     => '-1',
                type     => 'file',
                required => 1,
                help     => 'Forward reads (R1) FASTQ[.gz] - also used to derive sample name',
            },
            {   name     => 'r2',
                flag     => '-2',
                type     => 'file',
                required => 1,
                help     => 'Reverse reads (R2) FASTQ[.gz]',
            },
        ],

        # ── Parameters ───────────────────────────────────────────────────────
        params => [
            {   name     => 'fwd_primer',
                flag     => '-f',
                type     => 'string',
                required => 1,
                help     => 'Forward primer sequence (IUPAC degenerate bases supported)',
            },
            {   name     => 'rev_primer',
                flag     => '-r',
                type     => 'string',
                required => 1,
                help     => 'Reverse primer sequence (IUPAC degenerate bases supported)',
            },
            # slurm_sync: --threads is not exposed as a user flag;
            # it is automatically set to match --cpus (Slurm --cpus-per-task).
            {   name      => 'threads',
                flag      => '-j',
                type      => 'int',
                slurm_sync => 'threads',
            },
        ],

        # ── Outputs ──────────────────────────────────────────────────────────
        # {sample} is derived from the R1 basename by stripping known suffixes:
        #   _R1, _1, .fastq, .fq, .gz
        # Override with --sample-name STR on the nbilaunch command line.
        outputs => [
            {   name     => 'r1_trimmed',
                pattern  => '{sample}_R1.fq.gz',
                required => 1,
                help     => 'Primer-trimmed forward reads',
            },
            {   name     => 'r2_trimmed',
                pattern  => '{sample}_R2.fq.gz',
                required => 1,
                help     => 'Primer-trimmed reverse reads',
            },
            {   name     => 'report',
                pattern  => '{sample}.cutadapt.txt',
                required => 0,
                help     => 'cutadapt run report (stdout)',
            },
            {   name     => 'log',
                pattern  => '{sample}.cutadapt.log',
                required => 0,
                help     => 'cutadapt stderr log',
            },
        ],

        outdir  => { flag => '--outdir', short => '-o', required => 1 },

        # use_tmpdir: write to $TMPDIR (fast local disk) during the job,
        # then promote outputs to outdir on success.
        scratch => { use_tmpdir => 1, cleanup_on_failure => 1 },
    );
}

# ── make_command ──────────────────────────────────────────────────────────────
# Builds the cutadapt shell invocation embedded in the generated job script.
#
# %args contains all resolved values at submission time:
#   $args{r1}, $args{r2}           absolute paths to input files
#   $args{fwd_primer}              forward primer string (may contain IUPAC)
#   $args{rev_primer}              reverse primer string (may contain IUPAC)
#   $args{threads}                 injected from Slurm --cpus-per-task
#   $args{sample}                  derived sample name (or --sample-name value)
#   $args{scratch}                 scratch directory (managed by base class)
#
# To customise the cutadapt flags (e.g. add --minimum-length, change error
# rate, etc.) edit the join() call below.
# ─────────────────────────────────────────────────────────────────────────────
sub make_command {
    my ($self, %args) = @_;

    # Reverse complements of both primers (IUPAC-aware, computed at submit time)
    my $fwd_rc = _rc($args{fwd_primer});
    my $rev_rc = _rc($args{rev_primer});

    # Linked-adapter notation (cutadapt §Linked adapters):
    #   R1 gets  fwd_primer...rev_rc   (5'-anchored fwd, 3'-anchored rev_rc)
    #   R2 gets  rev_primer...fwd_rc   (5'-anchored rev, 3'-anchored fwd_rc)
    my $adapter_r1 = "$args{fwd_primer}...$rev_rc";
    my $adapter_r2 = "$args{rev_primer}...$fwd_rc";

    # Outputs land in scratch; base class moves them to outdir after validation
    my $out_r1 = "\$SCRATCH/$args{sample}_R1.fq.gz";
    my $out_r2 = "\$SCRATCH/$args{sample}_R2.fq.gz";
    my $report  = "\$SCRATCH/$args{sample}.cutadapt.txt";
    my $log     = "\$SCRATCH/$args{sample}.cutadapt.log";

    # Singularity prefix - populated when activate => { singularity => ... }.
    # Empty string when using module or conda activation (handled by the
    # activation_lines() section of the script instead).
    my $img    = $self->{activate}{singularity} // '';
    my $prefix = $img ? "singularity exec $img " : '';

    return join(" \\\n    ",
        "${prefix}cutadapt",
        "-j $args{threads}",
        "-a $adapter_r1",         # linked adapter for R1
        "-A $adapter_r2",         # linked adapter for R2
        '--discard-untrimmed',    # drop pairs where no primer is detected
        "-o $out_r1",
        "-p $out_r2",
        $args{r1},
        $args{r2},
    ) . " \\\n    > $report 2> $log";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NBI::Launcher::RemovePrimers

=head1 VERSION

version 0.19.0

=head1 SYNOPSIS

  # Dry-run (default): print generated script
  nbilaunch remove-primers \
      --r1 sample_R1.fq.gz --r2 sample_R2.fq.gz \
      --fwd-primer GTGYCAGCMGCCGCGGTAA \
      --rev-primer GGACTACNVGGGTWTCTAAT \
      --outdir results/trimmed

  # Submit to Slurm
  nbilaunch remove-primers ... --run

=head1 DESCRIPTION

Packaged demo launcher that trims primers from paired-end FASTQ files using
cutadapt in linked-adapter mode (C<fwd...rev_rc> on R1, C<rev...fwd_rc> on R2).
Reads without a detectable primer are discarded (C<--discard-untrimmed>).

Primer reverse complements are computed in Perl at submission time - no
C<seqfu> or other runtime dependency needed.  IUPAC degenerate bases are
fully supported.

To customise this launcher for your project, copy the file to
C<./launchers/remove-primers.pm> or C<~/.nbi/launchers/remove-primers.pm>
and edit freely.  The package declaration must remain
C<NBI::Launcher::RemovePrimers> regardless of the file's location.

=head1 NAME

NBI::Launcher::RemovePrimers - Primer removal from paired-end reads using cutadapt

=head1 METHODS

=head2 new()

Construct the RemovePrimers launcher spec.  No arguments - all configuration
is embedded in the constructor body (activation image, Slurm defaults, inputs,
params, outputs).  Returns a blessed C<NBI::Launcher::RemovePrimers> object
ready for C<build()>.

=head2 make_command(%args)

Returns the cutadapt shell invocation string for embedding in the job script.
Reverse complements of both primers are computed here (IUPAC-aware) so that
the exact command is visible in the saved script.

Key C<%args> consumed here:

=over 4

=item * B<r1>, B<r2> - absolute paths to input FASTQ files

=item * B<fwd_primer>, B<rev_primer> - primer sequences (IUPAC bases supported)

=item * B<threads> - injected from C<--cpus> via C<slurm_sync>

=item * B<sample> - derived sample name (used for output filenames)

=back

Output files reference C<$SCRATCH> (a shell variable set by the generated
script) rather than an absolute path.

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
