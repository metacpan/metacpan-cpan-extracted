---
layout: default
title: "Configuration"
description: "Complete reference for the ~/.nbislurm.config file used by NBI::Slurm tools."
sidebar: true
toc:
  - { id: "overview", title: "Overview" }
  - { id: "format", title: "File format" }
  - { id: "job-defaults", title: "Job defaults" }
  - { id: "eco", title: "Eco scheduling" }
  - { id: "sessions", title: "Interactive sessions" }
  - { id: "packages", title: "HPC packages" }
  - { id: "priority", title: "Priority order" }
  - { id: "examples", title: "Full examples" }
---

<nav class="toc" aria-label="Contents">
  <div class="toc-title">Contents</div>
  <ul>
    <li><a href="#overview">Overview</a></li>
    <li><a href="#format">File format</a></li>
    <li><a href="#job-defaults">Job defaults</a></li>
    <li><a href="#eco">Eco scheduling</a></li>
    <li><a href="#sessions">Interactive sessions</a></li>
    <li><a href="#packages">HPC packages</a></li>
    <li><a href="#priority">Priority order</a></li>
    <li><a href="#examples">Full examples</a></li>
  </ul>
</nav>

# Configuration

`~/.nbislurm.config` is the personal configuration file read by every NBI::Slurm tool.
It lets you set cluster-specific defaults — queues, memory limits, email addresses — once,
so you don't repeat them on every command.

---

## Overview {#overview}

The file is read at startup by `runjob`, `lsjobs`, `session`, and all other CLI tools,
as well as by the Perl `NBI::Slurm::load_config()` function.

### Create or update the config file

The `configuration` helper writes a template with all known keys:

```bash
configuration
```

If the file already exists, it **appends any missing keys** without overwriting your
existing settings. Running it again is always safe.

You can also point a tool at a custom config file:

```bash
# Perl API
my $cfg = NBI::Slurm::load_config("/path/to/custom.config");
```

---

## File format {#format}

The file uses a simple `key=value` format, one entry per line.
Comments start with `#` or `;` and are ignored.
Blank lines are allowed.

```ini
# This is a comment
; This is also a comment

email=user@institution.ac.uk
queue=nbi-short
memory=8000
```

**Rules:**
- Keys are case-sensitive (all lowercase)
- Values are trimmed of leading/trailing whitespace
- Unrecognised keys are silently ignored
- Boolean-like options use `0` (off) or `1` (on)

<div class="callout callout-warning">
  <div class="callout-title">No quoting needed</div>
  Values are plain text — do not wrap them in quotes. A value like <code>email="foo@bar.com"</code> will include the literal quote characters.
</div>

---

## Job defaults {#job-defaults}

These keys set the defaults used by `runjob` and by `NBI::Opts->new()` when a parameter
is not explicitly provided on the command line or in the constructor.

### `queue`

The default SLURM partition for all submitted jobs.

```ini
queue=nbi-short
```

If not set, NBI::Slurm uses a hardcoded default of `nbi-short`.

### `gpuqueue`

The partition used when `runjob --gpu` is passed.

```ini
gpuqueue=nbi-gpu
```

### `threads`

Default number of CPU cores per job.

```ini
threads=1
```

Corresponds to `--ntasks` in the generated `#SBATCH` header.

### `memory`

Default memory allocation. Accepts a bare integer (MB) or a value with a unit suffix.

```ini
memory=8000       # 8000 MB
# or
memory=8GB
```

### `time`

Default wall-clock time limit. Accepts the same flexible formats as `runjob --time`.

```ini
time=2h           # 2 hours
# or
time=1d           # 1 day
# or
time=4h30m        # 4 hours 30 minutes
```

### `tmpdir`

Directory where NBI::Slurm writes temporary job scripts and by default
places stdout/stderr log files. Must be writable.

```ini
tmpdir=/tmp
# or
tmpdir=/scratch/myuser/slurm-tmp
```

### `email`

Email address for SLURM job notifications. Used by `runjob` when `--email-address`
is not specified on the command line.

```ini
email=your@institution.ac.uk
```

### `email_type`

When to send email notifications. Comma-separated values from:
`NONE`, `BEGIN`, `END`, `FAIL`, `REQUEUE`, `ALL`.

```ini
email_type=END,FAIL
# or
email_type=ALL
# or
email_type=NONE     # disable notifications (default)
```

### `placeholder`

The token that marks where the filename should appear in array job commands.
Defaults to `#FILE#`.

```ini
placeholder=#FILE#
# or any other unique string:
placeholder={INPUT}
```

---

## Eco scheduling {#eco}

NBI::Slurm can defer non-urgent jobs to cheap electricity windows (e.g. overnight).
The `NBI::EcoScheduler` module looks at the configured windows and finds the next
available slot before submitting.

Full API documentation: [metacpan.org/pod/NBI::EcoScheduler ↗](https://metacpan.org/pod/NBI::EcoScheduler)

### `eco_default`

Set to `1` to enable eco scheduling for all `runjob` invocations by default.
Individual jobs can still override with `--eco` or `--no-eco`.

```ini
eco_default=1     # eco on by default
# or
eco_default=0     # eco off (default)
```

### `eco_windows_weekday`

Comma-separated `HH:MM-HH:MM` windows during which it is cheap to run jobs
on weekdays (Monday–Friday).

```ini
eco_windows_weekday=00:00-06:00
# or multiple windows:
eco_windows_weekday=00:00-06:00,22:00-23:59
```

### `eco_windows_weekend`

Same format as `eco_windows_weekday`, but for Saturday and Sunday.

```ini
eco_windows_weekend=00:00-07:00,11:00-16:00
```

### `eco_avoid`

Time windows to avoid every day, regardless of whether they fall inside an eco window.
Used to represent peak pricing periods.

```ini
eco_avoid=17:00-20:00
# or multiple ranges:
eco_avoid=08:00-10:00,17:00-20:00
```

### `eco_lookahead_days`

How many calendar days ahead the scheduler searches for a suitable slot.
If no slot is found within this window, the job is submitted immediately.

```ini
eco_lookahead_days=3
```

### How the tier system works

| Tier | What it means |
|------|--------------|
| **1 — Ideal** | Job fits entirely inside an eco window AND avoids peak hours |
| **2 — Acceptable** | Job avoids peak hours but may run past the end of the eco window |
| **3 — Fallback** | Job starts inside an eco window but may overlap peak hours |

The scheduler tries tier 1 first, then tier 2, then tier 3.
If no slot meets even tier 3 within `eco_lookahead_days`, the job is submitted now.

### Eco scheduling in practice

```bash
# Submit a 4-hour job that should run overnight
runjob --eco --time 4h --run "long_computation.sh"

# Override: submit immediately regardless of config
runjob --no-eco --run "urgent_fix.sh"
```

When eco mode selects a slot, `runjob` prints the scheduled start time and tier:

```
Eco slot found (tier 1): starting in 6h 42m at 2026-04-01T00:00:00
```

---

## Interactive sessions {#sessions}

These keys set the defaults for the `session` command.

Full CLI documentation: [metacpan.org/dist/NBI-Slurm/view/bin/session ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/session)

### `session_memory`

Default memory (in MB) for interactive sessions.

```ini
session_memory=2000
```

### `session_cpus`

Default number of CPU cores for interactive sessions.

```ini
session_cpus=1
```

### `session_hours`

Default duration (in hours) for interactive sessions.

```ini
session_hours=4
```

### `session`

Extra `srun` parameters appended to every interactive session request.
Useful for cluster-specific requirements.

```ini
session=--constraint=intel
```

### `special_session`

Extra parameters used only when `session --special` is passed.
Handy for a second profile (e.g. high-memory nodes, specific partitions).

```ini
special_session=--partition=himem --mem=128GB
```

---

## HPC packages {#packages}

These keys are used by `shelf` and the image-building utilities.

### `default_dest`

Default destination path for newly created Singularity images.

```ini
default_dest=/qib/platforms/Informatics/transfer/outgoing/singularity/core/
```

### `packages_dir`

Directory where package wrapper scripts (binaries) are installed.

```ini
packages_dir=/nbi/software/testing/bin/
```

### `packages_basepath`

Base path for the package installation tree.

```ini
packages_basepath=/nbi/software/testing/
```

---

## Priority order {#priority}

When a value can come from multiple sources, NBI::Slurm uses this precedence
(highest wins):

1. **Command-line argument** — e.g. `runjob --memory 32GB`
2. **Config file value** — `~/.nbislurm.config`
3. **Hardcoded default** — e.g. `memory=8000`, `queue=nbi-short`

This means your config file overrides built-in defaults, and CLI flags override your config.
You can always override a config setting for one job without changing the file.

---

## Full examples {#examples}

### Minimal config

```ini
email=alice@lab.ac.uk
queue=nbi-short
```

### Typical research group config

```ini
# ── Job submission defaults ─────────────────────────────────────────
email=alice@lab.ac.uk
email_type=END,FAIL
queue=nbi-short
gpuqueue=nbi-gpu
threads=1
memory=8000
time=2h
tmpdir=/scratch/alice/slurm-logs

# ── Eco scheduling ──────────────────────────────────────────────────
eco_default=1
eco_windows_weekday=00:00-06:00
eco_windows_weekend=00:00-08:00,12:00-17:00
eco_avoid=17:00-20:00
eco_lookahead_days=3

# ── Interactive sessions ────────────────────────────────────────────
session_memory=4000
session_cpus=2
session_hours=8
special_session=--partition=himem
```

### Config for a high-throughput sequencing lab

```ini
email=seq-team@genomics.ac.uk
email_type=FAIL
queue=nbi-medium
gpuqueue=nbi-gpu
threads=4
memory=16000
time=8h
tmpdir=/scratch/seq-pipeline/logs
placeholder=#SAMPLE#

eco_default=1
eco_windows_weekday=22:00-23:59,00:00-08:00
eco_windows_weekend=00:00-23:59
eco_avoid=09:00-18:00
eco_lookahead_days=2

session_memory=16000
session_cpus=4
session_hours=12
```

---

## All configuration keys at a glance

| Key | Default | Description |
|-----|---------|-------------|
| `queue` | `nbi-short` | Default SLURM partition |
| `gpuqueue` | — | GPU partition (for `runjob --gpu`) |
| `threads` | `1` | Default CPU cores |
| `memory` | `8000` | Default memory (MB) |
| `time` | `2h` | Default wall-clock limit |
| `tmpdir` | `/tmp` | Temp directory for scripts and logs |
| `email` | — | Notification email address |
| `email_type` | `NONE` | When to notify: `BEGIN`, `END`, `FAIL`, `ALL` |
| `placeholder` | `#FILE#` | Array job file token |
| `eco_default` | `0` | Enable eco scheduling by default (`0`/`1`) |
| `eco_windows_weekday` | — | Mon–Fri eco windows (`HH:MM-HH:MM`) |
| `eco_windows_weekend` | — | Sat–Sun eco windows |
| `eco_avoid` | — | Daily peak hours to avoid |
| `eco_lookahead_days` | `3` | Days ahead to search for eco slots |
| `session_memory` | `1000` | Default session memory (MB) |
| `session_cpus` | `1` | Default session CPU cores |
| `session_hours` | `4` | Default session duration |
| `session` | — | Extra `srun` args for all sessions |
| `special_session` | — | Extra `srun` args for `session --special` |
| `default_dest` | — | Default Singularity image destination |
| `packages_dir` | — | Package binaries directory |
| `packages_basepath` | — | Package installation base path |

<div class="metacpan-ref">
  <div class="metacpan-ref-icon">📖</div>
  <div class="metacpan-ref-body">
    <div class="metacpan-ref-title">Related API documentation on MetaCPAN</div>
    <div class="metacpan-ref-links">
      <a href="https://metacpan.org/pod/NBI::Slurm" target="_blank" rel="noopener">NBI::Slurm (load_config)</a>
      <a href="https://metacpan.org/pod/NBI::Opts" target="_blank" rel="noopener">NBI::Opts</a>
      <a href="https://metacpan.org/pod/NBI::EcoScheduler" target="_blank" rel="noopener">NBI::EcoScheduler</a>
      <a href="https://metacpan.org/dist/NBI-Slurm/view/bin/runjob" target="_blank" rel="noopener">runjob</a>
      <a href="https://metacpan.org/dist/NBI-Slurm/view/bin/session" target="_blank" rel="noopener">session</a>
    </div>
  </div>
</div>
