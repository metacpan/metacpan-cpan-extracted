# Sys::Monitor::Lite

A lightweight system monitoring toolkit. Using the `script/sys-monitor-lite` script you can collect CPU, memory, disk capacity, disk I/O, network, and other Linux metrics in JSON or YAML format. It runs entirely on Perl with no external dependencies.

## Features

- Lightweight implementation that simply reads data from `/proc`
- Collects CPU, load average, memory, disk capacity, disk I/O, network, system information, and lightweight process stats
- Allows you to choose which metrics to collect from the CLI
- Supports JSON / JSON Lines output (with `--pretty` for formatted JSON), YAML output, and Prometheus text exposition
- Reusable as a module (`Sys::Monitor::Lite`) so scripts can integrate it easily

## Installation

To install from CPAN:

```bash
cpanm Sys::Monitor::Lite
```

To use it directly from the repository:

```bash
git clone https://github.com/yourname/sys-monitor-lite.git
cd sys-monitor-lite
perl Makefile.PL && make install
```

You can also run the scripts in the repository directly without installing.

## Usage (Command Line)

### Collect metrics once

```bash
script/sys-monitor-lite --once
```

### Collect continuously at 5-second intervals (default)

```bash
script/sys-monitor-lite --interval 5
```

### Limit the metrics collected and output as JSON Lines

```bash
script/sys-monitor-lite --interval 10 --collect cpu,mem,disk --output jsonl
```

### Output as YAML

```bash
script/sys-monitor-lite --once --output yaml
```

### Prometheus text output (node_exporter alternative)

```bash
script/sys-monitor-lite --once --output prometheus --prefix sysmon_
```

Add `--labels host=...` to attach fixed labels and `--timestamp` to append sample timestamps to each metric line.

### Key options

| Option | Description |
| ----------- | ---- |
| `--interval <seconds>` | Interval for repeated collection. Defaults to 5 seconds. Values ≤ 0 collect only once. |
| `--once` | Collects metrics once. Equivalent to omitting `--interval`. |
| `--collect <list>` | Comma-separated list selecting from `system,cpu,load,mem,disk,disk_io,net,process`. |
| `--output <format>` | Choose `json` (default), `jsonl`, `yaml`, or `prometheus`. |
| `--pretty` | Format JSON output (`jsonl` ignores this). |
| `--prefix <name>` | Prefix metric names (useful for `--output prometheus`, e.g. `sysmon_`). |
| `--labels <k=v,...>` | Attach fixed labels to Prometheus output (e.g. `--labels host=web1,role=app`). |
| `--timestamp` | Append timestamps to all outputs (Prometheus uses the sample timestamp at the end of each line). |
| `--check` | Run once, evaluate thresholds, and exit with Nagios-style status codes (0=OK, 1=WARN, 2=CRIT). |
| `--warn <expr>` | Threshold expression like `mem.used_pct>80`. Can be repeated. Implies `--check`. |
| `--crit <expr>` | Critical threshold expression like `mem.used_pct>90`. Can be repeated. Implies `--check`. |
| `--top <field=count>` | Collect the top N processes by `cpu` or `rss` (e.g. `--top cpu=5`). Automatically enables the `process` metric. |
| `--watch <names>` | Comma-separated list of process names/commands to include (e.g. `--watch nginx,sssd`). |
| `--help` | Show help (POD). |

The JSON output can be combined with tools such as `jq` or `jq-lite`, and YAML output works nicely with tools like `yq`.

```bash
script/sys-monitor-lite --once | jq '.mem.used_pct'
```

### Threshold-based checks

For cron, Ansible, or Nagios-style alerting you can evaluate thresholds and exit with status codes:

```bash
script/sys-monitor-lite --check \
  --warn mem.used_pct>80 \
  --crit mem.used_pct>90
```

The command prints a compact summary such as `OK - mem.used_pct=42.1 (>80 >90)` and exits with 0/1/2 for OK/WARN/CRIT, respectively.

### Process monitoring shortcuts

You can request lightweight process data without pulling in `top` or `ps`:

```bash
# Top 5 CPU consumers
script/sys-monitor-lite --once --top cpu=5

# Top 5 memory consumers and specific daemons
script/sys-monitor-lite --once --top rss=5 --watch nginx,sssd
```

The `--top` and `--watch` switches automatically enable the `process` metric, returning PID, command, CPU %, RSS, state, threads, and UID for the matching processes.

## Using as a Perl Module

```perl
use Sys::Monitor::Lite qw(collect_all to_json);

my $metrics = collect_all();
print to_json($metrics, pretty => 1);
```

If you prefer YAML, call `to_yaml` instead:

```perl
print Sys::Monitor::Lite::to_yaml($metrics);
```

Instead of `collect_all`, you can pass an array reference like `collect(["cpu", "mem"])` to specify which metrics to gather.

## Available Data

- `system`: OS name, kernel version, hostname, architecture, uptime (seconds)
- `cpu`: Number of cores and aggregate CPU utilization (difference over ~100 ms)
- `load`: Load average over 1, 5, and 15 minutes
- `mem`: Total, used, and free memory, plus swap usage
- `disk`: Total capacity, used capacity, inode counts, and utilization for each mount point
- `mounts`: Mount table snapshot with filesystem type, options, and read-only status for each mount (usable for detecting missing or unexpected mounts)
- `disk_io`: Block device read/write I/O counters (bytes, sectors, operations)
- `net`: Received/sent bytes and packets per interface
- `process`: PID, parent PID, state, command, CPU %, RSS, threads, and UID per process (optionally filtered via `--top` / `--watch`)

## License

MIT License

## Author

Shingo Kawamura ([@kawamurashingo](https://github.com/kawamurashingo))
