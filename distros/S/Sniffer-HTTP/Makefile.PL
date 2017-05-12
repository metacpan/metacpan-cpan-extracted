use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

eval {
    require Net::Pcap;
};
if (! $@) {
    if (&Net::Pcap::lib_version() eq 'libpcap version unknown (pre 0.8)') {
        warn <<VERSION_TOO_LOW;
Your version of libpcap is too low.

You need to install a higher version of
libpcap, and possibly recompile Net::Pcap
so it picks up the new, and necessary features.

If you're using Debian, the magic incantation is

  apt-get install libpcap0.8-dev

I give up. Sorry.
VERSION_TOO_LOW
        exit 1;
    };
};

WriteMakefile(
    'NAME'    => 'Sniffer::HTTP',
    'VERSION_FROM'  => 'lib/Sniffer/HTTP.pm', # finds $VERSION
    'PREREQ_PM'    => { 'Class::Accessor' => 0,
                        'Class::Data::Inheritable' => 0,
                        'HTTP::Request'   => 0,
                        'LWP::Simple'     => 0, # for one test.
                        'NetPacket::TCP'  => 0,
                        'Net::Pcap'       => '0.09',
			'Exporter'         => '5.5',
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Sniffer/HTTP.pm', # retrieve abstract from module
       AUTHOR     => 'Max Maischein <corion@cpan.org>') : ()),
);

1;
