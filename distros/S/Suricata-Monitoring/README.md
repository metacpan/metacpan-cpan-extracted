# Suricata-Monitoring

LibreNMS JSON SNMP extend and Nagios style check for Suricata stats.

For Nagious, this should be ran via NRPE.

For LibreNMS, this should be set up to run from cron and as a snmp extend.

cron...

`*/5 * * * * /usr/local/bin/suricata_stat_check`

## SYNOPSIS

```
suricata_stats_check [B<-m> single] [B<-s> <eve>] [B<-S> <instance name>] [B<-d> <drop percent warn>]
[B<-D> <drop percent crit>]  [B<-e> <error delta warn>] [B<-E> <error delta crit>]
[B<-r> <error percent warn>] [B<-r> <error percent crit>]

suricata_stats_check B<-m> slug [B<-s> <slug>] [B<-l> <log dir>]  [B<-d> <drop percent warn>]
[B<-D> <drop percent crit>]  [B<-e> <error delta warn>] [B<-E> <error delta crit>]
[B<-r> <error percent warn>] [B<-r> <error percent crit>]

suricata_stats_check B<-m> manual B<-1> <manual>  [B<-d> <drop percent warn>]
[B<-D> <drop percent crit>]  [B<-e> <error delta warn>] [B<-E> <error delta crit>]
[B<-r> <error percent warn>] [B<-r> <error percent crit>] [B<-2> <manual>] [B<-3> <manual>]
[B<-4> <manual>] [B<-5> <manual>] [B<-6> <manual>] [B<-7> <manual>]
[B<-8> <manual>] [B<-9> <manual>] [B<-0> <manual>]
```

## Flags

```
-m <mode>                Mode to run in.
                         Default: single

-s <eve>                 Eve file for use with single mode.
                         Default: /var/log/suricata/eve.json
-S <instance name>       Instance name to use in single mode.
                         Default: ids

-s <slug>                The slug to use in slug mode.
                         Default: alert
-l <log dir>             Log directory for slug mode.
                         Default: /var/log/suricata

-0 <manual>              A file to use in manual mode.
-1 <manual>              A file to use in manual mode.
-2 <manual>              A file to use in manual mode.
-3 <manual>              A file to use in manual mode.
-4 <manual>              A file to use in manual mode.
-5 <manual>              A file to use in manual mode.
-6 <manual>              A file to use in manual mode.
-7 <manual>              A file to use in manual mode.
-8 <manual>              A file to use in manual mode.
-9 <manual>              A file to use in manual mode.
-0 <manual>              A file to use in manual mode.

-c                       Print the cache and exit.

-d <drop percent warn>   Percent of drop packets to warn on.
                         Default: 0.75%
-D <drop percent crit>   Percent of dropped packets to critical on.
                         Default: 1%
-e <error delta warn>    Error delta to warn on.
                         Default: 1
-E <error delta crit>    Error delta to critical on.
                         Default: 2
-r <error percent warn>  Percent of drop packets to warn on.
                         Default: 0.05%
-R <error percent crit>  Percent of drop packets to warn on.
                         Default: 0.1%

-n                       Run as a nagios check style instead of LibreNMS.

-h                       Print help info.
--help                   Print help info.
-v                       Print version info.
--version                Print version info.
```

## Modes

### single

Use the specified eve file, -e, and the specified instance name, -i.

### slug

Check the dir specified, -l. for files starting with the
slug, -s. The files must match
`/^$slug\-[A-Za-z\_\-]\.[Jj][Ss][Oo][Nn]$/`. The instance name is formed
by removing `/^$slug\-/` and `/\.[Jj][Ss][Oo][Nn]$/`. So
"alert-ids.json" becomes "ids".

### manual

Use the files specified via -0 to -9 to specify instance
names and files. The value taken by each of those is comma seperated
with the first part being the instance name and the second being the
eve file. So "inet,/var/log/suricata/inet.json" would be a instance
name of "inet" with a eve file of "/var/log/suricata/inet.json".
