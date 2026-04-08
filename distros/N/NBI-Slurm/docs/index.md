---
layout: default
title: "NBI::Slurm — Perl toolkit for SLURM HPC clusters"
description: "Submit, monitor, and schedule jobs on SLURM clusters from Perl or the command line."
hero: true
hero_title: "NBI::Slurm"
hero_desc: "A Perl toolkit that makes SLURM job management feel effortless — from one-liners to complex pipelines."
---

<div class="install-box">
  <div class="install-title">Install via CPAN</div>
  <pre><code>cpanm NBI::Slurm</code></pre>
</div>

## What is NBI::Slurm?

**NBI::Slurm** is a comprehensive Perl package for interacting with [SLURM](https://slurm.schedmd.com/)
(Simple Linux Utility for Resource Management), the workload manager used on most HPC clusters.
It ships both a **Perl API** for programmatic job submission and a set of **command-line tools**
designed for day-to-day cluster use.

Whether you need to fire off a single analysis script, fan out hundreds of array tasks across
a file list, chain dependent pipeline stages, or schedule long jobs to run during cheap
electricity windows — NBI::Slurm has you covered.

<div class="feature-grid">
  <div class="feature-card">
    <div class="feature-icon">🚀</div>
    <h3>Easy job submission</h3>
    <p>Submit jobs with sensible defaults and override only what you need. Resources, queues, time limits, and email notifications are all one argument away.</p>
  </div>
  <div class="feature-card">
    <div class="feature-icon">📦</div>
    <h3>Array jobs made simple</h3>
    <p>Pass a list of files and a placeholder token — NBI::Slurm generates the SLURM array automatically. Process thousands of files with a single command.</p>
  </div>
  <div class="feature-card">
    <div class="feature-icon">🔗</div>
    <h3>Pipeline dependencies</h3>
    <p>Chain jobs so step 2 only starts when step 1 finishes. Use <code>--after</code> in <code>runjob</code> or <code>waitjobs</code> in shell scripts.</p>
  </div>
  <div class="feature-card">
    <div class="feature-icon">🌿</div>
    <h3>Eco scheduling</h3>
    <p>The built-in EcoScheduler finds cheap electricity windows (e.g. overnight) and defers non-urgent jobs automatically — saving energy and cost.</p>
  </div>
  <div class="feature-card">
    <div class="feature-icon">🖥️</div>
    <h3>Interactive sessions</h3>
    <p>The <code>session</code> command requests an interactive shell with specified resources. Great for exploratory analysis or debugging on the cluster.</p>
  </div>
  <div class="feature-card">
    <div class="feature-icon">🔍</div>
    <h3>Queue monitoring</h3>
    <p>List, filter, and manage your jobs with <code>lsjobs</code>. See who else is running what with <code>whojobs</code>. Block pipelines with <code>waitjobs</code>.</p>
  </div>
</div>

---

## Two interfaces, one toolkit

### Command-line tools

For quick interactive use, the CLI tools wrap SLURM commands with a friendlier interface:

```bash
# Submit a job with 8 cores and 16 GB RAM
runjob -n "alignment" -c 8 -m 16GB -t 4h -r "bwa mem ref.fa reads.fastq > out.sam"

# Process 200 files as a SLURM array job
runjob -n "variant-call" -f "*.bam" -c 4 -m 8GB -r "call_variants.sh #FILE#" --run

# List your running jobs
lsjobs --running

# Wait until all 'variant-call' jobs finish, then merge
waitjobs -n "variant-call"
merge_results.sh

# Start an interactive session with 4 cores and 32 GB
session -c 4 -m 32GB -h 8
```

### Perl API

For scripting and programmatic pipelines, use the object-oriented or functional interfaces:

```perl
use NBI::Slurm;

# Build options
my $opts = NBI::Opts->new(
    -queue   => "short",
    -threads => 8,
    -memory  => "16GB",
    -hours   => 4,
);

# Create and submit a job
my $job = NBI::Job->new(
    -name    => "alignment",
    -command => "bwa mem ref.fa reads.fastq > out.sam",
    -opts    => $opts,
);

my $jobid = $job->run();
print "Submitted as job $jobid\n";
```

---

## Command-line tools at a glance

| Tool | Purpose | MetaCPAN |
|------|---------|----------|
| `runjob` | Submit jobs with resource specifications | [docs ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/runjob) |
| `lsjobs` | List, filter, and delete queue jobs | [docs ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/lsjobs) |
| `waitjobs` | Block a script until matching jobs complete | [docs ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/waitjobs) |
| `whojobs` | Cluster usage summary by user | [docs ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/whojobs) |
| `session` | Start an interactive SLURM session | [docs ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/session) |
| `shelf` | Search installed HPC packages/containers | [docs ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/shelf) |
| `configuration` | Create or validate `~/.nbislurm.config` | — |

---

## Perl modules at a glance

| Module | Purpose | MetaCPAN |
|--------|---------|----------|
| `NBI::Slurm` | Top-level utilities and exports | [docs ↗](https://metacpan.org/pod/NBI::Slurm) |
| `NBI::Job` | Build and submit a single SLURM job | [docs ↗](https://metacpan.org/pod/NBI::Job) |
| `NBI::Opts` | SLURM resource options (queue, cores, RAM, time) | [docs ↗](https://metacpan.org/pod/NBI::Opts) |
| `NBI::Queue` | Query the live SLURM queue | [docs ↗](https://metacpan.org/pod/NBI::Queue) |
| `NBI::QueuedJob` | Represents a single job entry in the queue | [docs ↗](https://metacpan.org/pod/NBI::QueuedJob) |
| `NBI::EcoScheduler` | Find energy-efficient scheduling windows | [docs ↗](https://metacpan.org/pod/NBI::EcoScheduler) |

<div class="metacpan-ref">
  <div class="metacpan-ref-icon">📦</div>
  <div class="metacpan-ref-body">
    <div class="metacpan-ref-title">Official API documentation on MetaCPAN</div>
    <p style="font-size:0.88rem;color:var(--text-muted);margin:0 0 0.2rem">
      Full method signatures, parameters, and return values are maintained on MetaCPAN.
    </p>
    <div class="metacpan-ref-links">
      <a href="https://metacpan.org/pod/NBI::Slurm" target="_blank" rel="noopener">NBI::Slurm</a>
      <a href="https://metacpan.org/pod/NBI::Job" target="_blank" rel="noopener">NBI::Job</a>
      <a href="https://metacpan.org/pod/NBI::Opts" target="_blank" rel="noopener">NBI::Opts</a>
      <a href="https://metacpan.org/pod/NBI::Queue" target="_blank" rel="noopener">NBI::Queue</a>
      <a href="https://metacpan.org/pod/NBI::QueuedJob" target="_blank" rel="noopener">NBI::QueuedJob</a>
      <a href="https://metacpan.org/pod/NBI::EcoScheduler" target="_blank" rel="noopener">NBI::EcoScheduler</a>
    </div>
  </div>
</div>

---

## What makes it different?

Most SLURM wrappers are thin shells around `sbatch`. NBI::Slurm goes further:

- **Smart defaults** — sensible queue, memory, and time values that work out of the box, all overridable via a config file.
- **Array jobs without the boilerplate** — pass a glob or a list of files and the `#FILE#` placeholder; the wrapper generates the bash array and SLURM `--array` directive for you.
- **Eco-aware scheduling** — the EcoScheduler module can defer jobs to cheap electricity windows (e.g. overnight) while respecting peak-hour constraints.
- **Portable scripting** — the Perl API makes it easy to write portable pipeline scripts that run the same way on any SLURM cluster.
- **Dry-run by default** — `runjob` prints the generated script unless you pass `--run`, so you can always verify before submitting.

---

## Quick start

<div class="step">
  <div class="step-num">1</div>
  <div class="step-body">
    <h4>Install the module</h4>
    <pre><code>cpanm NBI::Slurm</code></pre>
  </div>
</div>

<div class="step">
  <div class="step-num">2</div>
  <div class="step-body">
    <h4>Create your config file</h4>
    <pre><code>configuration</code></pre>
    <p style="font-size:0.88rem;color:var(--text-muted)">Writes <code>~/.nbislurm.config</code> with all available options. Edit it to set your default queue, email, and memory.</p>
  </div>
</div>

<div class="step">
  <div class="step-num">3</div>
  <div class="step-body">
    <h4>Submit your first job</h4>
    <pre><code># Preview (no submission)
runjob "echo hello world"

# Submit for real
runjob -r "echo hello world"</code></pre>
  </div>
</div>

<div class="step">
  <div class="step-num">4</div>
  <div class="step-body">
    <h4>Read the tutorial</h4>
    <p style="font-size:0.88rem;color:var(--text-muted)">The <a href="./tutorial/">tutorial</a> walks through array jobs, dependencies, eco scheduling, and the Perl API.</p>
  </div>
</div>

---

## Requirements

- Perl 5.16 or newer
- A SLURM cluster (or at least `sbatch`/`squeue` in your PATH)
- CPAN modules: `Capture::Tiny`, `JSON::PP`, `Text::ASCIITable`

<span class="chip">v0.17.2</span> &nbsp;
<span class="chip chip-green">MIT License</span>
