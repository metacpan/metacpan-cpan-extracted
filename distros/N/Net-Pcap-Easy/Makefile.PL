
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Net::Pcap::Easy',
    'VERSION_FROM'  => 'Easy.pm',

    'PREREQ_PM'     => { 
        # NOTE: They have to be root *and* specify a device to run the tests on, 
        # if they're going to get that interactive they're probably not CPAN testers anyway.
        #
        # 'WWW::Mechanize' => 0,
        # 'Net::Ping'      => 0,
        'File::Slurp'         => 0, # the tests won't compile at all without this though

        'Net::Pcap'           => 0,
        'NetPacket::Ethernet' => 0,
        'NetPacket::IP'       => 0,
        'NetPacket::TCP'      => 0,
        'NetPacket::UDP'      => 0,
        'NetPacket::ARP'      => 0,
        'NetPacket::ICMP'     => 0,
        'Net::Netmask'        => 0,
        'Socket'              => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => ['pcap', 'sniffer'],
                resources=> {
                    repository => 'http://github.com/jettero/net--pcap--easy/',
                },
            },

        LICENSE	=> 'LGPL',
    ) : ()),

    clean => { FILES => 'device' },
);

my $dev = $ENV{TEST_DEVICE}
       || prompt( "network device on which to run tests (e.g., eth0, must be root): ", "skip");
   $dev = "" if $dev =~ m/skip/;

open my $dh, ">", "device" or die $!;
print $dh $dev;
close $dh;
