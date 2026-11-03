# Monitoring::Sneck::Checks

Nagios style checks written in Perl, run in process by
[sneck](https://github.com/VVelox/Monitoring-Sneck) instead of as a
program per check.

```
www|perl:http -H www.example.org -S -w 1 -c 2 -s Welcome
www_cert|perl:https_cert -H www.example.org -w 30 -c 14
dns_www|perl:dns -H www.example.org -a 192.0.2.10
backup_age|perl:file_age -f /var/backups/db.sql.gz -w 90000 -c 180000
```

They can also be run from the shell, or used as a nagios plugin, via
`sneck_check`. `--list-checks` lists them and `--help` with a check
prints its docs.

```
sneck_check http -H www.example.org -S -w 1 -c 2
sneck_check --help http
sneck_check --list-checks
```

## Checks

- accounts :: UID 0, empty passwords, duplicates, system accounts with login shells, and accounts that must or must not be there.
- cciss :: HP Smart Array controllers through cciss_vol_status, volumes, drives, spares, enclosures, and cache.
- cert_dir :: Every certificate in directories, without naming each file.
- cert_file :: Certificate files, every certificate in each, plus the key and names.
- checksums :: Files against stored checksums, in sha256sum or FreeBSD sha256 format.
- config_value :: Values in config files such as login.defs, rc.conf, and sysctl.conf, with =, !=, <, <=, >, and >=.
- conntrack :: How full the connection tracking table is, conntrack on Linux or pf's states on FreeBSD.
- containers :: Docker or Podman containers running, healthy, and not stuck restarting.
- debsecan :: Debian security fixes waiting to be installed, through debsecan.
- disk :: How full file systems are, space and inodes.
- dns :: A DNS lookup, its answers, and how long it took.
- dns_sync :: That a zone's nameservers all answer, are authoritative, and have the same serial.
- file_age :: How old and how big a file is.
- file_handles :: Open files against the system wide limit.
- file_mode :: The mode, owner, and group of files.
- hosts :: /etc/hosts, and names in it mapping to the right address.
- http :: HTTP and HTTPS, the status, content, XPath, and response time.
- http_json :: Values in a JSON response, such as a health endpoint.
- https_cert :: The certificate a TLS server hands out, directly or through STARTTLS for SMTP, IMAP, POP3, FTP, and LDAP.
- interface :: Network interfaces being up, at speed and full duplex, with the right MTU, and errors and drops per second.
- jails :: FreeBSD jails running, every one in jail.conf if wanted, and vm-bhyve VMs.
- kernel_modules :: Kernel modules loaded or not, and kept from loading through modprobe.d, as CIS wants.
- listening :: Ports being listened on, and optionally nothing else.
- load :: The load averages, optionally per CPU.
- log :: New lines in a log matching a regex, with rotation handled and matches held for a while.
- memory :: How much memory is used, optionally counting the ZFS ARC as available.
- mount :: That fstab's file systems are mounted, and not gone read only.
- neighbors :: How full the ARP and NDP neighbor tables are, and if they filled since the last run.
- ntp :: How far the local clock is off from a NTP server.
- oom :: Processes killed by the OOM killer since the last run, held for a while if wanted.
- packages :: Packages installed or not, through dpkg or pkg, jails included.
- pid_file :: The process in a PID file running, and being what it should be.
- ping :: Packet loss and round trip time, over ICMP, TCP, or UDP.
- pkg_audit :: FreeBSD packages with known vulnerabilities, through pkg audit, jails included.
- pressure :: Time stalled on CPU, memory, and IO, from Linux pressure stall information.
- procs :: How many processes match a name, command line, user, or state.
- rbl :: If a host is on DNS block lists.
- reboot_needed :: Updates waiting on a reboot, and processes still using replaced libraries.
- resolv :: /etc/resolv.conf, and that its nameservers answer.
- sensors :: Temperatures, fans, and voltages from hwmon, without lm-sensors, or FreeBSD's temperatures.
- service :: Services running, and optionally enabled, through systemd or service, jails included.
- smtp :: A SMTP server, its greeting, EHLO extensions, STARTTLS, and response time.
- sshd_config :: Settings in sshd_config, read the way sshd does.
- swap :: How much swap is used, across every device.
- swraid :: Software RAID, md on Linux and gmirror and graid on FreeBSD, degraded, failed, or rebuilding.
- sysctl :: Sysctl values, with =, !=, <, <=, >, and >=.
- systemd_failed :: Failed systemd units.
- tcp :: A TCP service, optionally over TLS, with send and expect.
- tls_protocols :: What TLS versions a server takes, such as it refusing TLS 1.0 and 1.1, STARTTLS included.
- uptime :: How long the host has been up, catching reboots no one planned.

Those that look at the host, such as disk, interface, listening, and
sysctl, work on Linux and FreeBSD, except neighbors, oom, pressure,
and systemd_failed, which are Linux only, as is procs with
`--fd-warning` or `--fd-critical`, debsecan, which is Debian only, and
jails and pkg_audit, which are FreeBSD only.

Each check's POD lists its options, such as `perldoc
Monitoring::Sneck::Checks::http`.

## Return Codes

Codes are the nagios ones, 0 to 3, except for -1, which means the check
could not be loaded. That is what a bad name, `base`, a module that is
not there, or one that is not a `Monitoring::Sneck::Checks::base` gets. Bad args, timing out, and the check dying are
UNKNOWN.

## Writing Checks

A check is a module named `Monitoring::Sneck::Checks::$name` that
subclasses `Monitoring::Sneck::Checks::base`, which has the shared
helpers, such as option parsing, nagios style ranges, perfdata, and
setting up LWP and Net::DNS with the timeout. See its POD.

## Install

### From Source

```
perl Makefile.PL
make
make test
make install
```

### FreeBSD

```
pkg install p5-libwww p5-LWP-Protocol-https p5-HTTP-Message p5-Net-DNS p5-Net-IP \
    p5-Data-Validate-Domain p5-Data-Validate-IP p5-File-Slurp p5-XML-LibXML \
    p5-IO-Socket-SSL p5-Net-SSLeay p5-IO-Socket-IP p5-JSON p5-JSON-XS p5-Filesys-Df \
    p5-Proc-ProcessTable p5-BSD-Sysctl
```

Then install from source as above.

### Debian

```
apt-get install libwww-perl liblwp-protocol-https-perl libhttp-message-perl libnet-dns-perl \
    libnet-ip-perl libdata-validate-domain-perl libdata-validate-ip-perl libfile-slurp-perl \
    libxml-libxml-perl libio-socket-ssl-perl libnet-ssleay-perl libjson-perl libjson-xs-perl libfilesys-df-perl \
    libproc-processtable-perl
```

Then install from source as above.
