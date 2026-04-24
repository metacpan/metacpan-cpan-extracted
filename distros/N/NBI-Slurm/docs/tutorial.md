---
layout: default
title: "Tutorial"
description: "Step-by-step guide to submitting and managing SLURM jobs with NBI::Slurm."
sidebar: true
toc:
  - { id: "installation", title: "Installation" }
  - { id: "first-job", title: "Your first job" }
  - { id: "resources", title: "Specifying resources" }
  - { id: "array-jobs", title: "Array jobs" }
  - { id: "dependencies", title: "Job dependencies" }
  - { id: "perl-api", title: "Perl API" }
  - { id: "monitoring", title: "Monitoring the queue" }
  - { id: "interactive", title: "Interactive sessions" }
  - { id: "eco", title: "Eco scheduling" }
  - { id: "cli-reference", title: "CLI reference" }
---

<nav class="toc" aria-label="Contents">
  <div class="toc-title">Contents</div>
  <ul>
    <li><a href="#installation">Installation</a></li>
    <li><a href="#first-job">Your first job</a></li>
    <li><a href="#resources">Specifying resources</a></li>
    <li><a href="#array-jobs">Array jobs</a></li>
    <li><a href="#dependencies">Job dependencies</a></li>
    <li><a href="#perl-api">Perl API</a>
      <ul>
        <li><a href="#nbi-job">NBI::Job</a></li>
        <li><a href="#nbi-opts">NBI::Opts</a></li>
        <li><a href="#nbi-queue">NBI::Queue</a></li>
      </ul>
    </li>
    <li><a href="#monitoring">Monitoring the queue</a></li>
    <li><a href="#interactive">Interactive sessions</a></li>
    <li><a href="#eco">Eco scheduling</a></li>
    <li><a href="#cli-reference">CLI quick reference</a></li>
  </ul>
</nav>

# Tutorial

This tutorial walks through NBI::Slurm from installation to advanced features.
All API documentation links point to the [official MetaCPAN pages](https://metacpan.org/dist/NBI-Slurm).

---

## Installation {#installation}

Install from CPAN using `cpanm` (recommended) or the standard `cpan` client:

```bash
# Using cpanm (recommended)
cpanm NBI::Slurm

# Using the standard cpan client
cpan NBI::Slurm
```

After installation, create your personal config file:

```bash
configuration
```

This generates `~/.nbislurm.config` with all available keys. Open it in a text editor and set at least:

```ini
email=your@institution.ac.uk
queue=your-default-queue
```

See the [Configuration page](../configuration/) for the full reference.

<div class="callout callout-tip">
  <div class="callout-title">Tip</div>
  Every CLI tool reads <code>~/.nbislurm.config</code> automatically. Setting defaults there means fewer flags to type on every invocation.
</div>

---

## Your first job {#first-job}

### Dry run (preview)

By default, `runjob` **prints** the generated bash script without submitting it.
This lets you verify the script before sending it to the scheduler:

```bash
runjob "echo hello from SLURM"
```

Output (the generated script, not yet submitted):

```bash
#!/bin/bash
#SBATCH --job-name=job-a3f9
#SBATCH --output=/tmp/job-a3f9-%j.out
#SBATCH --error=/tmp/job-a3f9-%j.err
#SBATCH --partition=nbi-short
#SBATCH --time=0-02:00:00
#SBATCH --ntasks=1
#SBATCH --mem=8000MB

echo hello from SLURM
```

### Submitting

Add `--run` (or `-r`) to actually submit:

```bash
runjob --run "echo hello from SLURM"
# Submitted batch job 123456
```

<div class="callout callout-info">
  <div class="callout-title">Note</div>
  Full <code>runjob</code> documentation is on MetaCPAN:
  <a href="https://metacpan.org/dist/NBI-Slurm/view/bin/runjob" target="_blank" rel="noopener">
    metacpan.org/dist/NBI-Slurm/view/bin/runjob ↗
  </a>
</div>

---

## Specifying resources {#resources}

### Cores, memory, and time

```bash
runjob \
  --name    "alignment"   \   # job name (--name / -n)
  --cores   8             \   # CPU cores (--cores / -c)
  --memory  16GB          \   # RAM (--memory / -m); supports KB/MB/GB/TB
  --time    4h            \   # wall-clock limit (--time / -T); supports h/m/d/s
  --queue   nbi-long      \   # partition (--queue / -q)
  --run                   \   # actually submit
  "bwa mem ref.fa r1.fastq r2.fastq > aln.sam"
```

### Time formats

`runjob` (and the Perl `NBI::Opts`) accept flexible time strings:

| Input | Meaning |
|-------|---------|
| `2h` | 2 hours |
| `30m` | 30 minutes |
| `1d` | 1 day |
| `1d12h` | 36 hours |
| `90m` | 1 hour 30 minutes |
| `2` | 2 hours (bare integer) |

### Memory formats

| Input | Meaning |
|-------|---------|
| `8000` | 8000 MB (bare integer = MB) |
| `8GB` | 8 gigabytes |
| `500MB` | 500 megabytes |
| `2TB` | 2 terabytes |

### Email notifications

```bash
runjob --email-address "you@lab.ac.uk" --mail-type END,FAIL --run "long_job.sh"
```

Or set `email` and `email_type` in `~/.nbislurm.config` to avoid repeating them every time.

### GPU jobs

```bash
runjob --gpu --cores 4 --memory 32GB --time 8h --run "train_model.py"
```

The `--gpu` flag automatically uses the GPU queue (`gpuqueue` in your config).

### Scheduling at a specific time

```bash
# Start tonight at 22:00
runjob --run --start-time 22:00 "overnight_job.sh"

# Start on a specific date
runjob --run --start-time 02:00 --start-date 25/12 "christmas_job.sh"
```

### Extra SBATCH directives

Pass any raw `#SBATCH` option via `--option`:

```bash
runjob --option "--constraint=intel" --option "--exclusive" --run "benchmark.sh"
```

---

## Array jobs {#array-jobs}

Array jobs let you run the same script on many inputs in parallel.
Pass a list of files with `--files` and a placeholder token with `--placeholder`
(default: `#FILE#`):

### From a shell glob

```bash
runjob \
  --name "variant-call"  \
  --files "*.bam"        \
  --cores 4              \
  --memory 8GB           \
  --run                  \
  "gatk HaplotypeCaller -I #FILE# -O #FILE#.vcf"
```

NBI::Slurm generates a SLURM job array that automatically expands `#FILE#`
to each matched path. If 50 BAM files match, 50 tasks are submitted as a single array job.

### From an explicit list

```bash
runjob --name "process" --files "sample1.txt,sample2.txt,sample3.txt" \
       --run "process.sh #FILE#"
```

### Custom placeholder

```bash
runjob --files "*.fastq" --placeholder "{INPUT}" --run "trim.sh {INPUT}"
```

<div class="callout callout-tip">
  <div class="callout-title">How it works</div>
  The generated script uses a bash array and <code>${SLURM_ARRAY_TASK_ID}</code> to select the correct file for each task. The full SLURM <code>--array=0-N</code> directive is added automatically.
</div>

### Array jobs in Perl

```perl
use NBI::Slurm;

my @files = glob("data/*.bam");

my $opts = NBI::Opts->new(
    -queue       => "short",
    -threads     => 4,
    -memory      => "8GB",
    -files       => \@files,         # enables array mode
    -placeholder => "#FILE#",
);

my $job = NBI::Job->new(
    -name    => "variant-call",
    -command => "gatk HaplotypeCaller -I #FILE# -O #FILE#.vcf",
    -opts    => $opts,
);

my $jobid = $job->run();
print "Array job submitted: $jobid (", scalar(@files), " tasks)\n";
```

---

## Job dependencies {#dependencies}

### CLI: `--after`

Run a job only after another job (by ID) completes successfully:

```bash
# Submit step 1
JOB1=$(runjob --run "step1.sh" | grep -oP '\d+')

# Submit step 2, depends on step 1
runjob --after $JOB1 --run "step2.sh"
```

### CLI: `waitjobs`

Alternatively, block a shell script until jobs matching a pattern finish:

```bash
# Submit analysis jobs (all named "analysis-*")
for sample in *.fastq; do
    runjob -n "analysis-$sample" -r "analyse.sh $sample"
done

# Wait for them all
waitjobs -n "analysis-"

# Now run the merge
runjob -n "merge" -r "merge_results.sh"
```

`waitjobs` polls the queue every 20 seconds (configurable with `--refresh`) and
exits only when no matching jobs remain.

Full documentation: [metacpan.org/dist/NBI-Slurm/view/bin/waitjobs ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/waitjobs)

### Perl: multi-step pipeline

```perl
use NBI::Slurm;

my $opts = NBI::Opts->new(-queue => "short", -hours => 2);

# Step 1
my $job1 = NBI::Job->new(
    -name    => "step1",
    -command => "align.sh sample.fastq",
    -opts    => $opts,
);
my $id1 = $job1->run();

# Step 2: add dependency via raw SBATCH option
$opts->add_option("--dependency=afterok:$id1");
my $job2 = NBI::Job->new(
    -name    => "step2",
    -command => "call_variants.sh sample.bam",
    -opts    => $opts,
);
my $id2 = $job2->run();

print "Pipeline: $id1 -> $id2\n";
```

---

## Perl API {#perl-api}

The Perl API exposes four main classes. Full method references are on MetaCPAN.

### NBI::Job {#nbi-job}

[metacpan.org/pod/NBI::Job ↗](https://metacpan.org/pod/NBI::Job)

`NBI::Job` represents a job to be submitted. Build it, configure it, call `run()`.

```perl
use NBI::Slurm;

my $job = NBI::Job->new(
    -name     => "my-job",           # optional, random name if omitted
    -command  => "echo hello",       # single command
    # -commands => ["cmd1", "cmd2"], # OR a list of commands
    -opts     => $opts_object,       # NBI::Opts (see below)
);

# Add commands after creation
$job->append_command("echo step 2");
$job->prepend_command("module load bwa");

# Set output/error files (use %j for job ID)
$job->outputfile = "/scratch/logs/job-%j.out";
$job->errorfile  = "/scratch/logs/job-%j.err";

# Preview the generated script without submitting
print $job->script();

# Submit and get the job ID
my $jobid = $job->run();  # returns 0 on failure
```

**Key lvalue accessors** (can be used as `$job->name = "x"` or `my $x = $job->name`):

| Accessor | Type | Description |
|----------|------|-------------|
| `name` | String | Job name |
| `outputfile` | String | stdout log path (supports `%j`) |
| `errorfile` | String | stderr log path (supports `%j`) |
| `script_path` | String | Path where the generated script is written |

### NBI::Opts {#nbi-opts}

[metacpan.org/pod/NBI::Opts ↗](https://metacpan.org/pod/NBI::Opts)

`NBI::Opts` holds all the SLURM resource options.

```perl
my $opts = NBI::Opts->new(
    -queue         => "nbi-short",
    -threads       => 8,
    -memory        => "16GB",    # or bare MB: 16000
    -time          => "4h",      # or "1d", "90m", integer hours
    -email_address => "me@lab.ac.uk",
    -email_type    => "END,FAIL",
    -tmpdir        => "/scratch/tmp",
);

# Lvalue setters
$opts->queue   = "nbi-long";
$opts->threads = 16;
$opts->memory  = "32GB";
$opts->hours   = 8;          # always in hours internally

# Extra raw SBATCH directives
$opts->add_option("--constraint=intel");
$opts->add_option("--exclusive");

# Array job mode
$opts->files = ["file1.txt", "file2.txt", "file3.txt"];
$opts->placeholder = "#INPUT#";

# Scheduled start (defer to a specific time)
$opts->start_time = "22:00";   # HH:MM (24-hour)
$opts->start_date = "25/12";   # DD/MM or DD/MM/YYYY

# Inspect the generated SBATCH header
print $opts->header();
```

### NBI::Queue {#nbi-queue}

[metacpan.org/pod/NBI::Queue ↗](https://metacpan.org/pod/NBI::Queue)

Query the live SLURM queue. Returns a collection of [NBI::QueuedJob](https://metacpan.org/pod/NBI::QueuedJob) objects.

```perl
use NBI::Slurm;

# All jobs for current user
my $queue = NBI::Queue->new(-username => $ENV{USER});
print "You have ", $queue->len(), " jobs in the queue\n";

# Filter by job name (regex)
my $analysis = NBI::Queue->new(
    -username => $ENV{USER},
    -name     => "analysis",
);

# Filter by state
my $pending = NBI::Queue->new(
    -username => $ENV{USER},
    -state    => "PD",
);

# Get all job IDs
my @ids = $queue->ids();

# Iterate
for my $job ($queue->jobs()) {
    printf "  %7d  %-20s  %s\n",
        $job->jobid, $job->name, $job->status;
}
```

Valid states: `PD` (pending), `R` (running), `CG` (completing), `CD` (completed),
`F` (failed), `CA` (cancelled), `TO` (timeout), and others.

---

## Monitoring the queue {#monitoring}

### lsjobs — view and manage your jobs

```bash
# All your jobs
lsjobs

# Running only
lsjobs --running

# Pending only
lsjobs --pending

# Summary for your jobs vs all jobs
lsjobs --summary

# Filter by name (supports regex)
lsjobs --name "analysis"

# All users' jobs on a specific queue
lsjobs -u all --queue nbi-long

# Delete matching jobs (prompts for confirmation)
lsjobs --delete --name "test-"

# Tab-separated output for scripting
lsjobs --tab -u username | awk '{print $1}'

# Summary for a specific user vs all jobs
lsjobs --summary -u username
```

Full documentation: [metacpan.org/dist/NBI-Slurm/view/bin/lsjobs ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/lsjobs)

### whojobs — see what everyone is running

```bash
# All active users
whojobs

# Users with 10 or more jobs
whojobs --min-jobs 10

# Find a specific person's usage
whojobs alice

# Privacy-safe anonymised view
whojobs --scramble
```

Full documentation: [metacpan.org/dist/NBI-Slurm/view/bin/whojobs ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/whojobs)

### shelf — find installed software

```bash
# Search for bwa
shelf bwa

# Search in testing packages
shelf --stage testing samtools

# List all Singularity images
shelf --new-catalogue

# Refresh the cache if it's stale
shelf --refresh bwa
```

Full documentation: [metacpan.org/dist/NBI-Slurm/view/bin/shelf ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/shelf)

---

## Interactive sessions {#interactive}

The `session` command requests an interactive bash shell on the cluster:

```bash
# Default session (1 core, 1 GB, 4 hours)
session

# 4 cores, 16 GB, 8 hours
session -c 4 -m 16GB -h 8

# 1 day and 4 hours
session -d 1 -h 4

# With Intel processor constraint (if your cluster supports it)
session --intel

# Special session (uses special_session config params)
session --special
```

The queue is auto-selected based on duration:
- ≤ 2 hours → short queue
- ≤ 8 hours → medium queue
- > 8 hours → long queue

Set `session_memory`, `session_cpus`, and `session_hours` in `~/.nbislurm.config`
to change the defaults.

Full documentation: [metacpan.org/dist/NBI-Slurm/view/bin/session ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/session)

---

## Eco scheduling {#eco}

The EcoScheduler defers jobs to cheap electricity windows such as overnight off-peak hours.

### Using eco mode from the CLI

```bash
# Force eco scheduling on for this job
runjob --eco --run "long_computation.sh"

# Force it off even if eco_default=1 in config
runjob --no-eco --run "urgent_task.sh"
```

When eco mode is active, `runjob` calls `NBI::EcoScheduler::find_eco_begin()`
to calculate the next suitable start time and adds `--begin=...` to the SBATCH header.

### Configuring eco windows

In `~/.nbislurm.config`:

```ini
eco_default=1                          # enable by default for all jobs

eco_windows_weekday=00:00-06:00        # Mon–Fri cheap window
eco_windows_weekend=00:00-07:00,11:00-16:00  # Sat–Sun cheap windows
eco_avoid=17:00-20:00                  # peak hours to avoid every day
eco_lookahead_days=3                   # search up to 3 days ahead
```

### Tier system

The scheduler tries three tiers of slot quality:

| Tier | Criteria | Result |
|------|----------|--------|
| 1 (ideal) | Fits entirely in eco window AND avoids peak hours | Best |
| 2 (acceptable) | Avoids peak hours, may run past the eco window | Good |
| 3 (fallback) | Starts in eco window but might overlap peak hours | Acceptable |

If no slot is found within `eco_lookahead_days`, the job is submitted immediately.

### Using EcoScheduler in Perl

```perl
use NBI::EcoScheduler qw(find_eco_begin epoch_to_slurm format_delay);

my %config = (
    eco_windows_weekday => '00:00-06:00',
    eco_windows_weekend => '00:00-07:00,11:00-16:00',
    eco_avoid           => '17:00-20:00',
    eco_lookahead_days  => 3,
);

my ($begin_epoch, $tier) = find_eco_begin(2, \%config);  # 2-hour job

if (defined $begin_epoch) {
    my $slurm_time = epoch_to_slurm($begin_epoch);
    my $delay      = format_delay($begin_epoch, time());
    print "Scheduling in $delay (tier $tier): --begin=$slurm_time\n";
}
```

Full API documentation: [metacpan.org/pod/NBI::EcoScheduler ↗](https://metacpan.org/pod/NBI::EcoScheduler)

---

## CLI quick reference {#cli-reference}

### runjob options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--name` | `-n` | auto | Job name |
| `--cores` | `-c` | 1 | CPU cores |
| `--memory` | `-m` | 8000 MB | Memory |
| `--time` | `-T` | 2h | Time limit |
| `--queue` | `-q` | from config | SLURM partition |
| `--files` | `-f` | — | File list for array jobs |
| `--placeholder` | — | `#FILE#` | Array job token |
| `--email-address` | `-a` | from config | Notification email |
| `--mail-type` | `-e` | none | `BEGIN`/`END`/`FAIL`/`ALL` |
| `--after` | — | — | Depend on job ID(s) |
| `--gpu` | — | off | Use GPU queue |
| `--eco` | — | from config | Eco scheduling on |
| `--no-eco` | — | — | Eco scheduling off |
| `--option` | — | — | Extra `#SBATCH` directive |
| `--run` | `-r` | off | Actually submit (else preview) |

[Full runjob docs on MetaCPAN ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/runjob)

### lsjobs options

| Option | Short | Description |
|--------|-------|-------------|
| `--user` | `-u` | Username (default: current user) |
| `--name` | `-n` | Filter by name (regex) |
| `--running` | `-r` | Show only running jobs |
| `--pending` | `-p` | Show only pending jobs |
| `--queue` | — | Filter by partition |
| `--delete` | `-d` | Cancel selected jobs |
| `--tab` | `-t` | Tab-separated output |

[Full lsjobs docs on MetaCPAN ↗](https://metacpan.org/dist/NBI-Slurm/view/bin/lsjobs)

<div class="metacpan-ref">
  <div class="metacpan-ref-icon">📖</div>
  <div class="metacpan-ref-body">
    <div class="metacpan-ref-title">Complete API documentation on MetaCPAN</div>
    <p style="font-size:0.88rem;color:var(--text-muted);margin:0 0 0.2rem">
      For the full parameter lists, return values, and edge cases, refer to the official MetaCPAN documentation.
    </p>
    <div class="metacpan-ref-links">
      <a href="https://metacpan.org/dist/NBI-Slurm/view/bin/runjob" target="_blank" rel="noopener">runjob</a>
      <a href="https://metacpan.org/dist/NBI-Slurm/view/bin/lsjobs" target="_blank" rel="noopener">lsjobs</a>
      <a href="https://metacpan.org/dist/NBI-Slurm/view/bin/waitjobs" target="_blank" rel="noopener">waitjobs</a>
      <a href="https://metacpan.org/dist/NBI-Slurm/view/bin/whojobs" target="_blank" rel="noopener">whojobs</a>
      <a href="https://metacpan.org/dist/NBI-Slurm/view/bin/session" target="_blank" rel="noopener">session</a>
      <a href="https://metacpan.org/dist/NBI-Slurm/view/bin/shelf" target="_blank" rel="noopener">shelf</a>
    </div>
  </div>
</div>
