use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'NetPacket::LACP',
    'VERSION_FROM'	=> 'LACP.pm', # finds $VERSION
    'PREREQ_PM'		=> {'NetPacket::Ethernet' => 0.04,
	'NetPacket::LLC' => 0.01}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'NetPacket LACP encoding/decoding', # retrieve abstract from module
       AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),
);
