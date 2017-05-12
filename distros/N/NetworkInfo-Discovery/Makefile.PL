use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'NetworkInfo::Discovery',
    'VERSION_FROM'	=> 'lib/NetworkInfo/Discovery.pm', # finds $VERSION
    'PREREQ_PM'		=> {
				'Net::Pcap'   => 0.04,
				'NetPacket'   => 0.03,
				'Net::Traceroute' => 1.05,
			     }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/NetworkInfo/Discovery.pm', # retrieve abstract from module
       AUTHOR     => 'Tom Scanlan <tscanlan@they.gotdns.org>') : ()),
);
