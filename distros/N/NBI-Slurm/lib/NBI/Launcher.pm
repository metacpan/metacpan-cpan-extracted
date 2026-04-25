package NBI::Launcher;
#ABSTRACT: Base class for nbilaunch tool wrappers
#
# NBI::Launcher - Declarative base class for HPC tool launchers.
#
# DESCRIPTION:
#   Every tool wrapper inherits from this class.  Subclasses provide:
#     - A constructor that calls SUPER::new() with the launcher spec
#     - make_command(%args) - the tool invocation string (only override needed
#       for most tools)
#
#   The base class provides everything else:
#     - Spec storage and introspection (arg_spec, input_mode, sample_name)
#     - Input / param / output validation
#     - Shell script generation (generate_script)
#     - NBI::Job construction and NBI::Manifest creation (build)
#
# RELATIONSHIPS:
#   - Subclasses live in NBI::Launcher::*, ./launchers/, or ~/.nbi/launchers/.
#   - build() returns (NBI::Job, NBI::Manifest) - consumed by bin/nbilaunch.
#   - NBI::Pipeline wraps multiple NBI::Job objects for multi-step launchers.
#

use 5.012;
use strict;
use warnings;
use Carp qw(confess croak);
use File::Basename qw(basename);
use Cwd qw(realpath);
use POSIX qw(strftime);

$NBI::Launcher::VERSION = $NBI::Slurm::VERSION;

# ── Constructor ───────────────────────────────────────────────────────────────
# All parameters are named (not the -param style used by NBI::Opts/NBI::Job).
#
# Required: name, activate, inputs, outputs, outdir
# Optional: description, version, slurm_defaults, params, scratch, success_check
sub new {
    my ($class, %args) = @_;

    # ── Validate activate spec ────────────────────────────────────────────────
    my $activate = $args{activate}
        or confess "ERROR NBI::Launcher: 'activate' is required\n";
    ref $activate eq 'HASH'
        or confess "ERROR NBI::Launcher: 'activate' must be a hashref\n";
    my @act_keys = keys %$activate;
    confess "ERROR NBI::Launcher: 'activate' must have exactly one key (module|singularity|conda), got: @act_keys\n"
        unless @act_keys == 1 && grep { /^(module|singularity|conda)$/ } @act_keys;

    # ── Validate slurm_defaults ───────────────────────────────────────────────
    my $slurm_defaults = $args{slurm_defaults} // {};
    for my $k (keys %$slurm_defaults) {
        confess "ERROR NBI::Launcher: unknown slurm_defaults key '$k'\n"
            unless $k =~ /^(queue|threads|memory|runtime)$/;
    }

    my $self = bless {}, $class;

    $self->{name}          = $args{name}        or confess "ERROR NBI::Launcher: 'name' is required\n";
    $self->{description}   = $args{description} // '';
    $self->{version}       = $args{version}     // 'unknown';
    $self->{activate}      = $activate;
    $self->{slurm_defaults} = {
        queue   => 'qib-short',
        threads => 1,
        memory  => 4,       # GB
        runtime => '01:00:00',
        %$slurm_defaults,   # caller overrides
    };
    $self->{inputs}        = $args{inputs}   // [];
    $self->{params}        = $args{params}   // [];
    $self->{outputs}       = $args{outputs}  // [];
    $self->{outdir}        = $args{outdir}   // { flag => '--outdir', short => '-o', required => 1 };
    $self->{scratch}       = $args{scratch}  // { use_tmpdir => 0, cleanup_on_failure => 0 };
    $self->{success_check} = $args{success_check};  # optional coderef

    return $self;
}

# ── activation_lines() ────────────────────────────────────────────────────────
# Returns the shell snippet that loads the tool environment.
# For singularity: returns "" because the prefix goes into make_command()
# via singularity_prefix().
sub activation_lines {
    my ($self) = @_;
    my ($type, $value) = each %{ $self->{activate} };

    if ($type eq 'module') {
        return "module load $value\n";
    } elsif ($type eq 'conda') {
        # Use 'source activate' for broadest HPC compatibility.
        # On systems with conda >= 4.4, 'conda activate' also works.
        return "source activate $value\n";
    } elsif ($type eq 'singularity') {
        # Singularity prefix is applied per-command in make_command()
        # via singularity_prefix().  Nothing needed here.
        return '';
    }
    return '';
}

# ── singularity_prefix() ──────────────────────────────────────────────────────
# Helper for make_command() overrides: returns "singularity exec $image "
# when the launcher uses singularity activation, empty string otherwise.
# Subclass make_command() calls this and prepends it to the tool invocation.
sub singularity_prefix {
    my ($self) = @_;
    my $img = $self->{activate}{singularity};
    return defined $img ? "singularity exec $img " : '';
}

# ── sample_name(%args) ────────────────────────────────────────────────────────
# Derives the sample name from the first file-type required input (usually r1).
# Strips known FASTQ extensions in order: .gz .fastq .fq _R1 _R2 _1 _2
# Override with --sample-name on the nbilaunch command line.
sub sample_name {
    my ($self, %args) = @_;

    # Explicit override takes priority
    return $args{sample_name} if defined $args{sample_name};

    # Find the first required file-type input
    my $source;
    for my $inp (@{ $self->{inputs} }) {
        if (($inp->{type} // '') eq 'file' && ($inp->{required} // 0)) {
            $source = $args{ $inp->{name} };
            last if defined $source;
        }
    }
    confess "ERROR NBI::Launcher ($self->{name}): cannot derive sample name - no file input found\n"
        unless defined $source;

    my $name = basename($source);
    # Strip extensions from right to left
    $name =~ s/\.gz$//i;
    $name =~ s/\.(fastq|fq)$//i;
    $name =~ s/_R[12]$//;
    $name =~ s/_[12]$//;
    return $name;
}

# ── input_mode(%args) ────────────────────────────────────────────────────────
# Returns "paired" if both r1 and r2 are defined, "single" otherwise.
# Subclasses may override for tools with different pairing logic.
sub input_mode {
    my ($self, %args) = @_;
    return (defined $args{r1} && defined $args{r2}) ? 'paired' : 'single';
}

# ── arg_spec() ────────────────────────────────────────────────────────────────
# Returns the full CLI surface of this launcher for nbilaunch to use when
# generating --help text and parsing command-line arguments.
# slurm_sync params are excluded (they are derived, not user-settable).
sub arg_spec {
    my ($self) = @_;
    return {
        name        => $self->{name},
        description => $self->{description},
        version     => $self->{version},
        activate    => $self->{activate},
        inputs      => [ grep { !$_->{slurm_sync} } @{ $self->{inputs}  } ],
        params      => [ grep { !$_->{slurm_sync} } @{ $self->{params}  } ],
        outputs     => $self->{outputs},
        outdir      => $self->{outdir},
        slurm_defaults => $self->{slurm_defaults},
    };
}

# ── validate(%args) ───────────────────────────────────────────────────────────
# Dies with a helpful message if required inputs/params are missing or if
# file/dir values do not exist on disk.
sub validate {
    my ($self, %args) = @_;

    # Check inputs
    for my $inp (@{ $self->{inputs} }) {
        next if $inp->{slurm_sync};
        my $name = $inp->{name};
        my $val  = $args{$name};

        if ($inp->{required} && !defined $val) {
            confess "ERROR NBI::Launcher ($self->{name}): missing required input '--$name'\n";
        }
        next unless defined $val;

        my $type = $inp->{type} // 'string';
        if ($type eq 'file' && !-f $val) {
            confess "ERROR NBI::Launcher ($self->{name}): input '$name' - file not found: $val\n";
        } elsif ($type eq 'dir' && !-d $val) {
            confess "ERROR NBI::Launcher ($self->{name}): input '$name' - directory not found: $val\n";
        }
    }

    # Check params (with default_env and default fallback)
    for my $p (@{ $self->{params} }) {
        next if $p->{slurm_sync};
        my $name = $p->{name};
        my $val  = $args{$name};

        # Try default_env, then default
        if (!defined $val && $p->{default_env}) {
            $val = $ENV{ $p->{default_env} };
        }
        $val //= $p->{default};

        if ($p->{required} && !defined $val) {
            confess "ERROR NBI::Launcher ($self->{name}): missing required param '--$name'\n";
        }
        next unless defined $val;

        my $type = $p->{type} // 'string';
        if ($type eq 'int' && $val !~ /^\d+$/) {
            confess "ERROR NBI::Launcher ($self->{name}): param '$name' must be an integer, got: $val\n";
        } elsif ($type eq 'float' && $val !~ /^[\d.]+$/) {
            confess "ERROR NBI::Launcher ($self->{name}): param '$name' must be a number, got: $val\n";
        } elsif ($type eq 'file' && !-f $val) {
            confess "ERROR NBI::Launcher ($self->{name}): param '$name' - file not found: $val\n";
        } elsif ($type eq 'dir' && !-d $val) {
            confess "ERROR NBI::Launcher ($self->{name}): param '$name' - directory not found: $val\n";
        }
    }

    # Check outdir is provided
    if ($self->{outdir}{required} && !defined $args{outdir}) {
        confess "ERROR NBI::Launcher ($self->{name}): missing required '--outdir'\n";
    }

    return 1;
}

# ── make_command(%args) ───────────────────────────────────────────────────────
# Returns the tool invocation string to embed in the job script.
# Subclasses SHOULD override this method.
# The default implementation raises an error - every launcher needs a command.
#
# %args contains all resolved inputs, params, and derived keys:
#   $args{sample}    - derived sample name
#   $args{threads}   - from slurm_sync or slurm_defaults
#   For scratch paths, use literal \$SCRATCH (shell variable).
sub make_command {
    my ($self, %args) = @_;
    confess "ERROR NBI::Launcher ($self->{name}): make_command() not implemented\n";
}

# ── generate_script(%args) ───────────────────────────────────────────────────
# Assembles the script body (everything after the #SBATCH header generated by
# NBI::Opts->header()).  Returns a single string.
#
# Sections (in order):
#   1. set -euo pipefail + metadata comment
#   2. Manifest update shell functions + ERR trap
#   3. Activation (module load / conda / empty for singularity)
#   4. SAMPLE, OUTDIR, SCRATCH variables
#   5. EXIT trap (scratch cleanup)
#   6. Tool command from make_command()
#   7. Required-output validation
#   8. Promote from scratch to outdir + success update
sub generate_script {
    my ($self, %args) = @_;

    my $tool         = $self->{name};
    my $version      = $self->{version};
    my $sample       = $args{sample}        or confess "generate_script: 'sample' required\n";
    my $outdir       = $args{outdir}        or confess "generate_script: 'outdir' required\n";
    my $manifest_rel = $args{manifest_path} // ".nbilaunch/$sample.manifest.json";
    my $submitted_at = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime());

    my $launcher_class = ref($self);
    my $nbi_version    = $NBI::Slurm::VERSION // 'unknown';
    my $nbi_l_version  = $NBI::Launcher::VERSION // '0.1.0';

    # ── Resolve %args for make_command ───────────────────────────────────────
    # Apply default_env / default fallbacks for params before calling make_command
    my %cmd_args = %args;
    for my $p (@{ $self->{params} }) {
        my $name = $p->{name};
        next if defined $cmd_args{$name};
        if ($p->{default_env} && defined $ENV{ $p->{default_env} }) {
            $cmd_args{$name} = $ENV{ $p->{default_env} };
        } elsif (defined $p->{default}) {
            $cmd_args{$name} = $p->{default};
        }
    }

    my $tool_command = $self->make_command(%cmd_args);

    # ── Output validation checks ──────────────────────────────────────────────
    my $validation = '';
    for my $out (@{ $self->{outputs} }) {
        next unless $out->{required};
        my $pat = $out->{pattern} // next;
        # Substitute {sample} with shell variable reference
        (my $shell_pat = $pat) =~ s/\{sample\}/\${SAMPLE}/g;
        $validation .= <<"        BASH";
if [[ ! -s "\$SCRATCH/$shell_pat" ]]; then
    echo "[nbilaunch] ERROR: required output not found or empty: $shell_pat" >&2
    exit 1
fi
        BASH
    }

    my $activation = $self->activation_lines();

    # ── Scratch setup ─────────────────────────────────────────────────────────
    # Priority: explicit scratch_dir arg > $TMPDIR (use_tmpdir) > /tmp
    my $use_tmpdir = $self->{scratch}{use_tmpdir} // 0;
    my $scratch_base = defined $args{scratch_dir} ? $args{scratch_dir}
                     : $use_tmpdir                ? '${TMPDIR:-/tmp}'
                     :                              '/tmp';
    my $scratch_init = qq{SCRATCH=\$(mktemp -d "$scratch_base/${tool}_XXXXXXXX")};

    # ── Assemble script ───────────────────────────────────────────────────────
    my $sep = '# ' . '─' x 74;

    my $script = <<"SCRIPT";
set -euo pipefail

$sep
# Generated by nbilaunch v${nbi_l_version} / NBI::Slurm v${nbi_version}
# Tool:        $tool v$version
# Launcher:    $launcher_class
# Submitted:   $submitted_at
# Manifest:    $manifest_rel
$sep

$sep
# Runtime variables - defined first so traps and manifest can reference them
SAMPLE="$sample"
OUTDIR="\$(realpath "$outdir" 2>/dev/null || echo "$outdir")"
$scratch_init
MANIFEST="\$OUTDIR/.nbilaunch/$sample.manifest.json"
$sep

$sep
# Manifest update - called by ERR trap (failure) and at end (success).
# Uses a perl one-liner so there is no jq dependency on the HPC.
_nbi_manifest_update() {
    local status="\$1" exit_code="\$2" completed_at
    completed_at=\$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    perl -i -0777 -pe "
        s{\\\"status\\\":\\\\s*\\\"[^\\\"]+\\\"}{\\\"status\\\": \\\"\$status\\\"};
        s{\\\"exit_code\\\":\\\\s*null}{\\\"exit_code\\\": \$exit_code};
        s{\\\"completed_at\\\":\\\\s*null}{\\\"completed_at\\\": \\\"\$completed_at\\\"};
    " "\$MANIFEST"
}

trap '_nbi_manifest_update failure \$?' ERR
$sep

$sep
# Scratch cleanup on exit (runs even on success - scratch is empty after mv)
trap 'rm -rf "\$SCRATCH"' EXIT
$sep

SCRIPT

    # Activation section (empty for singularity)
    if ($activation) {
        $script .= <<"SCRIPT";
$sep
# Environment activation
$activation$sep

SCRIPT
    }

    $script .= <<"SCRIPT";

$sep
# Tool command
$tool_command
$sep

SCRIPT

    if ($validation) {
        $script .= <<"SCRIPT";
$sep
# Output validation
${validation}$sep

SCRIPT
    }

    $script .= <<"SCRIPT";
$sep
# Promote outputs from scratch to outdir and record success
mkdir -p "\$OUTDIR" "\$OUTDIR/.nbilaunch"
mv "\$SCRATCH"/* "\$OUTDIR"/
_nbi_manifest_update success 0
echo "[nbilaunch] Done. Outputs in: \$OUTDIR"
$sep
SCRIPT

    return $script;
}

# ── _resolve_args(%args) ──────────────────────────────────────────────────────
# Internal: apply default_env and default fallbacks, inject slurm_sync values,
# and resolve absolute paths.  Returns the resolved %args hash.
sub _resolve_args {
    my ($self, %args) = @_;

    # Apply param defaults
    for my $p (@{ $self->{params} }) {
        my $name = $p->{name};
        next if defined $args{$name};
        if ($p->{default_env} && defined $ENV{ $p->{default_env} }) {
            $args{$name} = $ENV{ $p->{default_env} };
        } elsif (defined $p->{default}) {
            $args{$name} = $p->{default};
        }
    }

    # Resolve absolute paths for file/dir inputs and params
    for my $spec (@{ $self->{inputs} }, @{ $self->{params} }) {
        my $name = $spec->{name};
        next unless defined $args{$name};
        my $type = $spec->{type} // '';
        if ($type eq 'file' || $type eq 'dir') {
            $args{$name} = realpath($args{$name}) // $args{$name};
        }
    }

    # Absolute outdir
    if (defined $args{outdir}) {
        # realpath requires the path to exist; use abs_path fallback
        my $abs = eval { realpath($args{outdir}) };
        $args{outdir} = $abs if defined $abs;
    }

    return %args;
}

# ── _runtime_to_hours($str) ───────────────────────────────────────────────────
# Convert HH:MM:SS or simple hour strings to decimal hours for NBI::Opts.
sub _runtime_to_hours {
    my ($rt) = @_;
    if ($rt =~ /^(\d+):(\d+):(\d+)$/) {
        return $1 + $2 / 60 + $3 / 3600;
    }
    if ($rt =~ /^(\d+):(\d+)$/) {
        return $1 + $2 / 60;
    }
    if ($rt =~ /^(\d+)$/) {
        return $1;    # bare integer = hours
    }
    # Fall back: try NBI::Opts internal parser pattern
    my $hours = 0;
    my $upper = uc $rt;
    while ($upper =~ /(\d+)([DHMS])/g) {
        my ($v, $u) = ($1, $2);
        $hours += $v * 24  if $u eq 'D';
        $hours += $v       if $u eq 'H';
        $hours += $v / 60  if $u eq 'M';
        $hours += $v / 3600 if $u eq 'S';
    }
    return $hours || 1;
}

# ── build(%args) ─────────────────────────────────────────────────────────────
# The main entry point called by bin/nbilaunch.
#
# Validates inputs, resolves defaults, builds NBI::Job and NBI::Manifest.
# Returns a two-element list: ($job, $manifest).
#
# %args keys:
#   All inputs/params by name (from nbilaunch arg parsing)
#   outdir         - output directory (required)
#   sample_name    - optional override for derived sample name
#   slurm_queue    - override slurm_defaults{queue}
#   slurm_threads  - override slurm_defaults{threads}
#   slurm_memory   - override slurm_defaults{memory} (GB)
#   slurm_runtime  - override slurm_defaults{runtime} (HH:MM:SS or hours)
sub build {
    my ($self, %args) = @_;

    require NBI::Job;
    require NBI::Opts;
    require NBI::Manifest;

    # ── Resolve Slurm resource values ─────────────────────────────────────────
    my $queue   = $args{slurm_queue}   // $self->{slurm_defaults}{queue};
    my $threads = $args{slurm_threads} // $self->{slurm_defaults}{threads};
    my $mem_gb  = $args{slurm_memory}  // $self->{slurm_defaults}{memory};
    my $runtime = $args{slurm_runtime} // $self->{slurm_defaults}{runtime};

    # Inject slurm_sync params (e.g. threads param mirrors Slurm --cpus)
    for my $p (@{ $self->{params} }) {
        next unless $p->{slurm_sync};
        if ($p->{slurm_sync} eq 'threads') {
            $args{ $p->{name} } = $threads;
        } elsif ($p->{slurm_sync} eq 'memory') {
            $args{ $p->{name} } = $mem_gb;
        }
    }

    # ── Resolve and validate args ─────────────────────────────────────────────
    %args = $self->_resolve_args(%args);
    $self->validate(%args);

    # ── Derive sample name ────────────────────────────────────────────────────
    my $sample = $self->sample_name(%args);
    $args{sample} = $sample;

    # ── Paths ─────────────────────────────────────────────────────────────────
    my $outdir        = $args{outdir};
    my $nbi_dir       = "$outdir/.nbilaunch";
    my $job_name      = "$self->{name}_$sample";
    my $manifest_path = "$nbi_dir/$sample.manifest.json";
    my $script_rel    = ".nbilaunch/${job_name}.script.sh";

    $args{manifest_path} = $manifest_path;

    # ── Generate script body ──────────────────────────────────────────────────
    my $script_body = $self->generate_script(%args);

    # ── Build NBI::Opts ───────────────────────────────────────────────────────
    my $hours  = _runtime_to_hours($runtime);
    my $mem_mb = $mem_gb * 1024;

    my $opts = NBI::Opts->new(
        -queue   => $queue,
        -threads => $threads,
        -memory  => $mem_mb,
        -time    => $hours,
        -tmpdir  => $nbi_dir,
    );

    # ── Build NBI::Job ────────────────────────────────────────────────────────
    my $job = NBI::Job->new(
        -name    => $job_name,
        -command => $script_body,
        -opts    => $opts,
    );

    # Log/err go to provenance directory; %j is expanded by Slurm to the job ID
    $job->outputfile = "$nbi_dir/${job_name}.%j.log";
    $job->errorfile  = "$nbi_dir/${job_name}.%j.err";

    # ── Collect resolved inputs/params/outputs for manifest ───────────────────
    my %inp_snapshot;
    for my $inp (@{ $self->{inputs} }) {
        $inp_snapshot{ $inp->{name} } = $args{ $inp->{name} }
            if defined $args{ $inp->{name} };
    }

    my %par_snapshot;
    for my $p (@{ $self->{params} }) {
        $par_snapshot{ $p->{name} } = $args{ $p->{name} }
            if defined $args{ $p->{name} };
    }

    my %out_snapshot;
    for my $out (@{ $self->{outputs} }) {
        my $pat = $out->{pattern} // next;
        (my $filename = $pat) =~ s/\{sample\}/$sample/g;
        $out_snapshot{ $out->{name} } = $filename;
    }

    # ── Build manifest ────────────────────────────────────────────────────────
    my $manifest = NBI::Manifest->new(
        tool               => $self->{name},
        tool_version       => $self->{version},
        sample             => $sample,
        outdir             => $outdir,
        inputs             => \%inp_snapshot,
        params             => \%par_snapshot,
        outputs            => \%out_snapshot,
        slurm_queue        => $queue,
        slurm_cpus         => $threads,
        slurm_mem_gb       => $mem_gb,
        script             => $script_rel,
        status             => 'submitted',
    );

    return ($job, $manifest);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NBI::Launcher - Base class for nbilaunch tool wrappers

=head1 VERSION

version 0.21.0

=head1 SYNOPSIS

  package NBI::Launcher::MyTool;
  use parent 'NBI::Launcher';

  sub new {
      my ($class) = @_;
      return $class->SUPER::new(
          name        => 'mytool',
          description => 'Does something useful',
          version     => '1.0.0',
          activate    => { module => 'mytool/1.0.0' },
          slurm_defaults => { queue => 'short', threads => 4, memory => 8 },
          inputs  => [ { name => 'input', flag => '-i', type => 'file', required => 1,
                         help => 'Input file' } ],
          params  => [],
          outputs => [ { name => 'result', pattern => '{sample}.out', required => 1,
                         help => 'Result file' } ],
          outdir  => { flag => '--outdir', short => '-o', required => 1 },
      );
  }

  sub make_command {
      my ($self, %args) = @_;
      my $prefix = $self->singularity_prefix;   # '' unless singularity activation
      return "${prefix}mytool -i $args{input} -o \$SCRATCH/$args{sample}.out";
  }

  1;

=head1 NAME

NBI::Launcher - Base class for nbilaunch tool wrappers

=head1 METHODS

=head2 new(%args)

Construct a launcher spec. See module source for all accepted keys.

=head2 activation_lines()

Shell snippet to load the tool (module load / source activate / empty for singularity).

=head2 singularity_prefix()

Returns C<"singularity exec $image "> or C<""> - use in make_command() overrides.

=head2 sample_name(%args)

Derives sample name from the first required file input, stripping FASTQ extensions.

=head2 input_mode(%args)

Returns C<"paired"> if both r1 and r2 are present, C<"single"> otherwise.

=head2 arg_spec()

Returns the launcher's CLI surface (inputs, params, outputs, slurm_defaults).
Used by nbilaunch for --help generation and argument parsing.

=head2 validate(%args)

Dies with a helpful message on missing or invalid inputs/params.

=head2 make_command(%args)

Returns the tool invocation string.  Subclasses must override this.
Use C<\$SCRATCH> (literal shell variable) for scratch-directory paths.

=head2 generate_script(%args)

Assembles the full bash script body.  Called by build().

=head2 build(%args)

Validates, resolves, and returns C<($job, $manifest)> - an C<NBI::Job>
and an C<NBI::Manifest> - ready for nbilaunch to write and optionally submit.

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
