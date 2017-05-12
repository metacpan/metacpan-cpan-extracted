#!/bin/bash

HOST1=${1:-192.168.3.5}
HOST2=${1:-192.168.3.145}
NET=192.168.3.0/24
PORTS=1-1024
#  Services for network service location (whohas)
SERVICES=ftp,dns,netbios-ssn,netbios-dgm,ssh,ident

base=examples

while read cmd args
do

    cat <<EOF
----------------------------------------------------------------------
$cmd $args
----------------------------------------------------------------------
EOF

    perl $base/$cmd $args || exit 1

done <<EOF
diff_osguess.pl $HOST1 $HOST2
event_osguess.pl $HOST1 $PORTS
event_ping.pl $NET
event_scan_from_file.pl
event_scan_from_file.pl http://nmap-scanner.sf.net/scan-test.xml
fast_scan.pl $HOST2
ftpscan.pl $HOST2
rpc_scan.pl $HOST1
open_pipe.pl $HOST1
osguess.pl $HOST2 $PORTS
pingscan.pl $NET
protoscan.pl $HOST1
scan_to_xml.pl
smtp_scanner.pl $HOST1
svcgraph.pl $NET $PORTS
webscan.pl $HOST2
whohas.pl $SERVICES open $NET
EOF

exit
