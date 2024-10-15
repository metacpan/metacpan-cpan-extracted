# OSLV-Monitor

OS level virtualization monitoring extend for LibreNMS

## Install

#### FreeBSD

```shell
pkg install p5-JSON p5-Mime-Base64 p5-Clone p5-File-Slurp p5-IO-Interface
perl Makefile.pl
make
make test
make install
```

or...

```shell
pkg install p5-JSON p5-Mime-Base64 p5-Clone p5-File-Slurp p5-IO-Interface p5-App-cpanminus
cpanm OSLV::Monitor
```

#### Debian

```shell
apt-get install libjson-perl libclone-perl libmime-base64-perl libfile-slurp-perl libio-interface-perl
perl Makefile.pl
make
make test
make install
```

or...

```shell
apt-get install libjson-perl libclone-perl libmime-base64-perl libfile-slurp-perl libio-interface-perl cpanminus
cpanm OSLV::Monitor
```

## Setup

For cron...

```
*/5 * * * * /usr/local/bin/oslv_monitor -q
```

For snmpd...

```
extend oslv_monitor /bin/cat /var/cache/oslv_monitor/snmp
```

See `oslvm_monitor -h` for more information.

### Config File

The default location for the optional config file is
`/usr/local/etc/oslv_monitor.json`.

The following keys are used in the JSON config file.

    - include :: A array of regular expressions to include.
        Default :: ["^.*$"]

    - exlcude :: A array of regular expressions to exlclude.
        Default :: undef

    - backend :: Override the the backend and automatically choose it.

    - time_divider :: Override the time_divider value. The default value varies
        per backend and if it is needed.

Time divider notes.

    - cgroups :: While the default for usec to sec conversion should be 1000000,
              some settings report the value in nanoseconds, requiring 1000000000.
        Default :: 1000000

    - FreeBSD :: not used

By Defaults the backends are as below.

- FreeBSD: FreeBSD
- Linux: cgroups

Default would be like this.

```json
{
    "include": ["^.*$"]
}
```

## Stats

| Path                | Description                                                      |
|---------------------|------------------------------------------------------------------|
| .data.backend       | The backend used.                                                |
| .data.oslvms        | A hash of OSLVMs found containing the stats for each one.        |
| .data.oslvms.*.ip   | A array of IP information OSLVM. Detailed below.                 |
| .data.oslvms.*.path | A array of paths for the OSLVM.                                  |
| .data.totals        | A hash of the totals of the values for the OSLVMs.               |
| .data.has.*         | A hash of variables with a 0/1 boolean for what data is present. |

The IP information is as below. Each item in the array with the hashes below.

| Variable | Description                                               |
|----------|-----------------------------------------------------------|
| ip       | The IP address.                                           |
| if       | The interface for the IP.                                 |
| gw       | The gateway IP that will be used for it.                  |
| gw_if    | The interface that will be used for reaching the gateway. |

The has hash is used for telling LibreNMS if a specific set of graphs
should be displayed or not.

| Variable        | Description                                      |
|-----------------|--------------------------------------------------|
| linux_mem_stats | Has stuff from memory.stat for Linux cgroups v2. |
| rwdops          | Has read/write/discard op vars.                  |
| rwdbytes        | Has read/write/discard bytes vars.               |
| rwdblocks       | Has read/write/discard blocks vars.              |
| signals-taken   | Has signals taken info for procs.                |
| stack-size      | Has stack size info for procs.                   |
| cows            | Has COW fault vars.                              |
| swaps           | Has meaningful info on swap in/out.              |
| sock            | Has socket buffer size info.                     |

### FreeBSD Stats

The stats names match those produced by "ps --libxo json".

### Linux cgroup v2 Stats

The cgroup to name mapping is done like below.

    systemd -> s_$name
    user -> u_$name
    docker -> d_$name
    podman -> p_$name
    anything else -> $name

Anything else is formed like below.

```perl
$cgroup =~ s/^0\:\:\///;
$cgroup =~ s/\/.*//;
```

The following ps to stats mapping are as below.

- %cpu -> percent-cpu
- %mem -> percent-memory
- rss -> rss
- vsize -> virtual-size
- trs -> text-size
- drs -> data-size
- size -> size

"procs" is a total number of procs in that cgroup.

The rest of the values are pulled from the following files with
the names kept as is.

- cpu.stat
- io.stat
- memory.stat

The following mappings are done though.

    pgfault -> minor-faults
    pgmajfault -> major-faults
    usage_usec -> cpu-time
    system_usec -> system-time
    user_usec -> user-time
    throttled_usec -> throttled-time
    burst_usec -> burst-time
    core_sched.force_idle_usec -> core_sched.force_idle-time
