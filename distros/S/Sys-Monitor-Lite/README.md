# Sys::Monitor::Lite

A lightweight system monitoring toolkit. Using the `script/sys-monitor-lite` script you can collect CPU, memory, disk capacity, disk I/O, network, and other Linux metrics in JSON format. It runs entirely on Perl with no external dependencies.

## Features

- Lightweight implementation that simply reads data from `/proc`
- Collects CPU, load average, memory, disk capacity, disk I/O, network, and system information
- Allows you to choose which metrics to collect from the CLI
- Supports JSON / JSON Lines output, with `--pretty` for formatted JSON
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

### Key options

| Option | Description |
| ----------- | ---- |
| `--interval <seconds>` | Interval for repeated collection. Defaults to 5 seconds. Values ≤ 0 collect only once. |
| `--once` | Collects metrics once. Equivalent to omitting `--interval`. |
| `--collect <list>` | Comma-separated list selecting from `system,cpu,load,mem,disk,disk_io,net`. |
| `--output <format>` | Choose `json` (default) or `jsonl`. |
| `--pretty` | Format JSON output (`jsonl` ignores this). |
| `--help` | Show help (POD). |

The JSON output can be combined with tools such as `jq` or `jq-lite`.

```bash
script/sys-monitor-lite --once | jq '.mem.used_pct'
```

## Using as a Perl Module

```perl
use Sys::Monitor::Lite qw(collect_all to_json);

my $metrics = collect_all();
print to_json($metrics, pretty => 1);
```

Instead of `collect_all`, you can pass an array reference like `collect(["cpu", "mem"])` to specify which metrics to gather.

## Available Data

- `system`: OS name, kernel version, hostname, architecture, uptime (seconds)
- `cpu`: Number of cores and aggregate CPU utilization (difference over ~100 ms)
- `load`: Load average over 1, 5, and 15 minutes
- `mem`: Total, used, and free memory, plus swap usage
- `disk`: Total capacity, used capacity, and utilization for each mount point
- `disk_io`: Block device read/write I/O counters (bytes, sectors, operations)
- `net`: Received/sent bytes and packets per interface

## License

MIT License

## Author

Shingo Kawamura ([@kawamurashingo](https://github.com/kawamurashingo))
