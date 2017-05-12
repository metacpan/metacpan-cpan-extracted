use strict;
use warnings;
use Config;
use DynaLoader;
use ExtUtils::MakeMaker;

my %config = (
    'linux' => [
        '-D_LINUX_ -D_ETH_ -D_IFLIST_',
        'RawIP.o util.o eth.o ifaddrlist.o',
        '',
        q{ $def .= ' -D_GLIBC_' if -e "/usr/include/net/if_packet.h" }, 
    ],

    'solaris' => [ 
        '-D_SOLARIS_ -D_IFLIST_',
        'RawIP.o util.o ifaddrlist.o',
        "Sorry,ethernet related methods are not implemented on Solaris\n"
        . "Sorry, the rdev function is not imlemented on Solaris\n",
        '',         
    ],

    'freebsd' => [ 
        '-D_BSDRAW_ -D_ETH_ -D_BPF_ -D_IFLIST_ -DHAVE_SOCKADDR_SA_LEN',
        'RawIP.o util.o ifaddrlist.o eth.o rdev.o',
        '',
        '',
    ],

    'openbsd' => [
        '-D_ETH_ -D_BPF_ -D_IFLIST_ -DHAVE_SOCKADDR_SA_LEN',
        'RawIP.o util.o ifaddrlist.o eth.o rdev.o',
        '',
        q{ $def .= ' -D_BSDRAW_' if join('',(split /\./,$Config{osvers})[0,1]) < 21 },
    ],

    'others'   => [
        '',
        'RawIP.o util.o',
        "Sorry,ethernet related methods are not implemented on this system\n"
        . "Sorry, the ifaddrlist function is not imlemented on this system\n"
        . "Sorry, the rdev function is not imlemented on this system\n",
        '',
    ]
);          

$config{bsdos } = $config{freebsd};
$config{darwin} = $config{freebsd};
$config{netbsd} = $config{freebsd};

my $name = $Config{osname} || "others"; 
my $def = $config{$name}->[0] . (defined $ENV{CFLAGS} ? " $ENV{'CFLAGS'}" : "");
my $obj = $config{$name}->[1];
print $config{$name}->[2];
eval $config{$name}->[3];

print "Compiler: $Config{cc}\n";
system "$Config{cc} --version";

locate_pcap();


WriteMakefile(
    NAME            => 'Net::RawIP',
    LICENSE         => 'perl',
    AUTHOR          => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM    => 'lib/Net/RawIP.pm', 
    ABSTRACT_FROM   => 'lib/Net/RawIP.pm', 
    LIBS           => ['-lpcap'],   
    DEFINE         => $def,      
    INC            => '',      
    OBJECT         => $obj,
    PREREQ_PM      => {
        # prereqs
        'Carp'         => 0,
        'Class::Struct'=> 0,
        'Data::Dumper' => 0,
        'English'      => 0,
        'Getopt::Long' => 0,
        'Socket'       => 0,

        # build/test prereqs
        'Test::More'   => 0,
    },
    PL_FILES        => {},
);


sub locate_pcap {
    # temporary; in next releases, I'll just completely remove the pcap parts
    # from Net::RawIP and use Net::pcap instead

    my @paths = DynaLoader::dl_findfile("-lpcap");
    die <<'REASON' unless @paths;
Could not load the pcap library. Please see the README file on how
to install it. Be sure to also install the C headers (pcap.h).
REASON
}

