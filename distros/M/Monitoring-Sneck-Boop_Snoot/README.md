# Monitoring-Sneck-Boop_Snoot

This his basically a wrapper for smpget and nicely formatting
the returned output. Also saves one the headache of having to
remember the OID or have it handy.

## FLAGS

```
boop_snoot <args> <host>

-p                       Do not pretty print.

-s                       Do not Sort the keys.

-d                       Print all of it and not just .data

-v <version >            Version to use. 1, 2c, or 3
                         Default: 2c

SNMP Version 1 or 2c specific
-c <community>           SNMP community stream.
                         Default: public

SNMP Version 3
-a <value>               Set authentication protocol (MD5|SHA|SHA-224|SHA-256|SHA-384|SHA-512)
-A <value>               Set authentication protocol pass phrase
-e <value>               Set security engine ID (e.g. 800000020109840301)
-E <value>               Set context engine ID (e.g. 800000020109840301)
-l <value>               Set security level (noAuthNoPriv|authNoPriv|authPriv)
-n <value>               Set context name (e.g. bridge1)
-u <value>               Set security name (e.g. bert)
-x <value>               Set privacy protocol (DES|AES)
-X <value>               Set privacy protocol pass phrase
-Z <value>               Set destination engine boots/time

-h                       Print help info.
--help                   Print help info.
--version                Print version info.
```

## EXAMPLE

```
> boop_snoot nibbles1
{
   "alert" : 0,
   "alertString" : "",
   "checks" : {
      "geom_nibbles1" : {
         "check" : "/usr/local/libexec/nagios/check_geom mirror nibbles1",
         "exit" : 0,
         "output" : "OK mirror/nibbles1 COMPLETE { da0 (ACTIVE) , da1 (ACTIVE) }|geom_mirror=2;;;0;",
         "ran" : "/usr/local/libexec/nagios/check_geom mirror nibbles1"
      },
      "zfs_src" : {
         "check" : "/usr/local/libexec/nagios/check_zpools -p src",
         "exit" : 0,
         "output" : "ALL ZFS POOLS OK (src)|src=15%",
         "ran" : "/usr/local/libexec/nagios/check_zpools -p src"
      },
      "zfs_storage" : {
         "check" : "/usr/local/libexec/nagios/check_zpools -p storage",
         "exit" : 0,
         "output" : "ALL ZFS POOLS OK (storage)|storage=18%",
         "ran" : "/usr/local/libexec/nagios/check_zpools -p storage"
      }
   },
   "critical" : 0,
   "errored" : 0,
   "hostname" : "nibbles1",
   "ok" : 3,
   "time" : 1651728300,
   "unknown" : 0,
   "vars" : {
      "PATH" : "/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
   },
   "warning" : 0
}
```
