#!perl
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
BPF
CRC
IP
TCP
UDP
FDDI
Firewire
HDLC
IEEE
IrDA
LocalTalk
PPP
LBL
libpcap
pcap
WinPcap
BOADLER
JLMOREL
KCARNUT
PLISTER
TIMPOTTER
Bruhat
Carnut
Lanning
Maischen
Pradene
savefile
Savefile
savefiles
Savefiles
snaplen
endianness
pcapinfo
errbuf
PerlMonks
iptables
