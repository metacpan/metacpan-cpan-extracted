use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::IPP',
    'VERSION_FROM'	=> 'lib/Net/IPP/IPPRequest.pm', # finds $VERSION
    'PREREQ_PM'		=> {LWP::UserAgent => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Matthias Hilbig <bighil@cpan.org>') : ()),
);
