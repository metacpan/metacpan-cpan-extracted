use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Net::DNS::ToolKit::RR::Template',
    'VERSION_FROM'	=> 'Template.pm', # finds $VERSION
#    'clean'		=> { FILES	=> "*~"},
);
