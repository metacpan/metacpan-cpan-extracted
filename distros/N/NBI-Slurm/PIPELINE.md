# PROJECT_PIPELINE.md — NBI::Slurm Launcher Extension

## Overview

This document describes the design and implementation plan for extending the
`NBI::Slurm` Perl package with a **launcher subsystem**: a declarative DSL for
defining bioinformatics tool wrappers, and a CLI dispatcher `nbilaunch` that
turns those definitions into validated, provenance-tracked Slurm jobs.

The existing `NBI::Slurm` API (`NBI::Job`, `NBI::Opts`) is **not modified**.
The launcher subsystem sits on top of it as a new layer.

---

## Repository Layout (after this work)

```
NBI-Slurm/
├── bin/
│   ├── runjob                    # existing — do not modify
│   └── nbilaunch                 # NEW: universal launcher dispatcher
├── lib/
│   └── NBI/
│       ├── Job.pm                # existing — do not modify
│       ├── Opts.pm               # existing — do not modify
│       ├── Slurm.pm              # existing — do not modify
│       ├── Launcher.pm           # NEW: base class for all launchers
│       ├── Manifest.pm           # NEW: read/write JSON run manifests
│       ├── Pipeline.pm           # NEW: ordered list of NBI::Job with deps
│       └── Launcher/
│           └── Kraken2.pm        # NEW: reference implementation
├── t/
│   ├── launcher_base.t           # NEW
│   ├── launcher_kraken2.t        # NEW
│   ├── manifest.t                # NEW
│   └── pipeline.t                # NEW
└── PROJECT_PIPELINE.md           # this file
```

User-level launchers live outside the package:
- `./launchers/<name>.pm` — project-local (highest priority)
- `~/.nbi/launchers/<name>.pm` — user-level
- `NBI::Launcher::<Name>` — system (installed with package, lowest priority)

`nbilaunch` searches in that order and loads the first match.

---

## New Modules

---

### `NBI::Launcher` — Base Class

**File:** `lib/NBI/Launcher.pm`

This is the base class every launcher inherits from. It provides:
- The DSL constructor (`new` with named parameters)
- Argument spec introspection (used by `nbilaunch` for `--help` and parsing)
- Job script generation (scratch setup, tool invocation, manifest update,
  output promotion)
- Input/param/output validation

#### Constructor

```perl
my $launcher = NBI::Launcher->new(
    name        => "kraken2",
    description => "Taxonomic sequence classification",
    version     => "2.1.0",        # tool version (pinned)
    activate    => { ... },        # see Activation below

    slurm_defaults => {
        queue   => "short",
        threads => 8,
        memory  => 32,             # GB
        runtime => "04:00:00",
    },

    inputs  => [ ... ],            # see Input Spec below
    params  => [ ... ],            # see Param Spec below
    outputs => [ ... ],            # see Output Spec below
    outdir  => { flag => "--outdir", short => "-o", required => 1 },

    scratch => {
        use_tmpdir        => 1,    # use $TMPDIR from Slurm env
        cleanup_on_failure => 1,   # rm -rf scratch on non-zero exit
    },

    success_check => sub {         # optional extra validation
        my ($outdir, $sample) = @_;
        return -s "$outdir/$sample.k2report" > 100;
    },
);
```

#### Activation Spec

Exactly one key is set:

```perl
activate => { module      => "kraken2/2.1.0"          }  # module load
activate => { singularity => "/qib/tools/kraken2.sif"  }  # singularity exec
activate => { conda       => "kraken2-env"             }  # conda activate
```

The base class method `activation_lines()` returns the appropriate shell
snippet for each strategy:

| Strategy | Generated shell |
|---|---|
| `module` | `module load kraken2/2.1.0` |
| `singularity` | prefix every tool call with `singularity exec /qib/tools/kraken2.sif` |
| `conda` | `source activate kraken2-env` |

For `singularity`, the launcher stores the image path and `make_command()`
prepends `singularity exec $IMAGE` to the tool invocation string.

#### Input Spec

Each entry in the `inputs` array is a hashref:

```perl
{
    name     => "r1",           # used as CLI flag --r1 / positional key
    flag     => "-1",           # flag passed to the tool
    short    => undef,          # optional short CLI flag for nbilaunch
    type     => "file",         # "file" | "dir" | "string" | "int" | "float"
    required => 1,
    help     => "Forward reads (or single-end FASTQ)",
    # "file" type: nbilaunch checks the file exists before submitting
}
```

If `r2` is present and `r1` is present → paired-end mode.
If only `r1` → single-end mode.
The launcher subclass can override `input_mode()` to encode this logic,
or the base class can infer it from which optional file inputs were provided.

#### Param Spec

```perl
{
    name        => "db",
    flag        => "--db",
    type        => "dir",
    required    => 1,
    default     => "/qib/databases/kraken2/standard",
    default_env => "KRAKEN2_DB",   # env var checked before hardcoded default
    help        => "Kraken2 database directory",
},
{
    name       => "threads",
    flag       => "--threads",
    type       => "int",
    slurm_sync => "threads",       # value injected from NBI::Opts->threads
    # not shown in --help as a user-settable param; derived from --cpus
},
```

`slurm_sync` params are not exposed as CLI options in `nbilaunch`; they are
automatically populated from the corresponding Slurm allocation.
Supported sync keys: `threads` → `--cpus-per-task`, `memory` → `--mem`.

#### Output Spec

```perl
{
    name     => "report",
    flag     => "--report",
    pattern  => '{sample}.k2report',   # {sample} substituted at runtime
    required => 1,                     # must exist after run for success
    help     => "Per-taxon classification report",
},
{
    name    => "output",
    flag    => "--output",
    pattern => '{sample}.k2out',
    required => 0,
},
```

`{sample}` is derived from the basename of `r1` (or the first positional
input), stripping known FASTQ extensions (`_R1`, `_1`, `.fastq`, `.fq`,
`.gz`). Overrideable via `--sample-name STR` in `nbilaunch`.

#### Key Methods (base class provides default implementations)

| Method | Description |
|---|---|
| `activation_lines()` | Returns shell snippet to load the tool |
| `make_command(%args)` | Returns the tool invocation string |
| `build(%args)` | Returns `NBI::Job` (or `NBI::Pipeline` for complex launchers) |
| `validate(%args)` | Dies with a helpful message on bad input |
| `arg_spec()` | Returns the parsed spec for `nbilaunch` CLI generation |
| `input_mode(%args)` | Returns `"single"` or `"paired"` |
| `sample_name(%args)` | Derives sample name from input filename |

Subclasses **may** override any of these. For most tools, only `make_command`
needs overriding (to handle tool-specific flag ordering or logic).

#### Example Subclass (Kraken2)

```perl
package NBI::Launcher::Kraken2;
use parent 'NBI::Launcher';

sub new {
    my ($class) = @_;
    return $class->SUPER::new(
        name        => "kraken2",
        description => "Taxonomic classification of sequencing reads",
        version     => "2.1.0",
        activate    => { module => "kraken2/2.1.0" },

        slurm_defaults => { queue => "short", threads => 8, memory => 32 },

        inputs => [
            { name => "r1", flag => "-1", type => "file", required => 1,
              help => "Forward reads (or single-end FASTQ)" },
            { name => "r2", flag => "-2", type => "file", required => 0,
              help => "Reverse reads (omit for single-end)" },
        ],

        params => [
            { name => "db", flag => "--db", type => "dir", required => 1,
              default => "/qib/databases/kraken2/standard",
              default_env => "KRAKEN2_DB",
              help => "Kraken2 database path" },
            { name => "confidence", flag => "--confidence", type => "float",
              default => 0.0, help => "Confidence score threshold (0–1)" },
            { name => "threads", flag => "--threads", slurm_sync => "threads" },
        ],

        outputs => [
            { name => "report", flag => "--report",
              pattern => '{sample}.k2report', required => 1,
              help => "Kraken2 classification report" },
            { name => "output", flag => "--output",
              pattern => '{sample}.k2out', required => 0,
              help => "Per-read classification output" },
        ],

        outdir  => { flag => "--outdir", short => "-o", required => 1 },
        scratch => { use_tmpdir => 1, cleanup_on_failure => 1 },
    );
}

# Only make_command needs overriding — base class handles everything else.
sub make_command {
    my ($self, %args) = @_;
    my $pe = $args{r2} ? "--paired -1 $args{r1} -2 $args{r2}"
                       : "$args{r1}";
    return join(" ",
        "kraken2",
        "--threads $args{threads}",
        "--db $args{db}",
        "--confidence $args{confidence}",
        "--report $args{scratch}/$args{sample}.k2report",
        "--output $args{scratch}/$args{sample}.k2out",
        $pe,
    );
}

1;
```

---

### `NBI::Manifest` — Provenance Records

**File:** `lib/NBI/Manifest.pm`

Reads and writes the JSON manifest file. Written in two phases:

1. **At submission** (by `nbilaunch`): status `"submitted"`, all inputs/params recorded
2. **At job end** (by injected shell function): status updated to `"success"` or `"failure"`, checksums and timing added

#### Manifest JSON Schema

```json
{
  "tool":             "kraken2",
  "tool_version":     "2.1.0",
  "launcher_version": "0.1.0",
  "nbi_slurm_version":"0.17.0",
  "submitted_at":     "2026-03-20T10:32:00Z",
  "completed_at":     null,
  "slurm_job_id":     4821934,
  "slurm_queue":      "short",
  "slurm_cpus":       8,
  "slurm_mem_gb":     32,
  "host":             "hpc.qib.ac.uk",
  "user":             "andrea",
  "status":           "submitted",
  "exit_code":        null,
  "sample":           "sample1",
  "inputs": {
    "r1": "/data/raw/sample1_R1.fq.gz",
    "r2": "/data/raw/sample1_R2.fq.gz"
  },
  "params": {
    "db":         "/qib/databases/kraken2/standard",
    "confidence": 0.0,
    "threads":    8
  },
  "outputs": {
    "report": "sample1.k2report",
    "output": "sample1.k2out"
  },
  "outdir":   "/absolute/path/to/results/kraken2",
  "scratch":  "/tmp/kraken2_aB3xQ9",
  "checksums": {},
  "script":   ".nbilaunch/sample1.script.sh"
}
```

#### Key Methods

```perl
NBI::Manifest->new(%fields)           # create in memory
$m->write($path)                      # write JSON to file
NBI::Manifest->load($path)            # parse existing manifest
$m->output($name)                     # get absolute path of a named output
$m->update(status => "success", ...)  # update fields and rewrite
```

`NBI::Manifest->load()` enables complex launchers to chain jobs by reading
a previous run's outputs:

```perl
my $m = NBI::Manifest->load("$outdir/.nbilaunch/sample1.manifest.json");
my $report = $m->output("report");   # feed into bracken job
```

#### Provenance Directory Layout

```
results/kraken2/
  sample1.k2report              ← tool output
  sample1.k2out
  .nbilaunch/
    sample1.manifest.json       ← structured provenance
    sample1.script.sh           ← exact script submitted
    sample1.log                 ← stdout + stderr (via --output in sbatch)
```

The `.nbilaunch/` directory is hidden but travels with the data.

---

### `NBI::Pipeline` — Multi-Job Orchestration Stub

**File:** `lib/NBI/Pipeline.pm`

A thin ordered list of `NBI::Job` objects with dependency wiring. This is
intentionally minimal in v1 — it is designed to be extended, not to be a
workflow engine.

```perl
my $pipeline = NBI::Pipeline->new(
    jobs => [$job1, $job2],   # $job2 has depends_on => $job1
);

my @jobids = $pipeline->run;   # submits in order, wires afterok deps
$pipeline->print_summary;      # prints job IDs and dependency graph
```

#### Key Methods

```perl
NBI::Pipeline->new(jobs => \@jobs)
$p->add_job($job)
$p->run                          # submit all, return list of job IDs
$p->print_summary                # human-readable dep graph
```

#### Dependency Wiring

`NBI::Job` already accepts `-opts => ["-m afterok:JOBID"]` via `NBI::Opts`.
`NBI::Pipeline->run` submits jobs in order, captures each job ID, and injects
it into the next job's `NBI::Opts` before submission. No new mechanism needed.

#### Usage in a Complex Launcher

```perl
sub build {
    my ($self, %args) = @_;

    my $job1 = $self->_build_kraken2_job(%args);
    my $job2 = $self->_build_bracken_job(%args, depends_on => $job1);

    return NBI::Pipeline->new(jobs => [$job1, $job2]);
}
```

`nbilaunch` checks the return type of `build()`:
- `NBI::Job` → single submit
- `NBI::Pipeline` → `$pipeline->run`

---

### `bin/nbilaunch` — CLI Dispatcher

**File:** `bin/nbilaunch`

A Perl script. No non-core dependencies beyond `NBI::Slurm` itself.

#### Usage

```
nbilaunch <toolname> [tool-args] [slurm-args] [--run] [--verbose] [--dry-run]
nbilaunch <toolname> --help
nbilaunch --list
nbilaunch --list --verbose
```

#### Global Flags (always available regardless of launcher)

| Flag | Description |
|---|---|
| `--run` | Actually submit the job (default: dry-run, print script) |
| `--dry-run` | Explicit dry-run; print generated script and manifest preview |
| `--verbose` | Print script before submitting even with `--run` |
| `--sample-name STR` | Override inferred sample name |
| `--job-name STR` | Override Slurm job name (default: `{tool}_{sample}`) |
| `--queue STR` | Override launcher's default queue |
| `--mem INT` | Override memory in GB |
| `--cpus INT` | Override CPU count (also drives slurm_sync params) |
| `--runtime STR` | Override walltime (HH:MM:SS) |
| `--list` | List all discovered launchers |
| `--help` | Show tool-specific usage (after launcher is loaded) |

#### Discovery Logic

```perl
sub discover_launcher {
    my ($name) = @_;
    my $mod = ucfirst(lc($name));   # "kraken2" → "Kraken2"

    # 1. local
    my $local = "./launchers/${name}.pm";
    if (-f $local) { require $local; return "NBI::Launcher::${mod}"; }

    # 2. user
    my $user = "$ENV{HOME}/.nbi/launchers/${name}.pm";
    if (-f $user) { require $user; return "NBI::Launcher::${mod}"; }

    # 3. system
    my $sys = "NBI::Launcher::${mod}";
    eval "require $sys"; return $sys unless $@;

    die "No launcher found for '$name'. Run 'nbilaunch --list' to see available tools.\n";
}
```

#### `--help` Output (auto-generated from launcher spec)

```
kraken2 v2.1.0 — Taxonomic classification of sequencing reads
Activated via: module load kraken2/2.1.0

USAGE
  nbilaunch kraken2 --r1 FILE [--r2 FILE] --outdir DIR [options]

INPUTS
  --r1 FILE        Forward reads or single-end FASTQ  [required]
  --r2 FILE        Reverse reads — enables paired-end mode

OUTPUT
  -o, --outdir DIR  Output directory  [required]

TOOL PARAMETERS
  --db DIR         Kraken2 database  [default: /qib/databases/kraken2/standard]
                   (override with $KRAKEN2_DB)
  --confidence N   Confidence threshold  [default: 0.0]

SLURM OPTIONS
  --queue STR      [default: short]
  --mem INT        Memory in GB  [default: 32]
  --cpus INT       CPUs (also sets --threads)  [default: 8]
  --runtime STR    Walltime HH:MM:SS  [default: 04:00:00]

NOTES
  --cpus is automatically synced to --threads inside the job.
  Run without --run to preview the generated script (dry-run is default).

EXAMPLES
  nbilaunch kraken2 --r1 s_R1.fq.gz --r2 s_R2.fq.gz --outdir results/
  nbilaunch kraken2 --r1 s_R1.fq.gz --outdir results/ --run
  nbilaunch kraken2 --r1 s_R1.fq.gz --outdir results/ --db /my/db --cpus 16 --run
```

#### Dispatcher Flow

```
1. parse global argv: extract toolname, detect --help / --list
2. discover launcher module
3. instantiate: my $launcher = NBI::Launcher::Kraken2->new()
4. if --help: print auto-generated usage, exit 0
5. parse tool argv against $launcher->arg_spec()
6. validate: required args, file/dir existence, type checks
7. derive: sample name, absolute paths, slurm_sync params
8. call: my $result = $launcher->build(%args)
9. write manifest (status: "submitted"), save script to .nbilaunch/
10. if --dry-run (default): print script, print manifest preview, exit 0
11. if --run: submit via $result->run or $result->run (Pipeline)
12. print: job ID(s), manifest path, script path
```

---

## Generated Job Script Structure

Every script generated by `NBI::Launcher` follows this template.
The sections marked `# INJECTED` are emitted by the base class unconditionally.

```bash
#!/bin/bash
#SBATCH --job-name=kraken2_sample1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=short
#SBATCH --time=04:00:00
#SBATCH --output=results/.nbilaunch/sample1.log

# ── INJECTED: nbilaunch metadata ────────────────────────────────────────────
# Generated by nbilaunch v0.1.0 / NBI::Slurm v0.17.0
# Tool:        kraken2 v2.1.0
# Launcher:    NBI::Launcher::Kraken2
# Submitted:   2026-03-20T10:32:00Z
# Manifest:    results/.nbilaunch/sample1.manifest.json
# ────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── INJECTED: manifest update function ──────────────────────────────────────
MANIFEST="results/.nbilaunch/sample1.manifest.json"

_nbi_manifest_update() {
    local status="$1" exit_code="$2" completed_at
    completed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    # in-place JSON field update (no jq dependency)
    perl -i -0777 -pe "
        s{\"status\":\\s*\"[^\"]+\"}{\"status\": \"$status\"};
        s{\"exit_code\":\\s*null}{\"exit_code\": $exit_code};
        s{\"completed_at\":\\s*null}{\"completed_at\": \"$completed_at\"};
    " "$MANIFEST"
}

_nbi_manifest_checksums() {
    # compute sha256 for each expected output and patch into manifest
    perl -i -0777 -pe '
        use Digest::SHA;
        # ... patch checksums block ...
    ' "$MANIFEST"
}

trap '_nbi_manifest_update failure $?' ERR
# ────────────────────────────────────────────────────────────────────────────

# ── INJECTED: activation ────────────────────────────────────────────────────
module load kraken2/2.1.0
# ────────────────────────────────────────────────────────────────────────────

# ── INJECTED: variables ─────────────────────────────────────────────────────
SAMPLE="sample1"
OUTDIR="$(realpath results/kraken2)"
SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/kraken2_XXXXXXXX")
# ────────────────────────────────────────────────────────────────────────────

# ── INJECTED: scratch cleanup ───────────────────────────────────────────────
trap 'echo "[nbilaunch] Removing scratch: $SCRATCH"; rm -rf "$SCRATCH"' EXIT
# ────────────────────────────────────────────────────────────────────────────

# ── TOOL COMMAND (from make_command) ────────────────────────────────────────
kraken2 \
    --threads 8 \
    --db /qib/databases/kraken2/standard \
    --confidence 0.0 \
    --report "$SCRATCH/${SAMPLE}.k2report" \
    --output "$SCRATCH/${SAMPLE}.k2out" \
    --paired -1 /data/raw/sample1_R1.fq.gz -2 /data/raw/sample1_R2.fq.gz
# ────────────────────────────────────────────────────────────────────────────

# ── INJECTED: output validation ─────────────────────────────────────────────
if [[ ! -s "$SCRATCH/${SAMPLE}.k2report" ]]; then
    echo "[nbilaunch] ERROR: required output not found or empty: ${SAMPLE}.k2report" >&2
    exit 1
fi
# ────────────────────────────────────────────────────────────────────────────

# ── INJECTED: checksum + promote ────────────────────────────────────────────
_nbi_manifest_checksums
mkdir -p "$OUTDIR" "$OUTDIR/.nbilaunch"
mv "$SCRATCH"/* "$OUTDIR"/

_nbi_manifest_update success 0
echo "[nbilaunch] Done. Outputs in: $OUTDIR"
# ────────────────────────────────────────────────────────────────────────────
```

Key points:
- `set -euo pipefail` — any unhandled error triggers the `ERR` trap
- Two `trap` calls: `ERR` updates manifest to `failure`; `EXIT` removes scratch
- The `EXIT` trap runs even on success (scratch already empty after `mv`)
- `perl` one-liner for JSON patching avoids `jq` as a runtime dependency
- All injected sections are clearly delimited for debugging

---

## Testing Plan

Each new module gets its own test file under `t/`.

### `t/launcher_base.t`
- Constructor with all field types
- `arg_spec()` returns correct structure
- `activation_lines()` for module / singularity / conda
- `sample_name()` for various filename patterns
- `validate()` dies on missing required inputs
- `generate_script()` contains expected sections

### `t/launcher_kraken2.t`
- `make_command()` single-end and paired-end
- `build()` returns an `NBI::Job`
- Generated script contains correct `#SBATCH` headers
- `slurm_sync` wires threads correctly
- `default_env` overrides default when env var set

### `t/manifest.t`
- `new` + `write` + `load` round-trip
- `update()` patches status/exit_code/completed_at correctly
- `output()` returns correct absolute path
- JSON is valid after each write

### `t/pipeline.t`
- `new` with two jobs
- `run` (mocked sbatch) returns two job IDs
- Second job has correct `afterok:JOBID` dependency

Tests use `Test::More` and mock `sbatch` via a temporary `$PATH` entry that
writes to a temp file instead of submitting.

---

## Implementation Order

Implement in this sequence to keep tests passing at each step:

1. **`NBI::Manifest`** — pure data class, no Slurm dependency, easy to test first
2. **`NBI::Launcher` base class** — constructor, `arg_spec`, `activation_lines`,
   `sample_name`, `validate`, `generate_script` (no `build` yet)
3. **`NBI::Launcher::Kraken2`** — first concrete launcher, drives base class design
4. **`NBI::Launcher->build()`** — wires together script gen + `NBI::Job` creation
5. **`bin/nbilaunch`** — discovery, arg parsing, `--help`, dry-run, submit
6. **`NBI::Pipeline`** — stub sufficient for `nbilaunch` to handle the return type
7. **Tests** — fill in `t/` files throughout; don't leave until end

---

## Design Constraints & Conventions

- **No new non-core CPAN dependencies** in `NBI::Launcher` or `nbilaunch`.
  Use only modules already in `NBI::Slurm`'s current dependency list plus
  Perl core (`JSON::PP`, `File::Temp`, `File::Basename`, `Cwd`, `Getopt::Long`).
- **Dry-run is the default** in `nbilaunch`. `--run` must be explicit. This
  mirrors `runjob` behaviour.
- **Absolute paths everywhere** in generated scripts. Resolve at submission
  time via `Cwd::realpath`.
- **`set -euo pipefail`** in all generated scripts. The `ERR` trap handles
  manifest update on failure.
- **No `jq` dependency** at runtime. JSON patching in the job script uses a
  `perl` one-liner (Perl is always available on the QIB HPC).
- **Launcher subclasses must only override `make_command`** for simple tools.
  Overriding `build` is the escape hatch for complex multi-job launchers.
- **`NBI::Pipeline` is intentionally minimal in v1.** It does not resolve
  filenames between jobs — complex launchers do that via `NBI::Manifest->load`.

---

## Future Extensions (out of scope for this PR)

- `nbilaunch --batch samples.tsv` — submit one job per row
- `nbilaunch status <jobid>` — show manifest for a running/completed job
- `NBI::Launcher::Bracken` — chained launcher using `NBI::Manifest->load`
- YAML-format launcher definitions parsed into `NBI::Launcher` objects
- `nbilaunch rerun <manifest>` — resubmit from a manifest file
- `nbi_manifest_checksums` using `Digest::SHA` (currently stubbed)
