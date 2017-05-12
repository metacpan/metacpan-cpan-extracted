use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'NetPacket::LLC',
    'VERSION_FROM'	=> 'LLC.pm', # finds $VERSION
    'PREREQ_PM'		=> {"NetPacket::Ethernet" => 0.04}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'NetPacket module for decoding LLC packet data.',
       AUTHOR     => 'Chander Ganesan <cganesan@cpan.org>') : ()),
);
