use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::EMI::Client',
    'VERSION_FROM'	=> 'Client.pm', # finds $VERSION
    'PREREQ_PM'		=> {
       'Net::EMI::Common'=>'1.0',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Client.pm', # retrieve abstract from module
       AUTHOR     => 'Gustav Schaffter <schaffter_cpan@hotmail.com>') : ()),
);

