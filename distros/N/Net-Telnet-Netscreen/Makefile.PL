use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Telnet::Netscreen',
    'VERSION_FROM'	=> 'lib/Net/Telnet/Netscreen.pm', # finds $VERSION
    'PREREQ_PM'		=> { Net::Telnet => 3.02 }, # e.g., Module::Name => 1.1
);
