use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Tshark',
    VERSION_FROM      => 'lib/Net/Tshark.pm', # finds $VERSION
    PREREQ_PM         => {
                'File::Which'     => 0,
                'IPC::Run'        => 0,
                'List::MoreUtils' => 0,
                'List::Util'      => 0,
                'XML::Simple'     => 0,
            }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Tshark.pm', # retrieve abstract from module
       AUTHOR         => 'Zachary Blair <zblair@cpan.org>') : ()),
);
