#!perl -w
use strict;
use Test::More;

plan skip_all => "Pod spelling: for maintainer only" unless -d "releases";
plan skip_all => "Test::Spelling required for checking Pod spell"
    unless eval "use Test::Spelling; 1";

if (`type spell 2>/dev/null`) {
    # default
}
elsif (`type aspell 2>/dev/null`) {
    set_spell_cmd('aspell -l --lang=en');
}
else {
    plan skip_all => "spell(1) command or compatible required for checking Pod spell"
}

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__

SAPER
Sébastien
Aperghis
Tramoni
Aperghis-Tramoni
Christiansen
Kobes
Hedden
Reini
Harnisch
AnnoCPAN
CPAN
README
TODO
AUTOLOADER
API
arrayref
arrayrefs
hashref
hashrefs
lookup
hostname
loopback
netmask
timestamp
INET
BPF
IP
TCP
tcp
UDP
udp
UUCP
NTP
FDDI
Firewire
HDLC
IEEE
IrDA
LocalTalk
PPP
unix
FreeBSD
NetBSD
Solaris
IRIX
endianness
failover
Failover
logopts
pathname
syslogd
Syslogging
logmask
AIX
SUSv
SUSv3
Tru
Tru64
UX
HP-UX
VOS
NetInfo
VPN
launchd
logalert
